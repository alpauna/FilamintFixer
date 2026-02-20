// common.scad — Shared dimensions for FilamentFixer 3D printed parts
// All units in mm.

// --- MG996R Servo Dimensions ---
servo_body_w = 20.0;     // width (side to side)
servo_body_l = 40.7;     // length (front to back)
servo_body_h = 36.5;     // height (bottom to mounting tab top)
servo_tab_w  = 54.5;     // total width across mounting tabs
servo_tab_h  = 2.5;      // tab thickness
servo_tab_y  = 27.0;     // tab distance from bottom of servo
servo_shaft_offset = 10.0; // shaft center from front face
servo_shaft_dia = 6.0;   // output shaft diameter
servo_spline_dia = 5.8;  // 25T spline OD
servo_hole_dia = 4.5;    // mounting screw hole diameter (M4)
servo_hole_spacing_w = 49.0; // hole center to center (width)
servo_hole_spacing_l = 10.0; // hole center to center (length, front-back)
servo_total_h = 42.9;    // total height including shaft nub

// --- Print Tolerances ---
tol = 0.3;               // general clearance tolerance
tol_tight = 0.15;        // tight fit tolerance

// --- Fastener Sizes ---
m3_hole = 3.2;
m3_head = 5.8;
m3_insert = 4.2;         // heat-set insert hole
m4_hole = 4.3;
m4_head = 7.2;

// --- Filament ---
filament_dia = 1.75;     // standard filament diameter

// --- Potentiometer (typical 16mm panel-mount rotary pot) ---
pot_body_dia = 16.0;     // pot body diameter
pot_shaft_dia = 6.0;     // D-shaft diameter (round part)
pot_shaft_flat = 4.5;    // D-shaft flat-to-round distance
pot_shaft_len = 15.0;    // shaft length above body
pot_bushing_dia = 7.2;   // threaded bushing OD (panel mount hole)
pot_bushing_len = 9.0;   // bushing length
pot_body_h = 10.0;       // body height (below bushing)
pot_tab_w = 3.0;         // anti-rotation tab width
pot_tab_depth = 2.0;     // anti-rotation tab slot depth

// --- D-shaft profile (matches pot shaft) ---
dshaft_dia = 6.0;        // round diameter
dshaft_flat = 4.5;       // flat-to-round distance (D cut depth)
dshaft_len = 10.0;       // length extending below arm hub

// --- Reed switch (glass body, typical) ---
reed_body_l = 14.0;      // glass body length
reed_body_dia = 2.5;     // glass body diameter
reed_lead_dia = 0.5;     // lead wire diameter
reed_mount_id = 3.0;     // clip inner diameter (holds reed body)

$fn = 60;
