#include "WheelEncoder.h"

// Static instance pointer for ISR trampoline.
static ReedSwitch* _isrInstance = nullptr;

static void IRAM_ATTR reedISR() {
    if (_isrInstance) {
        _isrInstance->handleInterrupt();
    }
}

void ReedSwitch::begin(uint8_t pin) {
    _pin = pin;
    _pulseCount = 0;
    _lastPulseTimeMs = 0;
    _lastSampleCount = 0;
    _lastSampleTimeMs = millis();
    _pulsesPerSec = 0;

    pinMode(_pin, INPUT_PULLUP);

    _isrInstance = this;
    // Reed switch closes when magnet passes — falling edge.
    attachInterrupt(digitalPinToInterrupt(_pin), reedISR, FALLING);
}

void IRAM_ATTR ReedSwitch::handleInterrupt() {
    // Simple debounce: ignore pulses within 50ms of each other.
    // At typical filament feed rates, the wheel won't spin faster
    // than ~5 rev/sec (200ms per rev), so 50ms debounce is safe.
    uint32_t now = millis();
    if (now - _lastPulseTimeMs > 50) {
        _pulseCount++;
        _lastPulseTimeMs = now;
    }
}

bool ReedSwitch::isStalled(uint32_t timeoutMs) const {
    // If we've never seen a pulse, don't report stall until timeout
    // from startup (gives the system time to start).
    if (_lastPulseTimeMs == 0) {
        return (millis() > timeoutMs);
    }
    return (millis() - _lastPulseTimeMs) > timeoutMs;
}

float ReedSwitch::pulsesPerSec() const {
    return _pulsesPerSec;
}

uint32_t ReedSwitch::sample() {
    uint32_t now = millis();
    uint32_t count = _pulseCount;  // atomic on ESP32

    uint32_t deltaPulses = count - _lastSampleCount;
    uint32_t deltaTimeMs = now - _lastSampleTimeMs;

    if (deltaTimeMs > 0) {
        _pulsesPerSec = (float)deltaPulses / ((float)deltaTimeMs / 1000.0f);
    }

    _lastSampleCount = count;
    _lastSampleTimeMs = now;
    return deltaPulses;
}

uint32_t ReedSwitch::timeSinceLastPulseMs() const {
    if (_lastPulseTimeMs == 0) return millis();  // never pulsed
    return millis() - _lastPulseTimeMs;
}

void ReedSwitch::reset() {
    _pulseCount = 0;
    _lastPulseTimeMs = 0;
    _lastSampleCount = 0;
    _lastSampleTimeMs = millis();
    _pulsesPerSec = 0;
}
