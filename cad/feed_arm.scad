// feed_arm.scad — Main feed arm that attaches to Servo0
// 120mm from servo shaft to guide wheel center.
// Spring anchor point partway along the arm.
// D-shaft coupling at the base for potentiometer feedback.

include <common.scad>

// --- Arm Parameters ---
arm_length = 120;           // shaft center to wheel center
arm_width = 15;             // arm cross-section width
arm_thickness = 6;          // arm cross-section height
hub_dia = 16;               // hub outer diameter
hub_height = 8;             // hub thickness above arm

// Spring anchor — hole for spring hook, partway along the arm
spring_anchor_dist = 35;    // distance from shaft center
spring_hole_dia = 3.5;      // spring wire hook hole

// Guide wheel axle at the tip
wheel_axle_dia = 5.0;       // axle hole diameter (for M5 bolt or 5mm shaft)
wheel_mount_dia = 14;       // boss around axle

// Servo screw hole through hub (M3 to secure to servo horn)
horn_screw_dia = m3_hole;

// D-shaft bore (couples to potentiometer shaft below base)
dshaft_bore_dia = dshaft_dia + tol_tight;
dshaft_bore_flat = dshaft_flat + tol_tight;

// --- D-shaft profile module ---
module d_shaft_bore(dia, flat, depth) {
    // D-shaped bore: cylinder with one flat side
    intersection() {
        cylinder(d=dia, h=depth);
        translate([-(dia/2), -(dia/2), 0])
            cube([dia, flat, depth]);
    }
    // Add the round part above the flat
    difference() {
        cylinder(d=dia, h=depth);
        translate([-(dia/2), flat - dia/2, -0.1])
            cube([dia, dia, depth + 0.2]);
    }
}

module feed_arm() {
    difference() {
        union() {
            // Hub (attaches to servo spline + pot D-shaft)
            cylinder(d=hub_dia, h=hub_height);

            // Arm body — tapered from hub to wheel mount
            hull() {
                // At hub
                translate([0, -arm_width/2, 0])
                    cube([0.1, arm_width, arm_thickness]);
                // At wheel mount
                translate([arm_length, 0, 0])
                    cylinder(d=wheel_mount_dia, h=arm_thickness);
            }

            // Wheel mount boss (thicker)
            translate([arm_length, 0, 0])
                cylinder(d=wheel_mount_dia, h=arm_thickness + 2);

            // Spring anchor boss
            translate([spring_anchor_dist, 0, 0])
                cylinder(d=10, h=arm_thickness);

            // D-shaft extension below hub (extends through base to pot)
            translate([0, 0, -dshaft_len])
                cylinder(d=hub_dia - 2, h=dshaft_len);
        }

        // D-shaft bore (through entire hub + extension)
        translate([0, 0, -dshaft_len - 0.1])
            d_shaft_bore(dshaft_bore_dia, dshaft_bore_flat,
                         hub_height + dshaft_len + 0.2);

        // Horn screw hole (through center, for M3 screw into servo)
        translate([0, 0, -dshaft_len - 0.1])
            cylinder(d=horn_screw_dia, h=hub_height + dshaft_len + 1);

        // Guide wheel axle hole
        translate([arm_length, 0, -0.1])
            cylinder(d=wheel_axle_dia + tol, h=arm_thickness + 3);

        // Spring anchor hole (vertical, for spring hook)
        translate([spring_anchor_dist, 0, -0.1])
            cylinder(d=spring_hole_dia, h=arm_thickness + 1);
    }
}

feed_arm();

echo("=== Feed Arm ===");
echo(str("Length: ", arm_length, " mm"));
echo(str("Hub OD: ", hub_dia, " mm"));
echo(str("D-shaft bore: ", dshaft_bore_dia, " mm"));
echo(str("Spring anchor at: ", spring_anchor_dist, " mm from shaft"));
