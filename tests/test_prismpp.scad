// Tests of the data layer of prismpp (no geometry is produced).
// Run: openscad -o /tmp/out.echo tests/test_prismpp.scad
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

_P5 = [[0, 0], [6, 0, "g"], [7, 4], [3, 7], [-1, 4]];
_sq = [[0, 0], [4, 0], [4, 4], [0, 4]];

function base(p) = __spp_prism_base(p, "T");
function edge_tags(p) = [for (e = __spp_prism_edges(base(p)[1])) e[0]];
// tags of the edges selected by 'tokens'
function sel(p, tokens, zet="z") =
    let(b = base(p))
    [for (e = __spp_prism_select(tokens, __spp_prism_edges(b[1]), b[0], b[3], zet, "T")) e[0]];
function spec(p, h, mods) =
    let(b = base(p), e = __spp_prism_edges(b[1]))
    __spp_prism_spec(b, h, __spp_prism_stages(mods, e, b[0], b[3], "z", "T"), "T");

// ------------------------------------------------------------------ base

_t_base = [
    check("base ccw kept", base(_P5)[0], [[0, 0], [6, 0], [7, 4], [3, 7], [-1, 4]]),
    check("base side names", base(_P5)[1], [["s0"], ["s1", "g"], ["s2"], ["s3"], ["s4"]]),
    check("base letters", base(_P5)[3], "tbsg"),
    check("base centroid square", base(_sq)[2], [2, 2]),
    // clockwise input: points reversed, the sides keep the user's numbers and tags
    check("base cw names", base([[0, 4], [4, 4], [4, 0, "g"], [0, 0]])[1], [["s2", "g"], ["s1"], ["s0"], ["s3"]]),
    check("base cw points", base([[0, 4], [4, 4], [4, 0], [0, 0]])[0], [[0, 0], [4, 0], [4, 4], [0, 4]]),
    check("tag canonical", __spp_prism_tag(["s10", "g", "s2", "t"]), "ts2s10g"),
];

// ------------------------------------------------------------------ edges and selectors

_t_sel = [
    check("edges", edge_tags(_sq),
          ["s0s3", "s0s1", "s1s2", "s2s3", "ts0", "ts1", "ts2", "ts3", "bs0", "bs1", "bs2", "bs3"]),
    check("edges with tag", edge_tags(_P5)[1], "s0s1g"),
    check("sel t", sel(_sq, ["t"]), ["ts0", "ts1", "ts2", "ts3"]),
    check("sel side s1 (4 edges)", sel(_sq, ["s1"]), ["s0s1", "s1s2", "ts1", "bs1"]),
    check("sel single top edge", sel(_sq, ["ts2"]), ["ts2"]),
    check("sel vertical edge", sel(_sq, ["s1s2"]), ["s1s2"]),
    check("sel z-edges", sel(_sq, ["z-edges"]), ["s0s3", "s0s1", "s1s2", "s2s3"]),
    check("sel x-edges (zet z)", sel(_sq, ["x-edges"]), ["ts0", "ts2", "bs0", "bs2"]),
    check("sel x-edges (zet x) are vertical", sel(_sq, ["x-edges"], "x"), ["s0s3", "s0s1", "s1s2", "s2s3"]),
    check("sel family s = all", len(sel(_sq, ["s"])), 12),
    check("sel tag family", sel(_P5, ["g"]), ["s0s1g", "s1s2g", "ts1g", "bs1g"]),
    check("sel list", sel(_sq, ["ts0", "b"]), ["ts0", "bs0", "bs1", "bs2", "bs3"]),
];

// ------------------------------------------------------------------ stages

_st = let(b = base(_sq)) __spp_prism_stages([rounding(1, "z-edges"), bevel(0.5, "ts1"), rounding(0.3, "s0s1")],
                                            __spp_prism_edges(b[1]), b[0], b[3], "z", "T");
_t_stages = [
    check("stage A", _st[0], [["__SPP_EDGE_MOD__", "rounding", [1, 1], ["s0s3", "s0s1", "s1s2", "s2s3"]]]),
    check("stage B side 1", _st[1][1], [["__SPP_EDGE_MOD__", "bevel", [0.5, 0.5], ["to"]]]),
    check("stage B side 0 empty", _st[1][0], []),
    check("stage C", _st[2], [["__SPP_EDGE_MOD__", "rounding", [0.3, 0.3], ["s0s1"]]]),
];

// ------------------------------------------------------------------ weights and spec

