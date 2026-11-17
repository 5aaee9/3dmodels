// Parametric reconstruction of 干燥剂盒.stl.
//
// Open in OpenSCAD. Set `show_lid` to true for
// a quick fit preview; export box_lid.scad separately for the lid.

include <common.scad>;

show_lid = false;
lid_preview_file = "box_lid_rebuilt.stl";
show_baffle = false;
baffle_preview_file = "desiccant_baffle_rebuilt.stl";

module desiccant_box() {
    desiccant_box_shell();
}

desiccant_box();

if (show_lid) {
    // Restore the print-oriented lid STL to its assembled position.
    %translate([0, 188, 121])
        rotate([180, 0, 0])
            import(lid_preview_file);
}

if (show_baffle) {
    %translate([0, 0, baffle_middle_z]) import(baffle_preview_file);
}

