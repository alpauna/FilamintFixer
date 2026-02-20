#pragma once

// ESP32-S3 WROOM pin map.
// GPIO 26-37 are RESERVED (internal flash/PSRAM on WROOM-N8R8).
// GPIO 19-20 are USB D-/D+ (used for serial/JTAG).

// --- Servo Pins ---
// Feed arm servo: the main arm that filament rides on.
// Actuates to yank filament free when jam is detected.
// DETACHED during monitoring so arm floats with spring tension.
#define PIN_SERVO_FEED_ARM      13

// Tension arm servo: adjusts spring effective length
// to calibrate normal spool friction baseline.
// STAYS ATTACHED during printing — holds position.
#define PIN_SERVO_TENSION       14

// --- Potentiometer Pins (angle feedback via ADC) ---
// 10k linear pots on each arm pivot, D-shaft coupled.
// Reads actual arm angle (not servo-commanded position).
#define PIN_POT_FEED_ARM        6   // ADC1_CH5
#define PIN_POT_TENSION         7   // ADC1_CH6

// --- Reed Switch (filament wheel rotation detection) ---
// Magnet on guide wheel, reed switch on arm/mount.
// One pulse per revolution = filament is moving.
#define PIN_REED_SWITCH         4   // interrupt capable

// --- Status LED (Freenove onboard RGB is GPIO 48) ---
#define PIN_STATUS_LED          2
