// base.scad — Main base plate holding two MG996R servos
// Servo0 (feed arm) on the right, Servo1 (tension/spring) on the left.
// Potentiometer mounts coaxial with each servo shaft (below base).
// Reed switch mount near guide wheel position.

include <common.scad>

// --- Base Parameters ---
base_wall = 3.0;             // wall thickness around servos
base_floor = 3.0;            // floor thickness
servo_gap = 5.0;             // gap between the two servos
corner_r = 3.0;              // corner rounding radius

// Calculated dimensions
base_w = servo_tab_w + base_wall * 2;  // total width
base_l = servo_body_l * 2 + servo_gap + base_wall * 2; // two servos front-to-back
base_h = servo_tab_y + servo_tab_h + base_wall; // height to hold servos at tab level

// ESP32 mounting area behind servos
esp_mount_l = 30;
esp_mount_w = base_w;

total_l = base_l + esp_mount_l;

// --- Pot mount parameters ---
pot_tower_h = pot_body_h + 3;  // tower extends below base to hold pot
pot_tower_od = pot_body_dia + 6; // tower outer diameter
pot_mount_plate_t = 3.0;      // mounting plate thickness

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

    // Shaft clearance hole (through the floor for D-shaft to pot below)
    translate([servo_shaft_offset, servo_body_w/2, -pot_tower_h - 1])
        cylinder(d=pot_bushing_dia + tol*2, h=base_h + pot_tower_h + 10);

    // Wire channel out the back
    translate([servo_body_w/2 - 4, servo_body_l - 1, base_floor + 5])
        cube([8, base_wall + 2, 10]);
}

// Potentiometer mounting tower (hangs below base, coaxial with servo shaft)
module pot_tower() {
    difference() {
        // Tower body (cylindrical, extends below base)
        translate([0, 0, -pot_tower_h])
            cylinder(d=pot_tower_od, h=pot_tower_h);

        // Pot bushing hole (through tower center)
        translate([0, 0, -pot_tower_h - 0.1])
            cylinder(d=pot_bushing_dia + tol, h=pot_tower_h + 0.2);

        // Anti-rotation tab slot (small flat cut in the tower bore)
        translate([-pot_tab_w/2, pot_bushing_dia/2 - 0.5, -pot_tower_h - 0.1])
            cube([pot_tab_w, pot_tab_depth + 0.5, pot_tower_h + 0.2]);
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
    // Servo shaft positions (for pot tower placement)
    servo0_x = base_w/2 + servo_gap/2 - tol + servo_shaft_offset;
    servo0_y = base_wall + servo_body_w/2;
    servo1_x = base_w/2 - servo_gap/2 - servo_body_w + tol + servo_shaft_offset;
    servo1_y = base_wall + servo_body_w/2;

    difference() {
        union() {
            // Main body
            rounded_rect(base_w, total_l, base_h, corner_r);

            // Pot tower for Servo0 (feed arm)
            translate([servo0_x, servo0_y, 0])
                pot_tower();

            // Pot tower for Servo1 (tension arm)
            translate([servo1_x, servo1_y, 0])
                pot_tower();

            // Reed switch mount (positioned at front-right of base,
            // near where the feed arm's guide wheel passes)
            translate([base_w - mount_inset - 2, base_wall + servo_body_l + 3, base_h])
                reed_switch_mount();
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

        // Weight reduction — pocket in the bottom (avoid pot tower areas)
        translate([base_wall + 5, base_wall + 5, -0.01])
            rounded_rect(base_w - base_wall*2 - 10,
                         base_l - base_wall*2 - 10,
                         base_floor - 1.2, 2);
    }

    // Tab supports (bridges under servo tabs)
    for (side = [0, 1]) {
        sx = side == 0 ?
            base_w/2 + servo_gap/2 - tol :
            base_w/2 - servo_gap/2 - servo_body_w + tol;
        translate([sx - (servo_tab_w - servo_body_w)/2, base_wall,
                   base_floor + servo_tab_y - 0.5])
            cube([servo_tab_w + tol*2, servo_body_l + tol*2, 0.5]);
    }
}

base();

echo("=== Base Dimensions ===");
echo(str("Width: ", base_w, " mm"));
echo(str("Length: ", total_l, " mm"));
echo(str("Height: ", base_h, " mm"));
echo(str("Pot tower depth: ", pot_tower_h, " mm below base"));
echo("Reed switch mount on top-right corner");
