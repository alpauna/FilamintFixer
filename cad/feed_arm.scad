// feed_arm.scad — Main feed arm that attaches to Servo0
// 120mm from servo shaft to guide wheel center.
// Spring anchor point partway along the arm.
// Blind 25T spline bore couples directly to servo output shaft.

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

// --- Filament Retainer ---
// L-shaped guard over the guide wheel groove to prevent filament from
// jumping out during unsticking. Bridge plate spans from boss top over
// the wheel, vertical wall drops down at the outer radius to cover the groove.
// Tapered inlet on one end for easy filament threading.

// Guide wheel references (must match guide_wheel.scad)
wheel_od     = 25;          // wheel outer diameter
wheel_width  = 10;          // wheel width (Z)
wheel_z_off  = -3;          // wheel bottom Z relative to arm Z=0 (match assembly)

// Retainer tuning
ret_gap      = 2.0;         // radial clearance between wheel rim and retainer wall
ret_wall     = 2.0;         // shell/plate thickness
ret_arc_len  = 15.0;        // arc coverage over wheel outer edge (mm)
ret_drop     = 8.0;         // how far wall drops below bridge to cover groove
ret_taper_len   = 8.0;      // inlet taper arc length (mm)
ret_taper_flare = 4.0;      // extra radial gap at taper mouth

// Derived
ret_ir       = wheel_od / 2 + ret_gap;                     // inner radius from wheel center
ret_or       = ret_ir + ret_wall;                           // outer radius
ret_arc_deg  = ret_arc_len / ret_ir * 57.2958;             // arc in degrees
ret_tap_deg  = ret_taper_len / ret_ir * 57.2958;           // taper arc in degrees
ret_bridge_z = arm_thickness + 2;                           // bridge plate Z = boss top
ret_wall_bot = ret_bridge_z - ret_drop;                     // bottom of retainer wall
ret_plate_r0 = wheel_mount_dia / 2 - 1;                    // bridge plate inner radius
ret_plate_w  = ret_or - ret_plate_r0;                       // bridge plate radial width

// Servo screw hole through hub (M3 to secure to servo horn)
horn_screw_dia = m3_hole;

// --- Filament retainer module ---
// Generates an L-shaped guard at the tip of the arm over the guide wheel.
// The bridge plate sits on the boss top (above the wheel), the vertical
// wall drops down at the outer radius to cover the groove.
module filament_retainer() {
    translate([arm_length, 0, 0]) {
        // Main arc: L-shaped cross-section swept around wheel outer edge.
        // Arc centered on +X direction (outer rim, away from arm body).
        // Single polygon avoids coincident-face manifold warnings.
        rotate([0, 0, -ret_arc_deg / 2])
            rotate_extrude(angle = ret_arc_deg)
                polygon([
                    [ret_plate_r0, ret_bridge_z],                // bridge inner bottom
                    [ret_plate_r0, ret_bridge_z + ret_wall],     // bridge inner top
                    [ret_or,       ret_bridge_z + ret_wall],     // bridge outer top
                    [ret_or,       ret_wall_bot],                // wall outer bottom
                    [ret_ir,       ret_wall_bot],                // wall inner bottom
                    [ret_ir,       ret_bridge_z]                 // L corner
                ]);

        // Inlet taper on +Y end: L-shaped cross-section flares outward.
        // Overlap 1 degree into main arc to avoid coincident-face warnings.
        hull() {
            rotate([0, 0, ret_arc_deg / 2 - 1])
                translate([ret_plate_r0, 0, ret_wall_bot])
                    cube([ret_plate_w, 0.01, ret_bridge_z + ret_wall - ret_wall_bot]);
            rotate([0, 0, ret_arc_deg / 2 + ret_tap_deg])
                translate([ret_plate_r0, 0, ret_wall_bot])
                    cube([ret_plate_w + ret_taper_flare, 0.01,
                          ret_bridge_z + ret_wall - ret_wall_bot]);
        }
    }
}

module feed_arm() {
    difference() {
        union() {
            // Hub (attaches to servo 25T spline)
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

            // Filament retainer (guard over guide wheel groove)
            filament_retainer();
        }

        // Blind spline bore (25T servo spline coupling)
        translate([0, 0, -0.1])
            cylinder(d=servo_spline_bore, h=spline_engage_depth + 0.1);

        // Horn screw hole (through hub center, for M3 screw into servo)
        translate([0, 0, -0.1])
            cylinder(d=horn_screw_dia, h=hub_height + 0.2);

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
echo(str("Spline bore: ", servo_spline_bore, " mm x ", spline_engage_depth, " mm deep"));
echo(str("Spring anchor at: ", spring_anchor_dist, " mm from shaft"));
