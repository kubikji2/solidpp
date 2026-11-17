// Visual smoke test of the 2D shapes. Each shape is extruded by 1 so that F6 renders it.

include<../solidpp.scad>

$fa = 6;
$fs = 0.3;

step = 20;
module at(i, j) translate([i*step, j*step, 0]) linear_extrude(1) children();

L = [[0, 0], [12, 0], [12, 5], [5, 5], [5, 12], [0, 12]];
star = [[0, 0], [12, 0, "g"], [9, 5], [12, 11], [6, 8], [0, 11], [3, 5]];

// ---- row 0: squarepp
at(0, 0) squarepp([14, 8]);
at(1, 0) squarepp([14, 8], mod_list=[rounding(2)]);
at(2, 0) squarepp([14, 8], mod_list=[bevel([3, 1.5], "xY"), rounding(2, "X")]);
at(3, 0) squarepp([12, 8], mod_list=[rounding(-2, "y")], flare_in_align=true);      // feet along the bottom
at(4, 0) squarepp([12, 8], mod_list=[bevel(-1.5, "xY"), rounding(-1.5, "yX")]);
at(5, 0) squarepp([14, 8], mod_list=[bevel(2, "XY"), rounding(0.6, "XY")]);         // bevel, then round

// ---- row 1: polygonpp
at(0, 1) polygonpp(L, mod_list=[rounding(1.5)]);                                   // concave corner filled
at(1, 1) polygonpp(L, mod_list=[bevel(1.5, "s2s3"), rounding(1, "s0")]);
at(2, 1) polygonpp(L, mod_list=[rounding(-2, "s0")]);                              // flare along s0
at(3, 1) polygonpp(star, mod_list=[rounding(-1.5, "gs0"), bevel(0.8, "s2s3"), rounding(1, "s4s5")]);
at(4, 1) polygonpp([for (k = [0:5]) 7*[cos(60*k), sin(60*k)]], mod_list=[bevel(1.5)]);
at(5, 1) polygonpp(L, center=true, mod_list=[rounding(1, "s3"), bevel(1, "s5")]);

// ---- row 2: circlepp and ringpp
at(0, 2) circlepp(d=14, fn=6, polygon="flats");
at(1, 2) circlepp(d=3, polygon="polyhole");
at(2, 2) circlepp(d=14, sector=[30, 300]);
at(3, 2) circlepp(d=12, section=[teardrop(), serration(10, 0.5, "round")]);
at(4, 2) ringpp(d=4, D=14, inner_polygon="polyhole", sector=[0, 270]);
at(5, 2) ringpp(t=2, R=8, inner_section=teardrop(cap="bridge"), outer_section=serration(24, 0.4));
