// base.scad — Main base plate holding two MG996R servos side-by-side
// Servo0 (feed arm) on the right, Servo1 (tension/spring) on the left.
// Flat pot mounting pads on base surface behind servos for future sensor bracket.
// Reed switch mount near guide wheel position.

include <common.scad>

// --- Base Parameters ---
base_wall = 3.0;             // wall thickness around servos
base_floor = 3.0;            // floor thickness
servo_gap = 5.0;             // gap between the two servos
corner_r = 3.0;              // corner rounding radius
lip_height = 5.0;            // wall lip above servo tabs

// Calculated dimensions
base_w = servo_tab_w + base_wall * 2;              // total width
base_l = servo_body_l + base_wall * 2;             // single servo front-to-back (side-by-side layout)
base_h = base_floor + servo_tab_y + servo_tab_h + tol + lip_height; // height with lip above tabs

// ESP32 mounting area behind servos
esp_mount_l = 30;
esp_mount_w = base_w;

total_l = base_l + esp_mount_l;

// --- Tab support thickness ---
tab_support_t = 2.0;

// --- Pot mounting pad (flat pad with M3 holes on base surface) ---
pot_pad_w = 20;              // pad width
pot_pad_l = 14;              // pad length (front-to-back)
pot_pad_h = 2.0;             // pad raised height above base top

// --- Reed switch mount ---
reed_mount_w = 8;
reed_mount_l = reed_body_l + 6;
reed_mount_h = 12;            // height above base for alignment with wheel

// --- Mounting hole positions (4 corners of base) ---
mount_inset = 6;

module rounded_rect(w, l, h, r) {
    hull() {
        for (x = [r, w-r])
            for (y = [r, l-r])
                translate([x, y, 0])
                    cylinder(r=r, h=h);
    }
}

module mg996r_cutout() {
    // Body pocket (servo drops in from top)
    translate([0, 0, base_floor])
        cube([servo_body_w + tol*2, servo_body_l + tol*2, base_h]);

    // Tab slots — cut through the walls at tab height
    translate([-(servo_tab_w - servo_body_w)/2 - tol, -1, servo_tab_y + base_floor])
        cube([servo_tab_w + tol*2, servo_body_l + tol*2 + 2, servo_tab_h + tol]);

    // Screw holes through tabs (vertical, into the base walls)
    for (dx = [-(servo_hole_spacing_w - servo_body_w)/2,
               (servo_hole_spacing_w - servo_body_w)/2 + servo_body_w]) {
        for (dy = [servo_body_l/2 - servo_hole_spacing_l/2,
                   servo_body_l/2 + servo_hole_spacing_l/2]) {
            translate([dx, dy, -1])
                cylinder(d=servo_hole_dia, h=base_h + 10);
        }
    }

    // Wire channel out the back
    translate([servo_body_w/2 - 4, servo_body_l - 1, base_floor + 5])
        cube([8, base_wall + 2, 10]);
}

// Pot mounting pad — flat raised pad with M3 holes for future sensor bracket
module pot_mounting_pad() {
    difference() {
        // Raised pad
        translate([-pot_pad_w/2, -pot_pad_l/2, 0])
            cube([pot_pad_w, pot_pad_l, pot_pad_h]);

        // Two M3 mounting holes
        for (dx = [-pot_pad_w/2 + 3.5, pot_pad_w/2 - 3.5]) {
            translate([dx, 0, -1])
                cylinder(d=m3_hole, h=pot_pad_h + base_floor + 2);
        }
    }
}

