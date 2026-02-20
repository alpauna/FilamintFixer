# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Project Overview

ESP32-based filament feed arm that detects and automatically frees filament jammed/pinched on a 3D printer spool. Two MG996R 160-degree servos: one drives the feed arm (spring-loaded, filament passes over a grooved guide wheel), the other adjusts spring tension. Potentiometers on both servo shafts (via D-shaft coupling) provide actual angle feedback. A reed switch on the guide wheel detects filament movement.

## Build Commands

```bash
# Build
pio run -e freenove_esp32_s3_wroom

# Upload firmware
pio run -t upload -e freenove_esp32_s3_wroom

# Serial monitor
pio run -t monitor -e freenove_esp32_s3_wroom
```

## Mechanical Concept

```
                         SPOOL
                           |
                     filament path
                           |
    [Tension Servo]--spring--[Feed Arm Servo]
    (locked, sets         |        (detached during
     spring tension)      |         monitoring, floats
         |                |         with spring)
    pot reads actual      |
    tension angle     guide wheel with
                      reed switch (1 pulse/rev)
                           |
                      filament rides in
                      grooved wheel
```

- **Feed Arm**: Spring-loaded arm with pot angle feedback. Servo DETACHED during normal printing — arm floats freely with spring tension. Pot reads actual angle. When filament jams, extruder pull decreases arm angle. At threshold (~45°), servo ATTACHES and drives to unstick angle (~140°) to yank filament free, then detaches again.
- **Tension Arm**: Servo stays LOCKED during printing. Adjusts spring effective length to calibrate baseline tension. Pot reads actual position.
- **Reed Switch**: Magnet on guide wheel, reed switch detects rotation (1 pulse per rev). Stall detection (no pulses within timeout) provides secondary jam indication.
- **D-shaft coupling**: Both arms have D-shaft bores that couple to potentiometer shafts mounted coaxially below the servo pivot on the base plate.

## Architecture

### Source Files

| File | Purpose |
|------|---------|
| `src/main.cpp` | Entry point, serial command interface, main loop |
| `src/FeedArmController.cpp` | State machine: MONITORING -> UNSTICKING -> HOLD -> RETURNING -> COOLDOWN |
| `src/WheelEncoder.cpp` | Reed switch ISR, pulse counting, stall detection |
| `include/Config.h` | All tunable parameters with defaults |
| `include/pins.h` | GPIO pin assignments |
| `include/FeedArmController.h` | Feed arm state machine and servo control |
| `include/WheelEncoder.h` | ReedSwitch class interface |

### CAD Files (cad/)

| File | Purpose |
|------|---------|
| `common.scad` | Shared dimensions (servo, pot, D-shaft, reed switch) |
| `base.scad` | Base plate with servo pockets, pot towers, reed switch mount |
| `feed_arm.scad` | 120mm feed arm with D-shaft bore and spring anchor |
| `tension_arm.scad` | 50mm tension arm with D-shaft bore |
| `guide_wheel.scad` | 25mm grooved wheel with 625ZZ bearing pockets |
| `assembly.scad` | Visualization of all parts together (not for printing) |

### GPIO Pin Map (ESP32-S3)

| Pin | Function |
|-----|----------|
| GPIO 13 | Feed arm servo (PWM) |
| GPIO 14 | Tension arm servo (PWM) |
| GPIO 6 | Feed arm potentiometer (ADC1_CH5) |
| GPIO 7 | Tension arm potentiometer (ADC1_CH6) |
| GPIO 4 | Reed switch (interrupt, FALLING edge) |
| GPIO 2 | Status LED |

### State Machine

```
MONITORING ──(jam detected)──> UNSTICKING ──> HOLD_UNSTICK ──(timeout)──> RETURNING ──> COOLDOWN ──(timeout)──> MONITORING
```

- MONITORING: Feed servo DETACHED, pot reads actual arm angle
- UNSTICKING: Feed servo ATTACHED, drives to unstick angle
- HOLD_UNSTICK: Holds unstick position for configured duration
- RETURNING: Drives to rest angle
- COOLDOWN: Detaches servo, resets reed switch, returns to monitoring

### Jam Detection (dual)

1. **Primary**: Feed arm pot angle drops below `feedArmJamAngle` threshold (filament pulling arm toward spool)
2. **Secondary**: Reed switch stall (no pulses) AND arm angle noticeably below rest (tension building but not yet at hard threshold)

### Serial Commands

| Command | Description |
|---------|-------------|
| `u` | Manual unstick trigger |
| `t <angle>` | Set tension servo angle |
| `j <angle>` | Set jam threshold angle |
| `r <angle>` | Set rest angle |
| `c` | Pot calibration mode (prints raw ADC for 5 sec) |
| `s` | Print status |
| `h` | Help |

### Key Parameters (Config.h)

| Parameter | Default | Description |
|-----------|---------|-------------|
| `feedArmRestAngle` | 90 | Normal operating angle |
| `feedArmJamAngle` | 45 | Angle that triggers unstick |
| `feedArmUnstickAngle` | 140 | Angle servo drives to yank filament |
| `tensionServoAngle` | 80 | Spring tension baseline |
| `potFeedMin/Max` | 200/3800 | ADC calibration range for feed pot |
| `potTensionMin/Max` | 200/3800 | ADC calibration range for tension pot |
| `reedStallTimeoutMs` | 3000 | No-pulse time before stall flag |
| `unstickHoldTimeMs` | 500 | How long to hold unstick position |
| `unstickCooldownMs` | 2000 | Minimum time between unstick attempts |

## BOM

| Part | Qty | Notes |
|------|-----|-------|
| ESP32-S3 (Freenove WROOM) | 1 | Any ESP32 with ADC works |
| MG996R servo | 2 | 160-degree, standard size |
| 16mm rotary potentiometer | 2 | Linear taper, D-shaft |
| Reed switch (glass) | 1 | Normally open |
| 6mm disc magnet | 1 | Glued to guide wheel |
| 625ZZ bearing | 2 | For guide wheel axle |
| M5x30 bolt + nut | 1 | Guide wheel axle |
| Extension spring | 1 | Connects both arms |
| M3/M4 hardware | - | Mounting screws |

## TODO / Future Work

- WiFi/web interface for remote monitoring (print farm use case)
- Persistent config storage (NVS or SPIFFS)
- MQTT integration for OctoPrint/Klipper notifications
- Multiple spool support (daisy-chain or multi-channel)