_t_spec = [
    check("weights on a side", __spp_prism_weights([0, -1], [[0, -1], [1, 0], [0, 1], [-1, 0]]), [1, 0, 0, 0]),
    // right angle: cos² / sin² as in cubepp
    check("weights right angle", __spp_prism_weights([cos(-60), sin(-60)], [[0, -1], [1, 0], [0, 1], [-1, 0]]),
          [pow(sin(60), 2), pow(sin(30), 2), 0, 0]),
    check("spec plain square", let(s = spec(_sq, 2, [bevel(0.5, "t")])) [s[1], s[3], s[4]],
          [true, [[0, 0, -1], [4, 4, 1]], [[0, 0, -1], [4, 4, 1]]]),
    check("spec flare box", let(s = spec(_sq, 2, [rounding(-1, "bs1")])) [s[1], s[4]],
          [false, [[0, 0, -1], [5, 4, 1]]]),
    // top ring of a top bevel 0.5 on all sides: the square inset by 0.5
    check("spec top ring", let(s = spec(_sq, 2, [bevel(0.5, "t")]), r = s[0][len(s[0])-1])
          [r[0], r[1]], [1, [[0.5, 0.5], [3.5, 0.5], [3.5, 3.5], [0.5, 3.5]]]),
];

// ------------------------------------------------------------------ taper

_bsq = base(_sq);
_Nsq = __spp_edge_normals([for (p = _bsq[0]) p - _bsq[2]]);
function taper(p, h, scale=undef, scale_center=undef, draft=undef) =
    __spp_prism_taper(base(p), h, scale, scale_center, draft, "T");

_t_taper = [
    check("poly from distances", __spp_prism_poly_from_w(_Nsq, [2, 2, 2, 2]), [[-2, -2], [2, -2], [2, 2], [-2, 2]]),
    check("poly from distances, vanished side", __spp_prism_poly_from_w(
          __spp_edge_normals([[0, 0], [4, 0], [5, 1], [4, 2], [0, 2]]), [1, 3, -1, 1, 1]), undef),
    check("no taper", taper(_sq, 4), undef),
    check("scale about the centroid", taper(_sq, 4, scale=0.5), [1, 1, 1, 1]),
    check("scale about a point", taper(_sq, 4, scale=0.5, scale_center=[4, 2]),
          // the top square [2, 4] x [1, 3], seen from the centroid [2, 2] (side s3 passes through it)
          [1, 2, 1, 0]),
    check("draft", taper(_sq, 4, draft=45), [-2, -2, -2, -2]),
    check("draft list (user order)", taper(_sq, 4, draft=[0, 45, 0, -45]), [2, -2, 2, 6]),
    // clockwise input: the list follows the user's sides
    check("draft list clockwise", taper([[0, 4], [4, 4], [4, 0], [0, 0]], 4, draft=[45, 0, 0, 0]),
          // user side 0 runs from [0, 4] to [4, 4] (the top side, CCW side 2)
          [2, 2, -2, 2]),
    check("top polygon", __spp_prism_top(_bsq, [1, 1, 1, 1], "T"), [[-1, -1], [1, -1], [1, 1], [-1, 1]]),
    check("body box overhang", __spp_prism_body_box(_bsq[0], [[-1, -1], [5, -1], [5, 5], [-1, 5]], 4),
          [[-1, -1, -2], [5, 5, 2]]),
    // tapered spec: the top ring of a top bevel on the scaled square
    check("taper spec top ring", let(
              b = _bsq, e = __spp_prism_edges(b[1]),
              s = __spp_prism_spec(b, 4, __spp_prism_stages([bevel(0.5, "t")], e, b[0], b[3], "z", "T"), "T",
                                   taper(_sq, 4, scale=0.5)),
              r = s[0][len(s[0])-1])
          [r[0], r[1], s[3], s[1]],
          [2, [[1.5, 1.5], [2.5, 1.5], [2.5, 2.5], [1.5, 2.5]], [[0, 0, -2], [4, 4, 2]], true]),
    check("taper spec flare against the slanted wall", let(
              b = _bsq, e = __spp_prism_edges(b[1]),
              s = __spp_prism_spec(b, 4, __spp_prism_stages([rounding(-1, "b")], e, b[0], b[3], "z", "T"), "T",
                                   taper(_sq, 4, scale=0.5)))
          // fillet of radius 1 between the base plane and the wall leaning in by atan(1/4):
          // it reaches 1/tan((90 + atan(1/4))/2) along the base
          [s[1], s[4][0][0], s[4][1][0]], let(g = 1/tan((90 + atan(1/4))/2)) [false, -g, 4 + g]),
];

echo("ALL TESTS PASSED");
