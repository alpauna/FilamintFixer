// tension_arm.scad — Tension arm that attaches to Servo1
// Shorter arm that anchors the other end of the spring.
// Servo1 holds this arm locked during printing to set spring tension.
// Blind 25T spline bore couples directly to servo output shaft.

include <common.scad>

// --- Arm Parameters ---
arm_length = 50;            // shorter than feed arm
arm_width = 12;
arm_thickness = 6;
hub_dia = 16;
hub_height = 8;
horn_screw_dia = m3_hole;

// Spring anchor at the tip
spring_hole_dia = 3.5;      // same as feed arm spring hole

module tension_arm() {
    difference() {
        union() {
            // Hub (attaches to servo 25T spline)
            cylinder(d=hub_dia, h=hub_height);

            // Arm body
            hull() {
                translate([0, -arm_width/2, 0])
                    cube([0.1, arm_width, arm_thickness]);
                translate([arm_length, 0, 0])
                    cylinder(d=10, h=arm_thickness);
            }

            // Tip boss
            translate([arm_length, 0, 0])
                cylinder(d=10, h=arm_thickness);
        }

        // Blind spline bore (25T servo spline coupling)
        translate([0, 0, -0.1])
            cylinder(d=servo_spline_bore, h=spline_engage_depth + 0.1);

        // Horn screw hole (through hub center, for M3 screw into servo)
        translate([0, 0, -0.1])
            cylinder(d=horn_screw_dia, h=hub_height + 0.2);

        // Spring anchor hole at tip
        translate([arm_length, 0, -0.1])
            cylinder(d=spring_hole_dia, h=arm_thickness + 1);
    }
}

tension_arm();

echo("=== Tension Arm ===");
echo(str("Length: ", arm_length, " mm"));
echo(str("Spline bore: ", servo_spline_bore, " mm x ", spline_engage_depth, " mm deep"));
