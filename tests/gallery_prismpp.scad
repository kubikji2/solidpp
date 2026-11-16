// Visual smoke test of prismpp with modifiers.
// Render (F6) to check that every combination produces a valid manifold.

include<../solidpp.scad>

$fa = 4;
$fs = 0.3;

// spacing of the grid
step = 20;

module at(i, j) translate([i*step, j*step, 0]) children();

pent = [[0, 0], [10, 0, "g"], [12, 7], [5, 12], [-2, 7]];
tri = [[0, 0], [12, 0], [3, 9]];                              // acute corners
hex = [for (k = [0:5]) 6*[cos(60*k), sin(60*k)]];

// ---- row 0: basic modifiers ("keep": the points as given, base on z = 0)
at(0, 0) prismpp(pent, h=6);
at(1, 0) prismpp(pent, h=6, mod_list=[rounding(1.5)]);
at(2, 0) prismpp(pent, h=6, mod_list=[bevel(1)]);
at(3, 0) prismpp(tri, h=5, mod_list=[rounding(1.2)]);
at(4, 0) prismpp(hex, h=5, mod_list=[rounding(2, "z-edges"), bevel(0.8, "t")]);
at(5, 0) prismpp(hex, h=5, mod_list=[bevel([1, 2], "t"), rounding(0.5, "b")]);

// ---- row 1: selection, order and layering
at(0, 1) prismpp(pent, h=6, mod_list=[rounding(2, "g")]);                          // tagged side
at(1, 1) prismpp(pent, h=6, mod_list=[rounding(2, "z-edges"), rounding(1.5, "ts1")]);  // blend into sides
at(2, 1) prismpp(pent, h=6, mod_list=[rounding(1.5, "ts1"), bevel(2, "s1s2")]);    // straight cut (stage C)
at(3, 1) prismpp(tri, h=5, mod_list=[rounding(1.5, "z-edges"), bevel([1.5, 0.7], "ts0"), rounding(0.8, "ts2")]);
at(4, 1) prismpp(pent, h=6, mod_list=[bevel(1.5, "t"), rounding(0.6, "t")]);       // bevel then round
at(5, 1) prismpp(pent, h=6, mod_list=[rounding(1, "s0s1"), rounding(0.5, "s3")]);

// ---- row 2: flares, flags, zet, alignment
at(0, 2) prismpp(hex, h=5, mod_list=[rounding(-1.5, "b"), rounding(0.8, "t")]);
at(1, 2) prismpp(pent, h=6, mod_list=[rounding(2, "z-edges"), bevel(-1, "bs1")]);
at(2, 2) prismpp(pent, h=6, align="xyz", flare_in_align=true, mod_list=[rounding(-2, "b")]);
at(3, 2) prismpp(pent, h=8, zet="x", mod_list=[rounding(1.5, "x-edges")]);
at(4, 2) prismpp(pent, h=8, zet="y", align="xyz", mod_list=[bevel(1, "all")]);
at(5, 2) prismpp(tri, h=5, center=true, mod_list=[rounding(1, "x-edges")]);      // side 0 only
