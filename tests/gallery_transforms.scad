// Visual smoke test of the transforms. Render (F6); the DEPRECATED echo of row 1 is expected.

include<../solidpp.scad>

$fa = 6;
$fs = 0.4;

step = 42;
module at(i, j) translate([i*step, j*step, 0]) children();

// ---- row 0: mirrorpp
at(0, 0) difference()                                                        // four corner holes
{
    cubepp([30, 20, 4], center=true);
    mirrorpp("xy", copy=true) translate([11, 6, 0]) cylinderpp(d=3.2, h=10, center=true);
}
at(1, 0) mirrorpp("xyz", copy=true) translate([6, 4, 3]) spherepp(d=4);       // 8 copies
at(2, 0) mirrorpp([1, 0, 0], point=[10, 0, 0], copy=true) cubepp([6, 6, 6]);  // plane x = 10
at(3, 0) mirrorpp("xy") translate([8, 5, 0]) cubepp(4);                      // 3 copies, no original

// ---- row 1: the _if transforms
at(0, 1) difference_if(true) { cubepp([20, 20, 6]); translate([10, 10, -1]) cylinderpp(d=4, h=8, align="z"); }
at(1, 1) difference_if(false, otherwise="rest") { cubepp([20, 20, 6]); translate([10, 10, 0]) cylinderpp(d=4, h=6, align="z"); }
at(2, 1) hull_if(true) { cubepp(4); translate([12, 12, 0]) spherepp(d=6); }
at(3, 1) minkowski_if(true) { cubepp([12, 12, 2]); spherepp(d=2); cylinderpp(d=1, h=1); }
at(4, 1) intersection_if(true) { cubepp(16, center=true); spherepp(d=20); }
at(5, 1) difference_if(false, ommit_children=false) { cubepp(10); spherepp(d=4); }  // deprecated

// ---- row 2: replicate_at, replicate_around, pairwise_hull
at(0, 2) replicate_at(x=[0, 10, 20], y=[0, 10]) cylinderpp(d=2 + $idx, h=4);   // size by $idx
at(1, 2) difference()
{
    cylinderpp(d=34, h=4);
    replicate_around(6, r=13) cylinderpp(d=3.2, h=10, center=true);            // bolt circle
}
at(2, 2) replicate_around(5, r=12, angle=180, zet="y") cubepp([6, 2, 2], center=true);
at(3, 2) pairwise_hull(closed=true) { spherepp(d=3); translate([20, 0, 0]) spherepp(d=3); translate([10, 15, 0]) spherepp(d=3); }

// ---- row 3: extrusions, projections, cut, transform_to_spp
at(0, 3) linear_extrudepp(-10, zet="x") squarepp([8, 4]);
at(1, 3) rotate_extrudepp(zet="y", sector=[0, 270]) translate([8, 0]) circlepp(d=4);
at(2, 3) linear_extrude(1) projectpp(normal="X") cubepp([4, 12, 8]);           // side view
at(3, 3) linear_extrude(1) projectpp(point=[0, 0, 3], cut=true) cylinderpp(d=16, h=10, mod_list=[rounding(4, "t")]);
at(4, 3) cut([90, -90]) spherepp(d=20);                                      // half removed
at(5, 3) difference()                                                        // drill into faces
{
    cubepp(16, center=true);
    for (f = ["X", "Y", "Z", "xZ"])
        transform_to_spp(16, "", f, orient=true) cylinderpp(d=3, h=6, align="Z");
}
