// Tests of the data layer of cubepp and of the legacy modifiers (no geometry is produced).
// Run: openscad -o /tmp/out.echo tests/test_cubepp.scad
// A failed test stops with an assert naming the test; the last echo is "ALL TESTS PASSED".
// The DEPRECATED echoes printed while running are expected (legacy translation tests).

include<../solidpp.scad>

// ------------------------------------------------------------------ helpers

function __t_eq(a, b, eps=1e-6) =
    is_num(a) && is_num(b) ?
        abs(a - b) <= eps :
        is_list(a) && is_list(b) ?
            len(a) == len(b) && len([for (i = [0:1:len(a)-1]) if (!__t_eq(a[i], b[i], eps)) 1]) == 0 :
            a == b;

function check(name, got, expected, eps=1e-6) =
    assert(__t_eq(got, expected, eps), str("TEST FAILED: ", name, "\n  got:      ", got, "\n  expected: ", expected))
    true;

// area of a polygon
function area(p) = let(n = len(p)) abs(sum([for (i = [0:1:n-1]) cross(p[i], p[(i+1)%n])])) / 2;
function sum(l) = len(l) == 0 ? 0 : l[0] + sum([for (i = [1:1:len(l)-1]) l[i]]);

// box spec directly from the data layer
function box(size, mods, zet="z", fis=false) =
    __spp_box_spec(__spp_box_to_local_extents(size, zet),
                   __spp_box_stages(__spp_resolve_mod_list(mods, "box", "TEST"), zet, "TEST"), fis, zet, "TEST");

$fn = 0; $fa = 12; $fs = 2;

// ------------------------------------------------------------------ frame

_t_frame = [
    check("z frame letters", [for (c = ["x", "X", "y", "Y", "z", "Z"]) __spp_box_local_to_parent_letter(c, "z")],
        ["x", "X", "y", "Y", "z", "Z"]),
    check("x frame letters", [for (c = ["x", "X", "y", "Y", "z", "Z"]) __spp_box_local_to_parent_letter(c, "x")],
        ["Z", "z", "y", "Y", "x", "X"]),
    check("y frame letters", [for (c = ["x", "X", "y", "Y", "z", "Z"]) __spp_box_local_to_parent_letter(c, "y")],
        ["x", "X", "Z", "z", "y", "Y"]),
    check("t/b are local Z/z", [__spp_box_parent_to_local_letter("t", "x"), __spp_box_parent_to_local_letter("b", "y")],
        ["Z", "z"]),
    check("parent X with zet x is the top", __spp_box_parent_to_local_letter("X", "x"), "Z"),
    check("extents to local x", __spp_box_to_local_extents([1, 2, 3], "x"), [3, 2, 1]),
    check("extents to local y", __spp_box_to_local_extents([1, 2, 3], "y"), [1, 3, 2]),
    check("extents round trip", __spp_box_to_parent_extents(__spp_box_to_local_extents([1, 2, 3], "y"), "y"), [1, 2, 3]),
    check("position to parent x", __spp_box_to_parent_position([1, 2, 3], "x"), [3, 2, -1]),
    check("pair value", __spp_box_local_value([1, 2], "x"), [1, 1, 2]),
];

// ------------------------------------------------------------------ selectors

_t_sel = [
    check("t", __spp_box_select(["t"], __SPP_BOX_EDGES, "z", "T"), ["Zx", "ZX", "Zy", "ZY"]),
    check("Z == t for zet z", __spp_box_select(["Z"], __SPP_BOX_EDGES, "z", "T"), ["Zx", "ZX", "Zy", "ZY"]),
    check("z-edges", __spp_box_select(["z-edges"], __SPP_BOX_EDGES, "z", "T"), ["xy", "Xy", "XY", "xY"]),
    check("x-edges zet z", __spp_box_select(["x-edges"], __SPP_BOX_EDGES, "z", "T"), ["zy", "zY", "Zy", "ZY"]),
    check("z-edges zet x are local base edges", __spp_box_select(["z-edges"], __SPP_BOX_EDGES, "x", "T"),
        ["zy", "zY", "Zy", "ZY"]),
    check("face X", __spp_box_select(["X"], __SPP_BOX_EDGES, "z", "T"), ["Xy", "XY", "zX", "ZX"]),
    check("single edge", __spp_box_select(["xY"], __SPP_BOX_EDGES, "z", "T"), ["xY"]),
    check("list", __spp_box_select(["tX", "bx"], __SPP_BOX_EDGES, "z", "T"), ["zx", "ZX"]),
    check("corner", __spp_box_select(["txY"], __SPP_BOX_CORNERS, "z", "T"), ["ZxY"]),
    check("corners top", len(__spp_box_select(["t"], __SPP_BOX_CORNERS, "z", "T")), 4),
    check("all edges", len(__spp_box_select(["all"], __SPP_BOX_EDGES, "z", "T")), 12),
];

