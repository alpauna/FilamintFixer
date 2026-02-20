#pragma once

#include <Arduino.h>

// Reed switch on the filament guide wheel.
// A magnet on the wheel triggers the reed switch once per revolution.
// Tracks pulse count and time since last pulse to detect:
//   - Normal feed (pulses arriving regularly)
//   - Stall (no pulses = filament stopped)
//   - Provides approximate feed rate via pulse frequency

class ReedSwitch {
public:
    void begin(uint8_t pin);

    // Check if filament has stalled (no pulses within timeout).
    bool isStalled(uint32_t timeoutMs) const;

    // Pulses per second (averaged over recent window).
    float pulsesPerSec() const;

    // Total pulse count since startup.
    uint32_t pulseCount() const { return _pulseCount; }

    // Pulses since last call to sample() — for periodic checking.
    uint32_t sample();

    // Time in ms since the last reed switch pulse.
    uint32_t timeSinceLastPulseMs() const;

    // Reset counters.
    void reset();

    // ISR handler — must be public for the static trampoline.
    void IRAM_ATTR handleInterrupt();

private:
    uint8_t _pin = 0;
    volatile uint32_t _pulseCount = 0;
    volatile uint32_t _lastPulseTimeMs = 0;
    uint32_t _lastSampleCount = 0;
    uint32_t _lastSampleTimeMs = 0;
    float _pulsesPerSec = 0;
};
