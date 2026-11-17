// Standalone printable B middle baffle for the desiccant box.
//
// The source design coordinates the baffle at z=62..64 inside the box. This
// entry point moves it to z=0..2 so it can be sliced as an independent part.

include <common.scad>;

translate([0, 0, -baffle_middle_z])
    desiccant_baffle();