// ------------------------------------------------------------------ stages

_st_round = __spp_box_stages([rounding(1)], "z", "T");
_st_cut = __spp_box_stages([bevel(1, "t"), bevel(2, "z-edges")], "z", "T");
_st_side = __spp_box_stages([bevel([1, 2, 3], "tX")], "z", "T");

_t_stages = [
    check("all: cross-section", _st_round[0], [["__SPP_EDGE_MOD__", "rounding", [1, 1], ["xy", "Xy", "XY", "xY"]]]),
    check("all: every side", [for (b = _st_round[1]) len(b)], [1, 1, 1, 1]),
    check("all: both bases", _st_round[1][0][0][3], ["bo", "to"]),
    check("all: no cut", _st_round[2], []),
    check("cut stage", [len(_st_cut[0]), len(_st_cut[2])], [0, 1]),
    check("side value [across(x), along(z)]", _st_side[1][1], [["__SPP_EDGE_MOD__", "bevel", [1, 3], ["to"]]]),
    check("side only X", [for (b = _st_side[1]) len(b)], [0, 1, 0, 0]),
];

// ------------------------------------------------------------------ 2D helpers

_sq = [[-1, -1], [1, -1], [1, 1], [-1, 1]];

_t_2d = [
    check("sort", __spp_sort([3, 1, 2, 1]), [1, 1, 2, 3]),
    check("unique sorted", __spp_unique_sorted([1, 1, 2, 3, 3]), [1, 2, 3]),
    check("line intersection", __spp_line_isect([1, 0], 2, [0, 1], 3), [2, 3]),
    check("clip half", area(__spp_clip_halfplane(_sq, [1, 0], 0)), 2),
    check("offset inward", __spp_convex_offset(_sq, [0.5, 0.5, 0.5, 0.5], 10),
        [[-0.5, -0.5], [0.5, -0.5], [0.5, 0.5], [-0.5, 0.5]]),
    check("offset outward mitered", __spp_convex_offset(_sq, [-1, -1, -1, -1], 10),
        [[-2, -2], [2, -2], [2, 2], [-2, 2]]),
    check("offset per edge", area(__spp_convex_offset(_sq, [0, 1, 0, 0], 10)), 2),
    // octagon whose short edges vanish (fallback to clipping)
    check("offset with vanishing edges",
        area(__spp_convex_offset([[-2, -3], [2, -3], [3, -2], [3, 2], [2, 3], [-2, 3], [-3, 2], [-3, -2]],
                                 [for (i = [0:7]) 2], 20)),
        4),
    check("offset with shrinking edges",
        area(__spp_convex_offset([[-2, -3], [2, -3], [3, -2], [3, 2], [2, 3], [-2, 3], [-3, 2], [-3, -2]],
                                 [for (i = [0:7]) 1.5], 20)),
        9 - 2*pow(3 - (5 - 1.5*sqrt(2)), 2)),
];

// ------------------------------------------------------------------ box spec

_b_plain = box([10, 20, 30], [rounding(0)]);
_b_round = box([10, 20, 30], [rounding(2, "z-edges")]);
_b_flare = box([10, 20, 30], [bevel(-1, "bx")]);
_b_flare_s = box([10, 20, 30], [bevel(-1, "bx")], fis=true);
_b_corner = box([10, 20, 30], [bevel_corners(2, "txY")]);
_b_x = box([10, 20, 30], [bevel(1, "t")], zet="x");

