#pragma once

#include <Arduino.h>
#include <ESP32Servo.h>
#include "Config.h"
#include "WheelEncoder.h"

// States for the feed arm state machine.
enum class FeedArmState : uint8_t {
    MONITORING,     // Servo DETACHED — arm floats with spring, reading pot for angle
    UNSTICKING,     // Servo ATTACHED — driving to unstick angle to yank filament free
    HOLD_UNSTICK,   // Holding unstick position for configured duration
    RETURNING,      // Returning servo to rest angle after unstick
    COOLDOWN        // Servo DETACHED — waiting between unstick attempts
};

const char* feedArmStateName(FeedArmState state);

class FeedArmController {
public:
    void begin(const Config& cfg, uint8_t feedServoPin, uint8_t tensionServoPin,
               uint8_t feedPotPin, uint8_t tensionPotPin, ReedSwitch* reed);

    // Main update loop — call every monitorIntervalMs.
    void update();

    // Current state.
    FeedArmState state() const { return _state; }

    // Read the actual feed arm angle from potentiometer (degrees).
    float feedArmAngle() const { return _feedArmAngle; }

    // Read the actual tension arm angle from potentiometer (degrees).
    float tensionArmAngle() const { return _tensionArmAngle; }

    // Manually trigger an unstick action (e.g., from serial command).
    void triggerUnstick();

    // Adjust the tension arm servo (spring calibration).
    // Tension servo STAYS ATTACHED and holds this position.
    void setTensionAngle(float angle);
    float tensionAngle() const { return _tensionAngle; }

    // Update config at runtime (e.g., from serial commands).
    void updateConfig(const Config& cfg) { _cfg = cfg; }

    // Stats.
    uint32_t unstickCount() const { return _unstickCount; }
    bool filamentStalled() const { return _filamentStalled; }
    float filamentPulsesPerSec() const;

    // Pot calibration helpers.
    uint16_t rawFeedPot() const { return _rawFeedPot; }
    uint16_t rawTensionPot() const { return _rawTensionPot; }

private:
    void transitionTo(FeedArmState newState);
    bool isJamDetected();
    float readPotAngle(uint8_t pin, uint16_t adcMin, uint16_t adcMax);
    uint16_t readPotSmoothed(uint8_t pin);

    Config _cfg;
    ReedSwitch* _reed = nullptr;

    Servo _feedServo;
    Servo _tensionServo;
    uint8_t _feedServoPin = 0;
    uint8_t _tensionServoPin = 0;
    uint8_t _feedPotPin = 0;
    uint8_t _tensionPotPin = 0;
    bool _feedServoAttached = false;

    FeedArmState _state = FeedArmState::MONITORING;
    float _feedArmAngle = 90.0f;      // actual angle from pot
    float _tensionArmAngle = 80.0f;   // actual angle from pot
    float _tensionAngle = 80.0f;      // commanded tension angle
    float _savedTensionAngle = 80.0f; // tension angle saved before relaxing for unstick
    uint16_t _rawFeedPot = 0;
    uint16_t _rawTensionPot = 0;

    uint32_t _stateEnteredAt = 0;
    uint32_t _unstickCount = 0;
    bool _filamentStalled = false;

    uint32_t _lastReedSampleTime = 0;
};
