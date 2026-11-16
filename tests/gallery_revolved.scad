// Visual smoke test of cylinderpp and tubepp with edge modifiers.
// Render (F6) to check that every combination produces a valid manifold.
// Set 'section' to true to cut the solids in half and see their profiles.

include<../solidpp.scad>

section = true;
$fa = 4;
$fs = 0.2;

// spacing of the grid
step = 16;

// cuts away the front half (y < 0) if 'section' is true
module show(i, j)
{
    translate([i*step, j*step, 0])
        difference()
        {
            children();
            if (section)
                translate([0, -50, 0])
                    cube([100, 100, 100], center=true);
        }
}

// ---- row 0: cylinderpp basics
show(0, 0) cylinderpp(d=10, h=6);
show(1, 0) cylinderpp(d=10, h=6, mod_list=[bevel(1, "t"), rounding(1, "b")]);
show(2, 0) cylinderpp(d=10, h=6, mod_list=[bevel(1.5), rounding(0.4)]);
show(3, 0) cylinderpp(d=10, h=6, mod_list=[rounding([2, 1], "t")]);
show(4, 0) cylinderpp(r=[5, 2], h=6, mod_list=[rounding(1)]);
show(5, 0) cylinderpp(r1=5, r2=0, h=6, mod_list=[bevel(1, "b")]);

// ---- row 1: flares and flags
show(0, 1) cylinderpp(d=10, h=6, mod_list=[rounding(-1.5, "b")]);
show(1, 1) cylinderpp(d=10, h=6, mod_list=[bevel([-1, -0.5], "t"), rounding(-1, "b")]);
show(2, 1) cylinderpp(d=10, h=6, mod_list=[rounding(-1.5, "b")], flare_in_size=true);
show(3, 1) cylinderpp(d=10, h=6, mod_list=[rounding(-1.5, "b")], flare_in_align=true, align="xy");
show(4, 1) cylinderpp(d=10, h=6, fn=8, mod_list=[rounding(1, "t")]);
show(5, 1) cylinderpp(d=10, h=6, fn=6, polygon="flats", mod_list=[bevel(0.5)]);

// ---- row 2: tubepp
show(0, 2) tubepp(r=3, R=5, h=6);
show(1, 2) tubepp(r=3, R=5, h=6, mod_list=[rounding(0.9)]);
show(2, 2) tubepp(d=4.2, D=8, h=8, outer_fn=8, mod_list=[bevel(0.6, "ti"), rounding(-1.5, "bo"), rounding(0.5, "to")]);
show(3, 2) tubepp(r=3, R=5, h=6, mod_list=[rounding(-1, "i"), bevel(0.5, "o")]);
show(4, 2) tubepp(t=1, R=[5, 3], h=6, mod_list=[rounding(0.4)]);
show(5, 2) tubepp(D=10, d=5.5, h=4, inner_fn=6, inner_polygon="flats", mod_list=[bevel(0.4)]);

// ---- row 4: sectors (angles from +x for zet "z", +y for zet "x", +z for zet "y")
translate([0, 4*step, 0]) {
    cylinderpp(d=10, h=6, sector=90, mod_list=[rounding(1, "t")]);
    translate([step, 0, 0]) cylinderpp(d=10, h=6, sector=[-60, 60], mod_list=[rounding(-1, "b")]);
    translate([2*step, 0, 0]) tubepp(r=3, R=5, h=6, sector=270, mod_list=[bevel(0.5)]);
    translate([3*step, 0, 0]) cylinderpp(d=10, h=12, zet="x", align="z", sector=[0, 180]);
    translate([4*step, 0, 0]) tubepp(r=3, R=5, h=12, zet="y", align="z", sector=[-90, 90], inner_section=teardrop());
}

// ---- row 5: polyholes in a plate (d = 2, 3, 4, 6, 8) and a tube
translate([0, 5*step, 0]) {
    difference() {
        cubepp([5*step, 12, 5], align="xz");
        for (i = [0:4])
            translate([(i + 0.5)*step, 0, -1])
                cylinderpp(d=[2, 3, 4, 6, 8][i], h=7, polygon="polyhole");
    }
    translate([5.5*step, 0, 0]) tubepp(d=3.2, D=10, h=6, inner_polygon="polyhole", mod_list=[bevel(0.4, "ti")]);
}

// ---- row 3: orientation and alignment (no section)
translate([0, 3*step, 0]) {
    cylinderpp(d=6, h=10, zet="x", align="x", mod_list=[rounding(1, "t")]);
    translate([step, 0, 0]) cylinderpp(d=6, h=10, zet="y", align="y", mod_list=[bevel(1, "b")]);
    translate([2*step, 0, 0]) tubepp(r=2, R=3, h=10, zet="x", align="xz", mod_list=[bevel(0.5, "ti")]);
    translate([3*step, 0, 0]) cylinderpp([10, 10, 3], center=true, mod_list=[rounding(1)]);
}
