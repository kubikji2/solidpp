// Tests of the 2D shapes (squarepp, polygonpp, circlepp, ringpp); no geometry is produced.
// Run: openscad -o /tmp/out.echo tests/test_shapes.scad
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

$fn = 0; $fa = 12; $fs = 2;

sq = function(mods) __spp_square_outline([10, 6], mods, "T");
_L = [[0, 0], [10, 0], [10, 4], [4, 4], [4, 10], [0, 10]];
pg = function(points, mods) __spp_polygon_outline(__spp_2d_base(points, "T"), mods, "T");

// ------------------------------------------------------------------ squarepp

_t_square = [
    check("square plain", sq([]), [[-5, -3], [5, -3], [5, 3], [-5, 3]]),
    check("square bevel [dx, dy] one corner", sq([bevel([2, 1], "xY")]), [[-5, -3], [5, -3], [5, 3], [-3, 3], [-5, 2]]),
    check("square bevel side X", sq([bevel(1, "X")]), [[-5, -3], [4, -3], [5, -2], [5, 2], [4, 3], [-5, 3]]),
    // flares: the first letter is the base side, extended beyond the corner
    check("square flare y (both corners)", sq([bevel(-1, "y")]), [[-5, -2], [-6, -3], [6, -3], [5, -2], [5, 3], [-5, 3]]),
    check("square flare yX", sq([bevel(-1, "yX")]), [[-5, -3], [6, -3], [5, -2], [5, 3], [-5, 3]]),
    check("square flare Xy", sq([bevel(-1, "Xy")]), [[-5, -3], [4, -3], [5, -4], [5, 3], [-5, 3]]),
    check("square flare [dx, dy]", sq([bevel([-2, -1], "yX")]), [[-5, -3], [7, -3], [5, -2], [5, 3], [-5, 3]]),
    // bevel, then rounding of the corners of the bevel (layering)
    check("square bevel then round", len(sq([bevel(2, "XY"), rounding(0.5, "XY")])) > 6, true),
    check("square rounding extent", let(p = sq([rounding(1)]))
          [min([for (q = p) q[0]]), max([for (q = p) q[0]]), min([for (q = p) q[1]]), max([for (q = p) q[1]])], [-5, 5, -3, 3]),
];

// ------------------------------------------------------------------ polygonpp

_t_polygon = [
    check("base ccw", __spp_2d_base(_L, "T")[0], _L),
    check("base names cw", __spp_2d_base([[0, 10], [4, 10, "g"], [4, 4], [10, 4], [10, 0], [0, 0]], "T")[1],
          [["s4"], ["s3"], ["s2"], ["s1", "g"], ["s0"], ["s5"]]),
    check("base letters", __spp_2d_base([[0, 0], [4, 0, "g"], [4, 4]], "T")[2], "sg"),
    check("base collinear is no corner", __spp_2d_base([[0, 0], [4, 0], [8, 0], [8, 4], [0, 4]], "T")[3],
          [true, false, true, true, true]),
    // concave corner (4, 4) is filled
    check("polygon bevel", pg(_L, [bevel(1)]),
          [[0, 1], [1, 0], [9, 0], [10, 1], [10, 3], [9, 4], [5, 4], [4, 5], [4, 9], [3, 10], [1, 10], [0, 9]]),
    check("polygon bevel one corner", pg(_L, [bevel(1, "s2s3")]), [[0, 0], [10, 0], [10, 4], [5, 4], [4, 5], [4, 10], [0, 10]]),
    check("polygon flare s0", pg(_L, [bevel(-1, "s0")]),
          [[0, 1], [-1, 0], [11, 0], [10, 1], [10, 4], [4, 4], [4, 10], [0, 10]]),
    check("polygon flare s0s1", pg(_L, [bevel(-1, "s0s1")]), [[0, 0], [11, 0], [10, 1], [10, 4], [4, 4], [4, 10], [0, 10]]),
    check("polygon flare tagged side", pg([[0, 0, "g"], [10, 0], [10, 4], [0, 4]], [bevel(-1, "gs3")]),
          [[0, 1], [-1, 0], [10, 0], [10, 4], [0, 4]]),
    // legs along slanted sides: a regular hexagon beveled by 1 has equal chamfers sqrt(3)
    check("polygon bevel slanted sides", let(p = pg([for (k = [0:5]) 6*[cos(60*k), sin(60*k)]], [bevel(1)]))
          [for (i = [0:1:len(p)-1]) norm(p[(i+1)%len(p)] - p[i])], [for (k = [0:5]) each [sqrt(3), 4]]),
];

// ------------------------------------------------------------------ circlepp, ringpp

cs = function(R, fn, mode, sector=undef, section=undef) __spp_circle_shape(R, fn, mode, sector, section, "T");
_t_circle = [
    check("circle corners", cs(5, 4, "corners"), [[5, 0], [0, 5], [-5, 0], [0, -5]]),
    check("circle flats", cs(5, 4, "flats")[0], [5*sqrt(2), 0]),
    check("circle polyhole sides", len(cs(1.5, undef, "polyhole")), 6),
    check("circle default fragments", len(cs(5, undef, "corners")), __spp_fragments(5)),
    check("sector", cs(5, 8, "corners", 90), [[0, 0], [5, 0], [5*cos(45), 5*sin(45)], [0, 5]]),
    check("sector [from, to]", cs(5, 4, "corners", [90, 270]), [[0, 0], [0, 5], [-5, 0], [0, -5]]),
    // teardrop: default up "Y" (tip at +y), up "x" (tip at -x)
    check("teardrop tip Y", let(p = cs(5, 8, "corners", undef, teardrop())) max([for (q = p) q[1]]), 5*sqrt(2)),
    check("teardrop tip x", let(p = cs(5, 8, "corners", undef, teardrop(up="x"))) min([for (q = p) q[0]]), -5*sqrt(2)),
    check("serration teeth", len(cs(5, 24, "corners", undef, serration(12, 0.5))), 24),
    check("ring args", __spp_torus_args(2, undef, undef, 8, undef, undef, "T", "x"), [6, 8, 2, 2]),
];

// ------------------------------------------------------------------ prismpp: bevel legs along slanted sides

_t_prism_fix = [
    check("prism vertical bevel legs", let(
              b = __spp_prism_base([for (k = [0:5]) 6*[cos(60*k), sin(60*k)]], "T"), e = __spp_prism_edges(b[1]),
              s = __spp_prism_spec(b, 4, __spp_prism_stages([bevel(1, "z-edges")], e, b[0], b[3], "z", "T"), "T"),
              r = s[0][0][1])
          [for (i = [0:1:len(r)-1]) norm(r[(i+1)%len(r)] - r[i])], [for (k = [0:5]) each [sqrt(3), 4]]),
];

echo("ALL TESTS PASSED");
