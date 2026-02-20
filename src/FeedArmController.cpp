#include "FeedArmController.h"

const char* feedArmStateName(FeedArmState state) {
    switch (state) {
        case FeedArmState::MONITORING:   return "MONITORING";
        case FeedArmState::UNSTICKING:   return "UNSTICKING";
        case FeedArmState::HOLD_UNSTICK: return "HOLD_UNSTICK";
        case FeedArmState::RETURNING:    return "RETURNING";
        case FeedArmState::COOLDOWN:     return "COOLDOWN";
        default:                         return "UNKNOWN";
    }
}

void FeedArmController::begin(const Config& cfg, uint8_t feedServoPin,
                               uint8_t tensionServoPin, uint8_t feedPotPin,
                               uint8_t tensionPotPin, ReedSwitch* reed) {
    _cfg = cfg;
    _reed = reed;
    _feedServoPin = feedServoPin;
    _tensionServoPin = tensionServoPin;
    _feedPotPin = feedPotPin;
    _tensionPotPin = tensionPotPin;

    // Configure ADC pins for potentiometers.
    analogReadResolution(12);       // 0-4095
    analogSetAttenuation(ADC_11db); // 0-3.3V range
    pinMode(_feedPotPin, INPUT);
    pinMode(_tensionPotPin, INPUT);

    // Tension servo: attach and hold position (stays locked during printing).
    _tensionServo.setPeriodHertz(50);
    _tensionServo.attach(_tensionServoPin, 500, 2500);
    _tensionAngle = _cfg.tensionServoAngle;
    _tensionServo.write((int)_tensionAngle);

    // Feed servo: configure but start DETACHED.
    // During monitoring, the arm floats freely with the spring.
    // The pot reads the actual angle.
    _feedServo.setPeriodHertz(50);
    _feedServoAttached = false;
    // Don't attach yet — arm should float in MONITORING state.

    _state = FeedArmState::MONITORING;
    _stateEnteredAt = millis();
    _lastReedSampleTime = millis();
    _unstickCount = 0;

    // Read initial angles from pots.
    _feedArmAngle = readPotAngle(_feedPotPin, _cfg.potFeedMin, _cfg.potFeedMax);
    _tensionArmAngle = readPotAngle(_tensionPotPin, _cfg.potTensionMin, _cfg.potTensionMax);

    Serial.printf("[FeedArm] Init. Feed pot=%.0f° Tension pot=%.0f°\n",
                  _feedArmAngle, _tensionArmAngle);
    Serial.printf("[FeedArm] Jam threshold=%.0f° Unstick=%.0f° Tension cmd=%.0f°\n",
                  _cfg.feedArmJamAngle, _cfg.feedArmUnstickAngle, _tensionAngle);
    Serial.printf("[FeedArm] Feed servo DETACHED (arm floating with spring)\n");
}

