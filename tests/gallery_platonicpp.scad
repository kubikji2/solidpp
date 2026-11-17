// Visual smoke test of platonicpp, its wrappers and the face/vertex helpers.
// Render (F6) to check that every solid is a valid manifold. The engraved numbers use text(),
// so the full render takes a while; set ENGRAVE = false for a quick check of the solids.

include<../solidpp.scad>

$fa = 6;
$fs = 0.4;

ENGRAVE = true;

step = 32;
module at(i, j) translate([i*step, j*step, 0]) children();

// engraved label of the current face ($face) with the depth 'depth'
module label(s, size, depth=0.6)
    translate([0, 0, -depth])
        linear_extrude(depth + 0.01)
            text(s, size=size, halign="center", valign="center");

// a die: solid minus the labels of all faces ("6" and "9" get an underline marker)
module die(n, d, mods, size, numbering="opposite")
{
    difference()
    {
        platonicpp(n, d=d, mod_list=mods);
        if (ENGRAVE)
            platonicpp_faces(n, d=d, numbering=numbering)
            {
                label(str($face + 1), size);
                if ($face + 1 == 6 || $face + 1 == 9)
                    translate([0, -0.62*size, 0]) cube([0.5*size, 0.1*size, 1.2], center=true);
            }
    }
}

// ---- row 0: plain solids (wrappers), sizes by edge, inscribed and circumscribed sphere
at(0, 0) tetrahedronpp(a=20);
at(1, 0) hexahedronpp(d=16);
at(2, 0) octahedronpp(D=24);
at(3, 0) dodecahedronpp(d=20);
at(4, 0) icosahedronpp(d=20);
at(5, 0) platonicpp(20, d=20, zet="x", align="xyz");

// ---- row 1: modifiers
at(0, 1) platonicpp(4, a=20, mod_list=[rounding(1.5)]);
at(1, 1) platonicpp(6, d=16, mod_list=[bevel(1.5)]);
at(2, 1) platonicpp(8, d=18, mod_list=[bevel_corners(2)]);
at(3, 1) platonicpp(12, d=20, mod_list=[bevel(0.8), bevel_corners(1.2), rounding(0.4)]);
at(4, 1) platonicpp(20, d=20, mod_list=[rounding(1)]);
at(5, 1) platonicpp(8, a=14, mod_list=[bevel_corners(7)]);          // cut to the edge middles

// ---- row 2: dice (opposite faces add up to n+1)
at(0, 2) difference()                                                  // d4: numbers at the corners
{
    platonicpp(4, a=24, mod_list=[rounding(1)]);
    if (ENGRAVE)
        platonicpp_faces(4, a=24)
            for (k = [0:2])
                let(c = $face_corners[k])
                    translate(0.55*c)
                        rotate(atan2(c[1], c[0]) - 90)
                            label(str($face_vertices[k] + 1), 3);
}
at(1, 2) die(6, 16, [rounding(1.5)], 7);
at(2, 2) die(8, 16, [rounding(0.8)], 5);
at(3, 2) die(12, 20, [rounding(1)], 5);
at(4, 2) die(20, 20, [rounding(0.8)], 3.5);
at(5, 2) die(20, 20, [bevel(0.5)], 3.5, numbering="sequential");    // spindown life counter
