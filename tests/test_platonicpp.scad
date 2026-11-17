// Tests of the data layer of platonicpp (no geometry is produced).
// Run: openscad -o /tmp/out.echo tests/test_platonicpp.scad
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

NS = [4, 6, 8, 12, 20];
spec = function(n, a=1) __spp_plat_spec(n, a, "T");

// faces f and g share an edge
function adjacent(s, f, g) = len([for (i = s[1][f]) if (__spp_in_list(i, s[1][g])) 1]) == 2;

// a frame is orthonormal and right-handed
function frame_ok(M) =
    let(x = [M[0][0], M[1][0], M[2][0]], y = [M[0][1], M[1][1], M[2][1]], z = [M[0][2], M[1][2], M[2][2]])
    __t_eq([x*x, y*y, z*z, x*y, x*z, y*z, cross(x, y)*z], [1, 1, 1, 0, 0, 0, 1]);

// ------------------------------------------------------------------ data

_t_data = [for (n = NS) let(s = spec(n))
    each [
        check(str(n, " face count"), len(s[1]), n),
        check(str(n, " vertices per face"), [for (f = s[1]) len(f)], [for (f = s[1]) n == 6 ? 4 : (n == 12 ? 5 : 3)]),
        check(str(n, " edge count"), len(s[4]), [6, 12, 12, 30, 30][search(n, NS)[0]]),
        // bottom face down at the inradius, its first edge parallel to x
        check(str(n, " bottom face"), [s[3][0], s[2][0][2]], [[0, 0, -1], -s[5][0]]),
        check(str(n, " bottom edge along x"), let(f = s[1][0], d = s[0][f[1]] - s[0][f[0]]) [d[1], d[2]], [0, 0]),
        // known inradius for the edge 1 (d = 2 * inradius)
        check(str(n, " inradius"), s[5][0],
              [1/sqrt(24), 0.5, 1/sqrt(6), sqrt((25 + 11*sqrt(5))/10)/2, (3 + sqrt(5))/(4*sqrt(3))][search(n, NS)[0]]),
        // faces counter-clockwise from outside: (v1 - v0) x (v2 - v0) points along the normal
        check(str(n, " face orientation"),
              [for (k = [0:1:n-1]) let(f = s[1][k]) cross(s[0][f[1]] - s[0][f[0]], s[0][f[2]] - s[0][f[0]]) * s[3][k] > 0],
              [for (k = [0:1:n-1]) true]),
    ]];

_t_size = [
    check("edge default", __spp_plat_edge(20, undef, undef, undef, "T"), 1),
    check("edge from d", __spp_plat_edge(20, undef, 20, undef, "T") * 2 * __spp_plat_metrics(20)[0], 20),
    check("edge from D", __spp_plat_edge(8, undef, undef, 10, "T") * 2 * __spp_plat_metrics(8)[2], 10),
    check("cube d = a", __spp_plat_edge(6, undef, 16, undef, "T"), 16),
];

// ------------------------------------------------------------------ numbering

_t_num = [for (n = NS) let(s = spec(n), opp = s[8], seq = s[9])
    each [
        check(str(n, " opposite is a permutation"), __spp_sort(opp), [for (k = [0:1:n-1]) k]),
        check(str(n, " sequential is a permutation"), __spp_sort(seq), [for (k = [0:1:n-1]) k]),
        check(str(n, " opposite pairs"), n == 4 ? true :
              len([for (k = [0:1:n-1]) if (s[3][opp[k]] * s[3][opp[n-1-k]] > -1 + 1e-9) 1]) == 0, true),
        check(str(n, " sequential path"), len([for (k = [0:1:n-2]) if (!adjacent(s, seq[k], seq[k+1])) 1]), 0),
        check(str(n, " sequential closed"), adjacent(s, seq[n-1], seq[0]), true),
        check(str(n, " starts on top"), [s[3][opp[0]][2] >= s[3][opp[n-1]][2], s[2][seq[0]][2]],
              [true, max([for (c = s[2]) c[2]])]),
        check(str(n, " vertex numbering"), __spp_sort(s[7]), [for (k = [0:1:len(s[0])-1]) k]),
    ]];

// ------------------------------------------------------------------ frames

_t_frames = [for (n = NS) let(s = spec(n, 10))
    each [
        check(str(n, " face frames"), [for (k = [0:1:n-1]) let(M = __spp_plat_frame(s[2][k], s[3][k]))
              frame_ok(M) && __t_eq([M[0][2], M[1][2], M[2][2]], s[3][k]) && __t_eq([M[0][3], M[1][3], M[2][3]], s[2][k])],
              [for (k = [0:1:n-1]) true]),
        check(str(n, " vertex frames"), [for (v = s[0]) frame_ok(__spp_plat_frame(v, v/norm(v)))],
              [for (v = s[0]) true]),
    ]];

// ------------------------------------------------------------------ modifiers

_s20 = spec(20, 10);
_t_mods = [
    check("mods none", __spp_plat_mods(undef, _s20, "T"), [0, 0, 0]),
    check("mods all", __spp_plat_mods([bevel(0.5), bevel_corners(1), rounding(0.4)], _s20, "T"), [0.5, 1, 0.4]),
    check("mods zero is no-op", __spp_plat_mods([bevel(0), rounding(1)], _s20, "T"), [0, 0, 1]),
    // edge plane with the chamfer leg d along the face: midradius - d * apothem / midradius
    check("bevel plane", __spp_plat_heights(_s20, 1, 0)[1], let(m = _s20[5]) m[1] - 1 * m[3] / m[1]),
    // vertex plane cut at d along the edges: circumradius - d * cos(edge, vertex direction)
    check("corner plane", __spp_plat_heights(_s20, 0, 2)[2], let(m = _s20[5]) m[2] - 2 * (m[4]/2) / m[2]),
];

echo("ALL TESTS PASSED");