void FeedArmController::update() {
    uint32_t now = millis();
    uint32_t elapsed = now - _stateEnteredAt;

    // Always read pot angles — gives actual arm position regardless of servo state.
    _feedArmAngle = readPotAngle(_feedPotPin, _cfg.potFeedMin, _cfg.potFeedMax);
    _tensionArmAngle = readPotAngle(_tensionPotPin, _cfg.potTensionMin, _cfg.potTensionMax);

    // Sample reed switch periodically.
    if (now - _lastReedSampleTime >= 1000) {
        if (_reed) {
            _reed->sample();
            _filamentStalled = _reed->isStalled(_cfg.reedStallTimeoutMs);
        }
        _lastReedSampleTime = now;
    }

    switch (_state) {

    case FeedArmState::MONITORING:
        // Feed servo is DETACHED. Arm floats with spring.
        // Pot reads actual arm angle driven by spring tension vs filament pull.
        // Jam detection: angle drops below threshold (filament pulling arm toward spool).
        if (isJamDetected()) {
            Serial.printf("[FeedArm] JAM! Arm angle=%.0f° (threshold=%.0f°) stall=%s\n",
                          _feedArmAngle, _cfg.feedArmJamAngle,
                          _filamentStalled ? "YES" : "no");
            transitionTo(FeedArmState::UNSTICKING);
        }
        break;

    case FeedArmState::UNSTICKING:
        // Relax tension servo first so feed arm doesn't fight spring + jam.
        // Then attach feed servo and drive to unstick angle.
        if (!_feedServoAttached) {
            _savedTensionAngle = _tensionAngle;
            _tensionServo.write((int)_cfg.tensionAngleMin);
            Serial.printf("[FeedArm] Tension relaxed: %.0f° -> %.0f° (min)\n",
                          _savedTensionAngle, _cfg.tensionAngleMin);

            _feedServo.attach(_feedServoPin, 500, 2500);
            _feedServoAttached = true;
            Serial.println("[FeedArm] Servo ATTACHED — driving to unstick angle");
        }
        _feedServo.write((int)_cfg.feedArmUnstickAngle);
        transitionTo(FeedArmState::HOLD_UNSTICK);
        break;

    case FeedArmState::HOLD_UNSTICK:
        // Hold the unstick position for the configured duration.
        // Servo stays attached and holding.
        if (elapsed >= _cfg.unstickHoldTimeMs) {
            transitionTo(FeedArmState::RETURNING);
        }
        break;

    case FeedArmState::RETURNING:
        // Drive back to rest angle, then detach.
        _feedServo.write((int)_cfg.feedArmRestAngle);
        _unstickCount++;
        Serial.printf("[FeedArm] Unstick #%u complete. Returning to %.0f°\n",
                      _unstickCount, _cfg.feedArmRestAngle);
        transitionTo(FeedArmState::COOLDOWN);
        break;

    case FeedArmState::COOLDOWN:
        // Wait before detaching servo and returning to monitoring.
        // Keep servo attached briefly so it reaches rest position.
        if (elapsed >= _cfg.unstickCooldownMs) {
            // Detach feed servo — arm floats with spring again.
            if (_feedServoAttached) {
                _feedServo.detach();
                _feedServoAttached = false;
                Serial.println("[FeedArm] Servo DETACHED — back to monitoring");
            }
            // Restore tension servo to its pre-unstick angle.
            _tensionAngle = _savedTensionAngle;
            _tensionServo.write((int)_tensionAngle);
            Serial.printf("[FeedArm] Tension restored to %.0f°\n", _tensionAngle);
            // Reset reed switch to avoid false stall after unstick action.
            if (_reed) _reed->reset();
            transitionTo(FeedArmState::MONITORING);
        }
        break;
    }
}

void FeedArmController::triggerUnstick() {
    if (_state == FeedArmState::MONITORING || _state == FeedArmState::COOLDOWN) {
        Serial.println("[FeedArm] Manual unstick triggered.");
        transitionTo(FeedArmState::UNSTICKING);
    }
}

void FeedArmController::setTensionAngle(float angle) {
    _tensionAngle = constrain(angle, _cfg.tensionAngleMin, _cfg.tensionAngleMax);
    _tensionServo.write((int)_tensionAngle);
    Serial.printf("[FeedArm] Tension set to %.0f°\n", _tensionAngle);
}

float FeedArmController::filamentPulsesPerSec() const {
    return _reed ? _reed->pulsesPerSec() : 0;
}

void FeedArmController::transitionTo(FeedArmState newState) {
    if (newState != _state) {
        Serial.printf("[FeedArm] %s -> %s\n",
                      feedArmStateName(_state), feedArmStateName(newState));
    }
    _state = newState;
    _stateEnteredAt = millis();
}

bool FeedArmController::isJamDetected() {
    // Primary: pot angle below jam threshold.
    // When filament is stuck, extruder pull increases tension on the spring arm,
    // pulling it toward the spool (decreasing angle).
    if (_feedArmAngle <= _cfg.feedArmJamAngle) {
        return true;
    }

    // Secondary: reed switch shows filament has stalled AND arm angle is
    // noticeably below rest (filament tension is building but hasn't hit
    // the hard threshold yet). This catches slow-developing jams.
    if (_filamentStalled && _feedArmAngle < (_cfg.feedArmRestAngle - 15.0f)) {
        return true;
    }

    return false;
}

float FeedArmController::readPotAngle(uint8_t pin, uint16_t adcMin, uint16_t adcMax) {
    uint16_t raw = readPotSmoothed(pin);

    // Store raw for calibration display.
    if (pin == _feedPotPin) _rawFeedPot = raw;
    else if (pin == _tensionPotPin) _rawTensionPot = raw;

    // Map ADC range to 0-160 degrees.
    float angle = (float)(raw - adcMin) / (float)(adcMax - adcMin) * 160.0f;
    return constrain(angle, 0.0f, 160.0f);
}

uint16_t FeedArmController::readPotSmoothed(uint8_t pin) {
    uint32_t sum = 0;
    for (uint8_t i = 0; i < _cfg.potSamples; i++) {
        sum += analogRead(pin);
    }
    return sum / _cfg.potSamples;
}
