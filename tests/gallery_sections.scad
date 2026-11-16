// Visual smoke test of the section shapes (teardrop, serration).
// Render (F6) to check that every combination produces a valid manifold.
// Row 2 subtracts the solids from plates, as holes are used in practice.

include<../solidpp.scad>

$fa = 4;
$fs = 0.2;

step = 16;

module at(i, j) translate([i*step, j*step, 0]) children();

// ---- row 0: teardrops
at(0, 0) cylinderpp(d=10, h=6, section=teardrop());
at(1, 0) cylinderpp(d=10, h=6, section=teardrop(cap="bridge"));
at(2, 0) cylinderpp(d=10, h=6, section=teardrop(angle=30, up="Y"));
at(3, 0) cylinderpp(d=10, h=6, section=teardrop(), mod_list=[bevel(1, "t"), rounding(-1, "b")]);
at(4, 0) cylinderpp(d=8, h=12, zet="x", align="z", section=teardrop(cap="bridge"), mod_list=[bevel(0.5)]);
at(5, 0) cylinderpp(r=[5, 3], h=6, section=teardrop());

// ---- row 1: serration
at(0, 1) cylinderpp(d=10, h=6, section=serration(16, 0.5));
at(1, 1) cylinderpp(d=10, h=6, section=serration(12, 0.4, "round"), mod_list=[rounding(1)]);
at(2, 1) cylinderpp(d=10, h=6, section=serration(10, 0.6, "round", width=1.6), mod_list=[rounding(-1.5, "b")]);
at(3, 1) cylinderpp(d=10, h=6, section=[teardrop(cap="bridge"), serration(12, 0.4)]);
at(4, 1) cylinderpp(r=[5, 3.5], h=6, section=serration(14, 0.3), mod_list=[bevel(0.5)]);
at(5, 1) tubepp(d=4, D=10, h=6, outer_section=serration(20, 0.4), inner_section=teardrop(), mod_list=[bevel(0.4)]);

// ---- row 2: holes in plates
// heat insert with crush ribs and a lead-in chamfer
at(0, 2) difference() {
    cubepp([12, 12, 6], align="z");
    translate([0, 0, -1]) cylinderpp(d=4.2, h=8, section=serration(6, 0.25, "round"), align="z");
}
// tube with crush ribs and a lead-in (the ribs stop at the chamfer)
at(1, 2) tubepp(d=4.2, D=10, h=6, inner_section=serration(6, 0.25, "round"), mod_list=[bevel(0.6, "ti")]);
// horizontal bridged teardrop hole with a chamfered entry
at(2, 2) difference() {
    cubepp([12, 12, 10], align="z");
    translate([0, 0, 5]) cylinderpp(d=5, h=14, zet="x", center=true, section=teardrop(cap="bridge"));
}
// horizontal teardrop with crush ribs
at(3, 2) difference() {
    cubepp([12, 12, 10], align="z");
    translate([0, 0, 5]) cylinderpp(d=5, h=14, zet="y", center=true, section=[teardrop(), serration(8, 0.25, "round")]);
}
// tube along x with a teardrop hole chamfered on both ends
at(4, 2) tubepp(d=4, D=10, h=12, zet="x", align="z", inner_section=teardrop(), mod_list=[bevel(0.5, "i")]);
// conical hole with serration
at(5, 2) tubepp(r=[2, 3], R=5, h=6, inner_section=serration(8, 0.2));
