// Tests of the data layer of the transforms (no geometry is produced).
// Run: openscad -o /tmp/out.echo tests/test_transforms.scad
// A failed test stops with an assert naming the test; the last echo is "ALL TESTS PASSED".

include<../solidpp.scad>

function __t_eq(a, b, eps=1e-6) =
    is_num(a) && is_num(b) ?
        abs(a - b) <= eps :
        is_list(a) && is_list(b) ?
            len(a) == len(b) && len([for (i = [0:1:len(a)-1]) if (!__t_eq(a[i], b[i], eps)) 1]) == 0 :
            a == b;

function check(name, got, expected, eps=1e-6) =
    assert(__t_eq(got, expected, eps), str("TEST FAILED: ", name, "\n  got:      ", got, "\n  expected: ", expected))
    true;

function apply(M, v) = [for (i = [0:2]) M[i][0]*v[0] + M[i][1]*v[1] + M[i][2]*v[2] + M[i][3]];

_t = [
    // _if transforms: what is kept when the condition is false
    check("otherwise default", __spp_if_otherwise("T", false, undef, undef, 3), [0]),
    check("otherwise rest", __spp_if_otherwise("T", false, "rest", undef, 3), [1, 2]),
    check("otherwise all", __spp_if_otherwise("T", false, "all", undef, 3), [0, 1, 2]),
    check("otherwise none", __spp_if_otherwise("T", false, "none", undef, 3), []),
    check("otherwise index", __spp_if_otherwise("T", false, 2, undef, 3), [2]),
    check("otherwise list", __spp_if_otherwise("T", false, [0, 2], undef, 3), [0, 2]),
    check("ommit_children true", __spp_if_otherwise("T", false, undef, true, 3), [0]),
    check("ommit_children false", __spp_if_otherwise("T", false, undef, false, 3), [0, 1, 2]),
    check("rest of a single child", __spp_if_otherwise("T", false, "rest", undef, 1), []),
    // mirrorpp letters
    check("mirror letters", [__spp_mirror_letters_ok("x"), __spp_mirror_letters_ok("xYz"),
                             __spp_mirror_letters_ok("xX"), __spp_mirror_letters_ok("xa")], [true, true, false, false]),
    // cut sectors
    check("cut positive", __spp_cut_sector(90, "T"), [0, 90]),
    check("cut negative", __spp_cut_sector(-90, "T"), [-90, 0]),
    check("cut pair", __spp_cut_sector([-90, 90], "T"), [-90, 90]),
    check("cut pair wraps", __spp_cut_sector([90, -90], "T"), [90, 270]),
    check("sector reference", [for (z = ["z", "x", "y"]) __spp_sector_ref(z)], [0, 90, 270]),
    // replicate_around directions (right-hand rule around zet)
    check("around z", [__spp_around_dir("z", 0), __spp_around_dir("z", 90)], [[1, 0, 0], [0, 1, 0]]),
    check("around x", [__spp_around_dir("x", 0), __spp_around_dir("x", 90)], [[0, 1, 0], [0, 0, 1]]),
    check("around y", [__spp_around_dir("y", 0), __spp_around_dir("y", 90)], [[0, 0, 1], [1, 0, 0]]),
    // frames
    check("frame top", __spp_frame([1, 2, 3], [0, 0, 1]), [[1, 0, 0, 1], [0, 1, 0, 2], [0, 0, 1, 3], [0, 0, 0, 1]]),
    check("frame X: x -> +y, y -> +z", let(M = __spp_frame([0, 0, 0], [1, 0, 0]))
          [[M[0][0], M[1][0], M[2][0]], [M[0][1], M[1][1], M[2][1]]], [[0, 1, 0], [0, 0, 1]]),
    check("frame inverse", let(M = __spp_frame([1, 2, 3], [1, 1, 0]/sqrt(2)))
          apply(__spp_frame_inverse(M), apply(M, [4, 5, 6])), [4, 5, 6]),
    check("letter vectors", [for (c = ["x", "X", "y", "Y", "z", "Z"]) __spp_letter_vector(c)],
          [[-1, 0, 0], [1, 0, 0], [0, -1, 0], [0, 1, 0], [0, 0, -1], [0, 0, 1]]),
    // transform_to_spp orientation
    check("orientation face", get_orientation_to_spp("X"), [1, 0, 0]),
    check("orientation edge", get_orientation_to_spp("yZ"), [0, -1, 1]/sqrt(2)),
    check("orientation corner", get_orientation_to_spp("xyz"), [-1, -1, -1]/sqrt(3)),
];

echo("ALL TESTS PASSED");
