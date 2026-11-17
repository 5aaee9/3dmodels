// Parametric reconstruction of 盒盖.stl.
//
// The original lid is a 2 mm plate with 200 rectangular ventilation slots:
// five x positions, forty evenly spaced y rows, each slot 8 x 2 mm.

include <common.scad>;

// Export with the flat outer face on the bed and the hooks pointing up.
// Set false to inspect the original assembled position.
print_ready = true;

plate_z = 119;
plate_h = 2;
slot_w = 8;
slot_h = 2;
slot_count = 40;
slot_pitch = 175 / (slot_count - 1);
slot_y0 = 3.3631289;
guide_y0 = 8;
guide_y1 = 182;
guide_z0 = 114.5;
guide_x0 = 2.35;
guide_x1 = 3.15;
guide_ranges = [
    [guide_y0, snap_y_centers[0] - snap_tab_length / 2 - 0.5],
    [snap_y_centers[0] + snap_tab_length / 2 + 0.5,
        snap_y_centers[1] - snap_tab_length / 2 - 0.5],
    [snap_y_centers[1] + snap_tab_length / 2 + 0.5, guide_y1]
];

module lid_plate() {
    // Planar top and bottom faces match x=2..52, y=-5..188. A small front
    // corner radius follows the source mesh. The original outer side roll is
    // omitted because it belongs to the old sliding fit and would intersect
    // the box wall during vertical insertion.
    translate([2, 0, plate_z])
        linear_extrude(height = plate_h)
            front_rect_2d(50, -5, 188, 0.2);
}

module lid_slots() {
    for (x = [5, 14, 23, 32, 41])
        for (row = [0:slot_count - 1])
            translate([x, slot_y0 + row * slot_pitch, plate_z - 0.5])
                cube([slot_w, slot_h, plate_h + 1], center = false);
}

module side_guides() {
    // Short inner rails keep the lid aligned while the four hooks enter the
    // wall windows. The 0.35 mm side clearance is printable on an FDM part.
    for (range = guide_ranges) {
        translate([guide_x0, range[0], guide_z0])
            cube([
                guide_x1 - guide_x0,
                range[1] - range[0],
                plate_z - guide_z0
            ]);

        translate([54 - guide_x1, range[0], guide_z0])
            cube([
                guide_x1 - guide_x0,
                range[1] - range[0],
                plate_z - guide_z0
            ]);
    }
}

module snap_tabs() {
    for (side = [-1, 1])
        for (yc = snap_y_centers)
            snap_tab(side, yc);
}

module box_lid() {
    difference() {
        union() {
            lid_plate();
            side_guides();
            snap_tabs();
        }
        lid_slots();
    }
}

if (print_ready) {
    // The former z=121 outer face becomes z=0; y=-5..188 becomes 0..193.
    translate([0, 188, plate_z + plate_h])
        rotate([180, 0, 0])
            box_lid();
} else {
    box_lid();
}