// Reed switch clip mount
module reed_switch_mount() {
    difference() {
        // Block body
        translate([-reed_mount_w/2, -reed_mount_l/2, 0])
            cube([reed_mount_w, reed_mount_l, reed_mount_h]);

        // Reed switch channel (horizontal groove for glass body)
        translate([0, 0, reed_mount_h - reed_body_dia - 1.5])
            rotate([0, 0, 0])
                translate([0, -reed_body_l/2 - 1, 0])
                    rotate([-90, 0, 0])
                        cylinder(d=reed_body_dia + tol*2, h=reed_body_l + 2);

        // Lead wire slots out each end
        for (dy = [-reed_mount_l/2 - 0.1, reed_mount_l/2 - 2])
            translate([-1, dy, reed_mount_h - reed_body_dia - 2])
                cube([2, 2.1, reed_body_dia + 3]);

        // M3 mounting hole through bottom
        translate([0, 0, -0.1])
            cylinder(d=m3_hole, h=reed_mount_h + 1);
    }
}

module base() {
    // Servo shaft positions (for pot pad placement)
    servo0_x = base_w/2 + servo_gap/2 - tol + servo_shaft_offset;
    servo0_y = base_wall + servo_body_w/2;
    servo1_x = base_w/2 - servo_gap/2 - servo_body_w + tol + servo_shaft_offset;
    servo1_y = base_wall + servo_body_w/2;

    difference() {
        union() {
            // Main body
            rounded_rect(base_w, total_l, base_h, corner_r);

            // Pot mounting pad for Servo0 (feed arm) — on base surface behind servo
            translate([servo0_x, base_l + 7, base_h])
                pot_mounting_pad();

            // Pot mounting pad for Servo1 (tension arm) — on base surface behind servo
            translate([servo1_x, base_l + 7, base_h])
                pot_mounting_pad();

            // Reed switch mount (positioned at front-right of base,
            // near where the feed arm's guide wheel passes)
            translate([base_w - mount_inset - 2, base_wall + servo_body_l + 3, base_h])
                reed_switch_mount();

            // Tab supports (bridges under servo tabs)
            for (side = [0, 1]) {
                sx = side == 0 ?
                    base_w/2 + servo_gap/2 - tol :
                    base_w/2 - servo_gap/2 - servo_body_w + tol;
                translate([sx - (servo_tab_w - servo_body_w)/2, base_wall,
                           base_floor + servo_tab_y - tab_support_t])
                    cube([servo_tab_w + tol*2, servo_body_l + tol*2, tab_support_t]);
            }
        }

        // Servo0 pocket (feed arm — right side)
        s0x = base_w/2 + servo_gap/2 - tol;
        s0y = base_wall;
        translate([s0x, s0y, 0])
            mg996r_cutout();

        // Servo1 pocket (tension — left side)
        s1x = base_w/2 - servo_gap/2 - servo_body_w + tol;
        s1y = base_wall;
        translate([s1x, s1y, 0])
            mg996r_cutout();

        // Base mounting holes (M4, 4 corners)
        for (x = [mount_inset, base_w - mount_inset])
            for (y = [mount_inset, total_l - mount_inset]) {
                translate([x, y, -1])
                    cylinder(d=m4_hole, h=base_floor + 2);
                translate([x, y, -0.01])
                    cylinder(d=m4_head + 0.5, h=2);
            }

        // ESP32 mounting holes (M3, behind servos)
        esp_start_y = base_l + 5;
        for (x = [mount_inset + 5, base_w - mount_inset - 5])
            for (y = [esp_start_y + 5, esp_start_y + esp_mount_l - 10]) {
                translate([x, y, -1])
                    cylinder(d=m3_hole, h=base_floor + 2);
            }

        // Weight reduction — pocket in the bottom (avoid mounting areas)
        translate([base_wall + 5, base_wall + 5, -0.01])
            rounded_rect(base_w - base_wall*2 - 10,
                         base_l - base_wall*2 - 10,
                         base_floor - 1.2, 2);
    }
}

base();

echo("=== Base Dimensions ===");
echo(str("Width: ", base_w, " mm"));
echo(str("Length (servo area): ", base_l, " mm"));
echo(str("Length (total): ", total_l, " mm"));
echo(str("Height: ", base_h, " mm"));
echo(str("Lip above tabs: ", lip_height, " mm"));
echo("Pot mounting pads on base surface (ESP mount area)");
echo("Reed switch mount on top-right corner");
