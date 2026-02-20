// assembly.scad — Visual assembly of all parts (NOT for printing)
// Open this to see how everything fits together.
// Render individual part files for STL export.

include <common.scad>

// Colors for visualization
color_base = [0.3, 0.3, 0.35];
color_servo = [0.15, 0.15, 0.2];
color_feed_arm = [0.2, 0.6, 0.3];
color_tension_arm = [0.6, 0.3, 0.2];
color_wheel = [0.8, 0.8, 0.2];
color_spring = [0.7, 0.7, 0.7];
color_filament = [1.0, 0.3, 0.1];

base_wall = 3.0;
servo_gap = 5.0;
base_w = servo_tab_w + base_wall * 2;
arm_length = 120;
tension_arm_length = 50;
spring_anchor_dist = 35;

// Servo0 (feed arm) position
servo0_x = base_w/2 + servo_gap/2 + servo_shaft_offset;
servo0_y = base_wall + servo_body_w/2;
servo0_z = 3 + servo_tab_y + servo_tab_h;  // base_floor + tab_y + tab_h

// Arm Z position — sits on top of servo body
arm_z = 3 + servo_body_h;  // base_floor + servo_body_h = 39.5mm

// Servo1 (tension) position
servo1_x = base_w/2 - servo_gap/2 - servo_body_w + servo_shaft_offset;
servo1_y = servo0_y;
servo1_z = servo0_z;

// Feed arm angle (adjustable for visualization)
feed_arm_angle = 90;    // degrees, 90 = horizontal rest
tension_arm_angle = 80;

module simple_servo() {
    // Simplified MG996R shape for visualization
    color(color_servo) {
        cube([servo_body_w, servo_body_l, servo_body_h], center=false);
        // Shaft nub
        translate([servo_shaft_offset, servo_body_w/2, servo_body_h])
            cylinder(d=servo_shaft_dia, h=6);
    }
}

// Base
color(color_base)
    import("base.scad");

// Servo placeholders
translate([base_w/2 + servo_gap/2, base_wall, 3])
    simple_servo();
translate([base_w/2 - servo_gap/2 - servo_body_w, base_wall, 3])
    simple_servo();

// Feed arm (rotated to current angle)
translate([servo0_x, servo0_y, arm_z]) {
    rotate([0, 0, feed_arm_angle])
        color(color_feed_arm)
            import("feed_arm.scad");

    // Guide wheel at tip
    rotate([0, 0, feed_arm_angle])
        translate([arm_length, 0, -3])
            color(color_wheel)
                import("guide_wheel.scad");
}

// Tension arm
translate([servo1_x, servo1_y, arm_z])
    rotate([0, 0, tension_arm_angle])
        color(color_tension_arm)
            import("tension_arm.scad");

// Spring visualization (line between anchor points)
// Feed arm spring anchor
feed_spring_x = servo0_x + spring_anchor_dist * cos(feed_arm_angle);
feed_spring_y = servo0_y + spring_anchor_dist * sin(feed_arm_angle);
// Tension arm spring anchor
tension_spring_x = servo1_x + tension_arm_length * cos(tension_arm_angle);
tension_spring_y = servo1_y + tension_arm_length * sin(tension_arm_angle);

color(color_spring) {
    hull() {
        translate([feed_spring_x, feed_spring_y, arm_z + 3])
            sphere(d=2);
        translate([tension_spring_x, tension_spring_y, arm_z + 3])
            sphere(d=2);
    }
}

// Filament path visualization
color(color_filament, 0.5) {
    wheel_x = servo0_x + arm_length * cos(feed_arm_angle);
    wheel_y = servo0_y + arm_length * sin(feed_arm_angle);
    // From spool (far right) to wheel to extruder (below)
    hull() {
        translate([wheel_x, wheel_y + 60, arm_z + 6])
            sphere(d=filament_dia);
        translate([wheel_x, wheel_y, arm_z + 6])
            sphere(d=filament_dia);
    }
    hull() {
        translate([wheel_x, wheel_y, arm_z + 6])
            sphere(d=filament_dia);
        translate([wheel_x - 30, wheel_y - 20, arm_z - 14])
            sphere(d=filament_dia);
    }
}

echo("=== Assembly View ===");
echo("Open individual .scad files to export STL:");
echo("  base.scad -> base.stl");
echo("  feed_arm.scad -> feed_arm.stl");
echo("  tension_arm.scad -> tension_arm.stl");
echo("  guide_wheel.scad -> guide_wheel.stl");
