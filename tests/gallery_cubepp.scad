// Visual smoke test of cubepp with modifiers.
// Render (F6) to check that every combination produces a valid manifold.
// The DEPRECATED echoes of row 3 are expected (legacy modifiers).

include<../solidpp.scad>

$fa = 4;
$fs = 0.3;

// spacing of the grid
step = 22;

module at(i, j) translate([i*step, j*step, 0]) children();

s = [12, 16, 8];

// ---- row 0: basic modifiers
at(0, 0) cubepp(s);
at(1, 0) cubepp(s, mod_list=[rounding(2)]);
at(2, 0) cubepp(s, mod_list=[bevel(1.5)]);
at(3, 0) cubepp(s, mod_list=[rounding(3, "z-edges"), bevel(1, "t")]);
at(4, 0) cubepp(s, mod_list=[rounding([1, 2, 3])]);
at(5, 0) cubepp(s, mod_list=[bevel_corners(3), rounding(0.5, "z-edges")]);

// ---- row 1: order and layering
at(0, 1) cubepp(s, mod_list=[bevel(2, "z-edges"), rounding(1.5, "t")]);      // swept
at(1, 1) cubepp(s, mod_list=[rounding(2, "t"), bevel(2.5, "z-edges")]);      // straight cut
at(2, 1) cubepp(s, mod_list=[bevel(2, "t"), rounding(0.5, "t")]);            // bevel then round
at(3, 1) cubepp(s, mod_list=[bevel([1, 3], "t"), bevel([2, 1, 1], "b")]);    // [across, along], [x, y, z]
at(4, 1) cubepp(s, mod_list=[rounding(1, "z-edges"), bevel(2, "tX")]);       // single base edge
at(5, 1) cubepp(s, mod_list=[rounding(2, ["xY", "XY"]), bevel_corners([2, 3, 4], "b")]);

// ---- row 2: flares, flags and zet
at(0, 2) cubepp(s, mod_list=[rounding(-2, "b")]);
at(1, 2) cubepp(s, mod_list=[rounding(2, "z-edges"), rounding(-2, "b"), rounding(1, "t")]);
at(2, 2) cubepp(s, mod_list=[bevel(-1.5, "bx")], flare_in_size=true, flare_in_align=true);
at(3, 2) cubepp(s, zet="x", mod_list=[rounding(2, "t"), bevel(1, "b")]);
at(4, 2) cubepp(s, zet="y", mod_list=[rounding(-1.5, "b"), rounding(1, "y-edges")]);
at(5, 2) cubepp(s, align="", mod_list=[rounding(1)]);

// ---- row 3: legacy modifiers (translated with DEPRECATED echoes)
at(0, 3) cubepp(s, mod_list=[round_corners(2)]);
at(1, 3) cubepp(s, mod_list=[round_edges(r=2, axes="xy")]);
at(2, 3) cubepp(s, mod_list=[bevel_edges(1)]);
at(3, 3) cubepp(s, mod_list=[bevel_bases(1.5)]);
at(4, 3) cubepp(s, mod_list=[bevel_corners(bevel=2)]);
at(5, 3) cubepp(s, mod_list=[round_corners(1), bevel_edges(1, axes="xy")]);
