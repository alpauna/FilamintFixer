#include <Arduino.h>
#include "pins.h"
#include "Config.h"
#include "WheelEncoder.h"
#include "FeedArmController.h"

Config config;
ReedSwitch reedSwitch;
FeedArmController feedArm;

uint32_t lastMonitorUpdate = 0;
uint32_t lastStatusPrint = 0;

// --- Serial Command Handler ---
//   u            - manual unstick trigger
//   t <angle>    - set tension servo angle
//   j <angle>    - set jam threshold angle
//   r <angle>    - set rest angle
//   c            - pot calibration mode (prints raw ADC values)
//   s            - print current status
//   h            - help
void handleSerial() {
    if (!Serial.available()) return;

    String line = Serial.readStringUntil('\n');
    line.trim();
    if (line.length() == 0) return;

    char cmd = line.charAt(0);

    switch (cmd) {
    case 'u':
    case 'U':
        feedArm.triggerUnstick();
        break;

    case 't':
    case 'T': {
        float angle = line.substring(1).toFloat();
        if (angle > 0) {
            feedArm.setTensionAngle(angle);
            config.tensionServoAngle = angle;
        } else {
            Serial.printf("Tension angle: cmd=%.0f° actual=%.0f°\n",
                          feedArm.tensionAngle(), feedArm.tensionArmAngle());
        }
        break;
    }

    case 'j':
    case 'J': {
        float angle = line.substring(1).toFloat();
        if (angle > 0) {
            config.feedArmJamAngle = angle;
            feedArm.updateConfig(config);
            Serial.printf("Jam threshold set to %.0f°\n", angle);
        }
        break;
    }

    case 'r':
    case 'R': {
        float angle = line.substring(1).toFloat();
        if (angle > 0) {
            config.feedArmRestAngle = angle;
            feedArm.updateConfig(config);
            Serial.printf("Rest angle set to %.0f°\n", angle);
        }
        break;
    }

    case 'c':
    case 'C':
        // Pot calibration: print raw ADC values for 5 seconds.
        Serial.println("=== Pot Calibration (5 sec) ===");
        Serial.println("Move arms to their endpoints and note the ADC values.");
        Serial.println("Update potFeedMin/Max and potTensionMin/Max in Config.h");
        for (int i = 0; i < 50; i++) {
            Serial.printf("  Feed: raw=%4d -> %.0f°  |  Tension: raw=%4d -> %.0f°\n",
                          feedArm.rawFeedPot(), feedArm.feedArmAngle(),
                          feedArm.rawTensionPot(), feedArm.tensionArmAngle());
            delay(100);
        }
        Serial.println("=== Calibration done ===");
        break;

    case 's':
    case 'S':
        Serial.println("=== Feed Arm Status ===");
        Serial.printf("  State:           %s\n", feedArmStateName(feedArm.state()));
        Serial.printf("  Feed arm angle:  %.0f° (pot raw: %d)\n",
                      feedArm.feedArmAngle(), feedArm.rawFeedPot());
        Serial.printf("  Tension angle:   %.0f° cmd / %.0f° actual (pot raw: %d)\n",
                      feedArm.tensionAngle(), feedArm.tensionArmAngle(),
                      feedArm.rawTensionPot());
        Serial.printf("  Reed pulses:     %u total, %.1f/sec\n",
                      reedSwitch.pulseCount(), reedSwitch.pulsesPerSec());
        Serial.printf("  Filament stall:  %s (last pulse %ums ago)\n",
                      feedArm.filamentStalled() ? "YES" : "no",
                      reedSwitch.timeSinceLastPulseMs());
        Serial.printf("  Unstick count:   %u\n", feedArm.unstickCount());
        Serial.printf("  Jam threshold:   %.0f°\n", config.feedArmJamAngle);
        Serial.printf("  Rest angle:      %.0f°\n", config.feedArmRestAngle);
        Serial.printf("  Unstick angle:   %.0f°\n", config.feedArmUnstickAngle);
        break;

    case 'h':
    case 'H':
    case '?':
        Serial.println("=== Commands ===");
        Serial.println("  u          - Manual unstick trigger");
        Serial.println("  t <angle>  - Set tension servo angle (spring calibration)");
        Serial.println("  j <angle>  - Set jam threshold angle");
        Serial.println("  r <angle>  - Set rest angle");
        Serial.println("  c          - Pot calibration (prints raw ADC for 5 sec)");
        Serial.println("  s          - Print status");
        Serial.println("  h          - This help");
        break;

    default:
        Serial.printf("Unknown command: '%c'. Type 'h' for help.\n", cmd);
        break;
    }
}

void setup() {
    Serial.begin(config.baudRate);
    delay(1000);

    Serial.println();
    Serial.println("================================");
    Serial.println("  3D Printer Feed Arm v0.2");
    Serial.println("  Pot Angle + Reed Switch");
    Serial.println("================================");

    // Status LED.
    pinMode(PIN_STATUS_LED, OUTPUT);
    digitalWrite(PIN_STATUS_LED, LOW);

    // Initialize reed switch (filament wheel rotation).
    reedSwitch.begin(PIN_REED_SWITCH);
    Serial.println("[Main] Reed switch initialized.");

    // Initialize feed arm controller with pot pins and reed switch.
    feedArm.begin(config, PIN_SERVO_FEED_ARM, PIN_SERVO_TENSION,
                  PIN_POT_FEED_ARM, PIN_POT_TENSION, &reedSwitch);
    Serial.println("[Main] Feed arm controller initialized.");

    Serial.println("[Main] Ready. Type 'h' for commands.");
    Serial.println();
}

void loop() {
    uint32_t now = millis();

    // Run feed arm monitor at configured interval.
    if (now - lastMonitorUpdate >= config.monitorIntervalMs) {
        feedArm.update();
        lastMonitorUpdate = now;

        // Blink LED based on state.
        if (feedArm.state() == FeedArmState::MONITORING) {
            // Slow heartbeat in normal operation.
            // Fast blink if filament stalled (warning).
            if (feedArm.filamentStalled()) {
                digitalWrite(PIN_STATUS_LED, (now / 250) % 2 == 0);
            } else {
                digitalWrite(PIN_STATUS_LED, (now / 1000) % 2 == 0);
            }
        } else if (feedArm.state() == FeedArmState::UNSTICKING ||
                   feedArm.state() == FeedArmState::HOLD_UNSTICK) {
            // Rapid blink during unstick action.
            digitalWrite(PIN_STATUS_LED, (now / 100) % 2 == 0);
        } else {
            digitalWrite(PIN_STATUS_LED, LOW);
        }
    }

    // Periodic status print (every 5 seconds).
    if (now - lastStatusPrint >= 5000) {
        Serial.printf("[Status] %s | Angle:%.0f° | Reed:%.1f/s | Unsticks:%u%s\n",
                      feedArmStateName(feedArm.state()),
                      feedArm.feedArmAngle(),
                      reedSwitch.pulsesPerSec(),
                      feedArm.unstickCount(),
                      feedArm.filamentStalled() ? " STALL" : "");
        lastStatusPrint = now;
    }

    // Handle serial commands.
    handleSerial();
}
