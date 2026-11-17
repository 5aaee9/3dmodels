// Shared helpers for the desiccant box and lid.
//
// The source STL uses millimetres and this file keeps the original coordinate
// system: x = 0..54, y = -5..189, z = 0..121.

$fn = 64;

// Snap-fit dimensions. The lid is pressed down from z=121 to its shelf at
// z=119. The shallow box windows leave about 1.15 mm of outside wall.
snap_y_centers = [35, 155];
snap_tab_length = 10;
snap_window_length = 11;
snap_window_x0 = 1.15;
snap_window_x1 = 2.05;
snap_window_z0 = 116.0;
snap_window_z1 = 118.2;
snap_tab_stem_x0 = 2.35;
snap_tab_stem_x1 = 3.20;
snap_tab_outer_x = 1.60;
snap_tab_attach_z = 119;
snap_tab_bottom_z = 110;
snap_hook_lower_z = 117.15;
snap_hook_upper_z = 117.45;
snap_hook_ramp_top_z = 118.2;

// B: one perforated middle baffle spanning the upper cavity.
// Its ventilation slots use the same layout as the lid.
baffles_enabled = true;
baffle_thickness = 2;
baffle_middle_z = 62;
baffle_slot_w = 8;
baffle_slot_h = 2;
baffle_slot_count = 40;
baffle_slot_pitch = 175 / (baffle_slot_count - 1);
baffle_slot_y0 = 3.3631289;
baffle_slot_x_positions = [5, 14, 23, 32, 41];

// Return points for a circular arc in the local XY plane.
function arc_points(cx, cy, r, a0, a1, n = 12) =
    [for (i = [0:n])
        let (a = a0 + (a1 - a0) * i / n)
        [cx + r * cos(a), cy + r * sin(a)]];

// OpenSCAD 2021 does not support the newer list slice syntax.
function tail(points) = [for (i = [1:len(points) - 1]) points[i]];

// A rectangle with rounded corners only at its low-y end.
// Coordinates are x=0..w and y=y0..y1.
function front_rect_points(w, y0, y1, r = 2.5, n = 12) =
    concat(
        [[r, y0], [w - r, y0]],
        tail(arc_points(w - r, y0 + r, r, -90, 0, n)),
        [[w, y1], [0, y1], [0, y0 + r]],
        tail(arc_points(r, y0 + r, r, 180, 270, n))
    );

// A rectangle with rounded corners at both y ends.
function full_rect_points(w, y0, y1, r = 2.5, n = 12) =
    concat(
        [[r, y0], [w - r, y0]],
        tail(arc_points(w - r, y0 + r, r, -90, 0, n)),
        [[w, y1 - r]],
        tail(arc_points(w - r, y1 - r, r, 0, 90, n)),
        [[r, y1]],
        tail(arc_points(r, y1 - r, r, 90, 180, n)),
        [[0, y0 + r]],
        tail(arc_points(r, y0 + r, r, 180, 270, n))
    );

module front_rect_2d(w, y0, y1, r = 2.5) {
    polygon(points = front_rect_points(w, y0, y1, r));
}

module full_rect_2d(w, y0, y1, r = 2.5) {
    polygon(points = full_rect_points(w, y0, y1, r));
}

module front_prism(w, y0, y1, z0, z1, r = 2.5) {
    translate([0, 0, z0])
        linear_extrude(height = z1 - z0)
            front_rect_2d(w, y0, y1, r);
}

module full_prism(w, y0, y1, z0, z1, r = 2.5) {
    translate([0, 0, z0])
        linear_extrude(height = z1 - z0)
            full_rect_2d(w, y0, y1, r);
}

// Loft between two front-rounded footprints.
module front_loft(w, y0, y1a, y1b, z0, z1, r = 2.5) {
    hull() {
        translate([0, 0, z0])
            linear_extrude(height = 0.01)
                front_rect_2d(w, y0, y1a, r);
        translate([0, 0, z1])
            linear_extrude(height = 0.01)
                front_rect_2d(w, y0, y1b, r);
    }
}

// Loft between two fully rounded footprints.
module full_loft(w, y0, y1a, y1b, z0, z1, r = 2.5) {
    hull() {
        translate([0, 0, z0])
            linear_extrude(height = 0.01)
                full_rect_2d(w, y0, y1a, r);
        translate([0, 0, z1])
            linear_extrude(height = 0.01)
                full_rect_2d(w, y0, y1b, r);
    }
}

// Map a 2D [y,z] polygon and an extrusion along local z to global [x,y,z].
// The matrix maps local (u,v,w) to global (w,u,v).
module yz_prism(profile, width) {
    multmatrix([
        [0, 0, 1, 0],
        [1, 0, 0, 0],
        [0, 1, 0, 0],
        [0, 0, 0, 1]
    ])
        linear_extrude(height = width)
            polygon(points = profile);
}

// Map a 2D [x,z] polygon and an extrusion along local z to global [x,y,z].
module xz_prism(profile, y0, y1) {
    translate([0, y0, 0])
        multmatrix([
            [1, 0, 0, 0],
            [0, 0, 1, 0],
            [0, 1, 0, 0],
            [0, 0, 0, 1]
        ])
            linear_extrude(height = y1 - y0)
                polygon(points = profile);
}

function snap_tab_profile() = [
    [snap_tab_stem_x0, snap_tab_attach_z],
    [snap_tab_stem_x1, snap_tab_attach_z],
    [snap_tab_stem_x1, snap_tab_bottom_z],
    [snap_tab_stem_x0, snap_tab_bottom_z],
    [snap_tab_stem_x0, snap_hook_lower_z],
    [snap_tab_outer_x, snap_hook_lower_z],
    [snap_tab_outer_x, snap_hook_upper_z],
    [snap_tab_stem_x0, snap_hook_ramp_top_z]
];

