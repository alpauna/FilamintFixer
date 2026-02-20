// tension_arm.scad — Tension arm that attaches to Servo1
// Shorter arm that anchors the other end of the spring.
// Servo1 holds this arm locked during printing to set spring tension.
// D-shaft coupling at the base for potentiometer feedback.

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

// D-shaft bore (couples to potentiometer shaft below base)
dshaft_bore_dia = dshaft_dia + tol_tight;
dshaft_bore_flat = dshaft_flat + tol_tight;

// --- D-shaft profile module ---
module d_shaft_bore(dia, flat, depth) {
    intersection() {
        cylinder(d=dia, h=depth);
        translate([-(dia/2), -(dia/2), 0])
            cube([dia, flat, depth]);
    }
    difference() {
        cylinder(d=dia, h=depth);
        translate([-(dia/2), flat - dia/2, -0.1])
            cube([dia, dia, depth + 0.2]);
    }
}

module tension_arm() {
    difference() {
        union() {
            // Hub
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

            // D-shaft extension below hub
            translate([0, 0, -dshaft_len])
                cylinder(d=hub_dia - 2, h=dshaft_len);
        }

        // D-shaft bore (through entire hub + extension)
        translate([0, 0, -dshaft_len - 0.1])
            d_shaft_bore(dshaft_bore_dia, dshaft_bore_flat,
                         hub_height + dshaft_len + 0.2);

        // Horn screw hole
        translate([0, 0, -dshaft_len - 0.1])
            cylinder(d=horn_screw_dia, h=hub_height + dshaft_len + 1);

        // Spring anchor hole at tip
        translate([arm_length, 0, -0.1])
            cylinder(d=spring_hole_dia, h=arm_thickness + 1);
    }
}

tension_arm();

echo("=== Tension Arm ===");
echo(str("Length: ", arm_length, " mm"));
echo(str("D-shaft bore: ", dshaft_bore_dia, " mm"));
