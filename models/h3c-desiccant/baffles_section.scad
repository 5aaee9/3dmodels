// Review the B baffle: centre side section or a top section of the baffle.
include <common.scad>;

section_view = "side"; // [side,top]

assert(section_view == "side" || section_view == "top",
    "section_view must be side or top.");

if (section_view == "top") {
    projection(cut = true)
        translate([0, 0, -baffle_middle_z - baffle_thickness / 2])
            desiccant_baffle();
} else {
    projection(cut = true)
        multmatrix([
            [0, -1, 0, 0],
            [0, 0, 1, 0],
            [1, 0, 0, -27],
            [0, 0, 0, 1]
        ])
            union() {
                desiccant_box_shell();
                desiccant_baffle();
            }
}