// A left or right elastic tab, mirrored about the box centre for the right
// side. The sloped upper face guides the tab past the wall while pressing.
module snap_tab(side = -1, yc = 0) {
    if (side < 0) {
        xz_prism(
            snap_tab_profile(),
            yc - snap_tab_length / 2,
            yc + snap_tab_length / 2
        );
    } else {
        translate([54, 0, 0])
            mirror([1, 0, 0])
                xz_prism(
                    snap_tab_profile(),
                    yc - snap_tab_length / 2,
                    yc + snap_tab_length / 2
                );
    }
}

// Cut a shallow rectangular receiving window into the left or right inner
// wall. It remains closed on the outside of the box.
module snap_window(side = -1, yc = 0) {
    y0 = yc - snap_window_length / 2;
    if (side < 0) {
        translate([snap_window_x0, y0, snap_window_z0])
            cube([
                snap_window_x1 - snap_window_x0,
                snap_window_length,
                snap_window_z1 - snap_window_z0
            ]);
    } else {
        translate([54 - snap_window_x1, y0, snap_window_z0])
            cube([
                snap_window_x1 - snap_window_x0,
                snap_window_length,
                snap_window_z1 - snap_window_z0
            ]);
    }
}

module desiccant_baffle() {
    if (baffles_enabled) {
        assert(baffle_thickness > 0, "Baffle thickness must be positive.");
        assert(baffle_middle_z >= 56 &&
            baffle_middle_z + baffle_thickness < snap_tab_bottom_z,
            "Keep the middle baffle above the shoulder and below the lid tabs.");
        assert(baffle_slot_count >= 2 &&
            baffle_slot_count == floor(baffle_slot_count),
            "Use at least two complete rows of ventilation slots.");
        assert(baffle_slot_w > 0 && baffle_slot_h > 0 &&
            baffle_slot_h < baffle_slot_pitch,
            "Ventilation slots must have positive size and separated rows.");
        assert(len(baffle_slot_x_positions) > 0 &&
            min(baffle_slot_x_positions) >= 4.5 &&
            max(baffle_slot_x_positions) + baffle_slot_w <= 49.5 &&
            baffle_slot_y0 >= -0.5 &&
            baffle_slot_y0 + 175 + baffle_slot_h <= 184.5,
            "Leave at least 2.5 mm of solid baffle around the slots.");
        if (len(baffle_slot_x_positions) > 1)
            for (i = [1:len(baffle_slot_x_positions) - 1])
                assert(baffle_slot_x_positions[i] -
                    baffle_slot_x_positions[i - 1] > baffle_slot_w,
                    "Ventilation columns must be ordered and separated.");

        difference() {
            translate([2, 0, 0])
                full_prism(
                    50,
                    -3,
                    187,
                    baffle_middle_z,
                    baffle_middle_z + baffle_thickness,
                    2.5
                );

            // Subtract only from the baffle, preserving the box walls/floor.
            for (x = baffle_slot_x_positions)
                for (row = [0:baffle_slot_count - 1])
                    translate([
                        x,
                        baffle_slot_y0 + row * baffle_slot_pitch,
                        baffle_middle_z - 0.1
                    ])
                        cube([
                            baffle_slot_w,
                            baffle_slot_h,
                            baffle_thickness + 0.2
                        ]);
        }
    }
}

// Compatibility wrapper for preview files that used the earlier plural name.
module desiccant_baffles() {
    desiccant_baffle();
}

// The outer side profile has 5 mm blends where the 45 degree shoulder meets
// the lower and upper sections. The inner profile remains a crisp 2 mm wall.
function outer_lower_profile() =
    concat(
        [[-5, 0], [129, 0], [129, 31.9289]],
        tail(arc_points(134, 31.9289, 5, 180, 135, 12)),
        [[147.5355, 52.5355]],
        tail(arc_points(151.0711, 49, 5, 135, 90, 12)),
        [[151.0711, 54], [-5, 54]]
    );

// The box shell. The lid recess is 2 mm deep: the shelf is at z=119 and the
// surrounding lip reaches z=121.
module desiccant_box_shell() {
    difference() {
        // Outer material, including the raised lip around the lid recess.
        difference() {
            union() {
                // Lower section and shoulder. Rounding the low-y corners is
                // done by the intersection with a front-rounded footprint.
                intersection() {
                    yz_prism(outer_lower_profile(), 54);
                    translate([0, 0, -0.01])
                        linear_extrude(height = 54.02)
                            front_rect_2d(54, -5, 151.0711, 2.5);
                }

                // Long upper section and the 2 mm high outer lip.
                full_prism(54, -5, 189, 54, 121, 2.5);
            }

            // The lid occupies this recessed footprint from z=119 to z=121.
            translate([2, 0, 0])
                full_prism(50, -5, 188, 119, 121.01, 2.5);
        }

        // Hollow interior. Rounded internal corners are visible at both ends.
        translate([2, 0, 0])
            full_prism(50, -3, 127, 2, 34.8284, 2.5);

        translate([2, 0, 0])
            full_loft(50, -3, 127, 148.1716, 34.8284, 56, 2.5);

        // Stop at the underside of the lid shelf; the 0.02 mm extension makes
        // the cavity unambiguously open into the recess in CGAL.
        translate([2, 0, 0])
            full_prism(50, -3, 187, 56, 119.02, 2.5);

        // Four shallow receiving windows let the lid hooks snap under the
        // remaining upper wall when the lid reaches the z=119 shelf.
        for (side = [-1, 1])
            for (yc = snap_y_centers)
                snap_window(side, yc);
    }
}

