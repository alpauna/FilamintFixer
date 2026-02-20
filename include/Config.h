#pragma once

#include <cstdint>

// All angles in degrees (0-160 range for 160-degree servos).
// All times in milliseconds unless noted.

struct Config {
    // --- Feed Arm ---
    // Resting angle: where the spring holds the arm under normal filament tension.
    // This is the "home" position during normal printing.
    float feedArmRestAngle = 90.0f;

    // Jam threshold: when the arm is pulled past this angle by extruder tension
    // (filament stuck on spool), trigger the unstick action.
    // Lower angle = more tension pulling the arm toward the spool.
    float feedArmJamAngle = 45.0f;

    // Unstick angle: the servo drives to this angle to yank filament away from spool.
    float feedArmUnstickAngle = 140.0f;

    // How long to hold the unstick position before returning to rest (ms).
    uint32_t unstickHoldTimeMs = 500;

    // Cooldown between unstick attempts to avoid hammering (ms).
    uint32_t unstickCooldownMs = 2000;

    // --- Tension Arm (Spring Adjustment) ---
    // Servo angle that sets the spring's effective length.
    // Higher angle = more spring compression = more tension on feed arm.
    // Adjust this to match your spool's normal drag friction.
    // Tension servo STAYS LOCKED at this angle during printing.
    float tensionServoAngle = 80.0f;

    // Min/max bounds for tension calibration.
    float tensionAngleMin = 30.0f;
    float tensionAngleMax = 130.0f;

    // --- Potentiometer Angle Reading ---
    // ADC range mapping: what ADC values correspond to 0° and 160°.
    // Calibrate by manually moving arm to known angles and reading ADC.
    uint16_t potFeedMin = 200;       // ADC value at 0° (full one direction)
    uint16_t potFeedMax = 3800;      // ADC value at 160° (full other direction)
    uint16_t potTensionMin = 200;
    uint16_t potTensionMax = 3800;

    // Potentiometer smoothing: number of samples to average.
    uint8_t potSamples = 8;

    // --- Reed Switch (Filament Movement Detection) ---
    // If no reed switch pulses within this window, filament has stalled.
    uint32_t reedStallTimeoutMs = 3000;

    // Minimum pulses per second during active printing.
    // Below this = suspicious (slow feed or stall).
    float reedMinPulsesPerSec = 0.5f;

    // --- General ---
    // How often the main monitor loop runs (ms).
    uint32_t monitorIntervalMs = 50;

    // Serial baud rate.
    uint32_t baudRate = 115200;
};