_t_spec = [
    check("no-op: 2 rings", len(_b_plain[0]), 2),
    check("no-op: ring", _b_plain[0][0], [-15, [[-5, -10], [5, -10], [5, 10], [-5, 10]]]),
    check("no-op: convex", _b_plain[1], true),
    // r = 2 with $fs = 2: 90 deg arcs have 2 segments
    check("z-edges rounding: ring area", area(_b_round[0][0][1]), 200 - 4*4*(1 - sin(45))),
    check("flare: not convex", _b_flare[1], false),
    check("flare: bottom ring wider", area(_b_flare[0][0][1]), 220),
    check("flare: boxes", [_b_flare[3], _b_flare[4]], [[[-5, -10, -15], [5, 10, 15]], [[-6, -10, -15], [5, 10, 15]]]),
    check("flare in size: boxes", [_b_flare_s[3], _b_flare_s[4]], [[[-4, -10, -15], [5, 10, 15]], [[-5, -10, -15], [5, 10, 15]]]),
    check("corner cutter", len(_b_corner[2]), 1),
    check("corner cutter plane points", [for (i = [0:2]) _b_corner[2][0][i]], [[-3, 10, 15], [-5, 8, 15], [-5, 10, 13]]),
    check("zet x: local height is x", [_b_x[0][0][0], _b_x[0][len(_b_x[0])-1][0]], [-5, 5]),
    check("zet x: top ring", area(_b_x[0][len(_b_x[0])-1][1]), 18*28),
];

// ------------------------------------------------------------------ legacy translation

_t_legacy = [
    check("round_corners", __spp_legacy_to_box(round_corners(1)), [rounding(1)]),
    check("round_corners d 3D", __spp_legacy_to_box(round_corners(d=[2, 4, 6])), [rounding([1, 2, 3])]),
    check("round_edges xy", __spp_legacy_to_box(round_edges(r=2, axes="xy")), [rounding(2, "z-edges")]),
    check("round_edges xz 2D", __spp_legacy_to_box(round_edges(r=[1, 3], axes="xz")), [rounding([1, 1, 3], "y-edges")]),
    check("round_edges x", __spp_legacy_to_box(round_edges(r=1, axes="x")), [rounding(1, ["x", "X"])]),
    check("bevel_edges all", __spp_legacy_to_box(bevel_edges(1)), [bevel(1)]),
    check("bevel_bases default", __spp_legacy_to_box(bevel_bases(1)), [bevel(1, ["z", "Z"])]),
    check("bevel_bases [a,h] axis y", __spp_legacy_to_box(bevel_bases([1, 2], axis="y")), [bevel([1, 2, 1], ["y", "Y"])]),
    check("bevel_bases top only", __spp_legacy_to_box(bevel_bases(bevel_top=1)), [bevel(1, "Z")]),
    check("bevel_bases non-positive skipped", __spp_legacy_to_box(bevel_bases(0)), []),
    check("round_bases bottom/top", __spp_legacy_to_box(round_bases(r_bottom=1, r_top=2)), [rounding(1, "z"), rounding(2, "Z")]),
    check("revolved round_corners 3D", __spp_legacy_to_revolved(round_corners([1, 2, 3]), "T"), [rounding([1, 3])]),
    check("revolved bevel_bases", __spp_legacy_to_revolved(bevel_bases(1), "T"), [bevel(1, ["b", "t"])]),
    check("revolved round_bases d", __spp_legacy_to_revolved(round_bases(d_top=2), "T"), [rounding(1, "t")]),
    check("all-legacy list is reversed",
        __spp_resolve_mod_list([round_corners(1), bevel_edges(2)], "box", "T"), [bevel(2), rounding(1)]),
    check("mixed list keeps order",
        __spp_resolve_mod_list([round_corners(1), bevel(2)], "box", "T"), [rounding(1), bevel(2)]),
    check("inner_mod_list negated", __spp_legacy_restrict([bevel(1, "t")], "i", "T"), [bevel(-1, "ti")]),
    check("outer_mod_list", __spp_legacy_restrict([rounding(1)], "o", "T"), [rounding(1, "o")]),
    check("bevel_corners positional", bevel_corners(1), ["__SPP_CORNER_MOD__", "bevel_corners", [1, 1, 1], ["all"]]),
];

echo("ALL TESTS PASSED");
