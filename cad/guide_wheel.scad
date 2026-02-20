// guide_wheel.scad — Filament guide wheel with groove
// Mounts at the tip of the feed arm on an axle.
// Has a V-groove to guide the filament.
// Designed for a rotary encoder or simply free-spinning on a bolt.

include <common.scad>

// --- Wheel Parameters ---
wheel_od = 25;              // outer diameter
wheel_width = 10;           // total width
groove_depth = 2.5;         // how deep the V-groove cuts into the OD
groove_width = 4;           // groove width at the rim
groove_angle = 60;          // V-groove angle

axle_dia = 5.0;             // M5 bolt or 5mm shaft
bearing_od = 16;            // 625ZZ bearing OD (if using bearing) or just clearance
bearing_h = 5;              // bearing width
use_bearing = true;         // set false for plain bore

// Encoder magnet pocket (for AS5600 or similar magnetic encoder)
magnet_dia = 6.2;           // 6mm diametric magnet
magnet_depth = 3;

module guide_wheel() {
    difference() {
        union() {
            // Main wheel body
            cylinder(d=wheel_od, h=wheel_width);
        }

        // V-groove around the circumference
        translate([0, 0, wheel_width/2])
            rotate_extrude()
                translate([wheel_od/2 - groove_depth + 0.5, 0, 0])
                    polygon([
                        [groove_depth, -groove_width/2],
                        [0, 0],
                        [groove_depth, groove_width/2]
                    ]);

        // Axle bore
        if (use_bearing) {
            // Bearing pocket (press fit from each side)
            translate([0, 0, -0.1])
                cylinder(d=bearing_od + tol_tight, h=bearing_h + 0.1);
            translate([0, 0, wheel_width - bearing_h])
                cylinder(d=bearing_od + tol_tight, h=bearing_h + 0.2);
            // Through hole for axle
            translate([0, 0, -0.1])
                cylinder(d=axle_dia + tol, h=wheel_width + 1);
        } else {
            // Plain bore with clearance
            translate([0, 0, -0.1])
                cylinder(d=axle_dia + tol*2, h=wheel_width + 1);
        }

        // Encoder magnet pocket (top face, centered)
        translate([0, 0, wheel_width - magnet_depth])
            cylinder(d=magnet_dia, h=magnet_depth + 0.1);
    }
}

guide_wheel();

echo("=== Guide Wheel ===");
echo(str("OD: ", wheel_od, " mm"));
echo(str("Width: ", wheel_width, " mm"));
echo(str("Axle: ", axle_dia, " mm"));
echo(str("Bearing: ", use_bearing ? "625ZZ" : "plain bore"));
