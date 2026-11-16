// Tests of the data layer of the revolved solids (no geometry is produced).
// Run: openscad -o /tmp/out.echo tests/test_revolved.scad
// A failed test stops with an assert naming the test; the last echo is "ALL TESTS PASSED".

include<../solidpp.scad>

// ------------------------------------------------------------------ helpers

// approximate equality of numbers / nested lists, exact for other types
function __t_eq(a, b, eps=1e-6) =
    is_num(a) && is_num(b) ?
        abs(a - b) <= eps :
        is_list(a) && is_list(b) ?
            len(a) == len(b) && len([for (i = [0:1:len(a)-1]) if (!__t_eq(a[i], b[i], eps)) 1]) == 0 :
            a == b;

function check(name, got, expected, eps=1e-6) =
    assert(__t_eq(got, expected, eps), str("TEST FAILED: ", name, "\n  got:      ", got, "\n  expected: ", expected))
    true;

// points of a profile with given tag
function pts(profile, tag) = [for (v = profile) if (v[2] == tag) [v[0], v[1]]];

// profile of a cylinder / tube directly from the data layer
function cyl(args, mods) = __spp_cyl_spec(args, mods, false, false, "TEST")[2];
function tube(args, mods) = __spp_tube_spec(args, mods, false, false, "TEST")[3];

$fn = 0; $fa = 12; $fs = 2;

// ------------------------------------------------------------------ modifiers

_t_mod = [
    check("bevel number", bevel(1), ["__SPP_EDGE_MOD__", "bevel", [1, 1], ["all"]]),
    check("bevel pair + list where", bevel([1, 2], ["t", "bo"]), ["__SPP_EDGE_MOD__", "bevel", [1, 2], ["t", "bo"]]),
    check("rounding negative", rounding(-2, "b"), ["__SPP_EDGE_MOD__", "rounding", [-2, -2], ["b"]]),
    check("is edge mod", __spp_is_edge_mod(rounding(1)), true),
    check("legacy mod detected", __spp_is_legacy_mod(round_corners(1)), true),
    check("new mod is not legacy", __spp_is_legacy_mod(bevel(1)), false),
    check("mod list undef", __spp_resolve_mod_list(undef, "revolved", "TEST"), []),
];

// ------------------------------------------------------------------ fragments

_t_frag = [
    check("fragments default small", __spp_fragments(0.5), 5),
    check("fragments $fn", __spp_fragments(10, fn=6), 6),
    check("fragments $fn < 3", __spp_fragments(10, fn=2), 3),
    check("fragments $fa/$fs", __spp_fragments(10, fn=0, fa=1, fs=0.1), 360),
    check("fragments $fs bound", __spp_fragments(1, fn=0, fa=1, fs=0.5), 13),
];

// ------------------------------------------------------------------ selectors

_t_sel = [
    check("token t", __spp_select_tags(["t"], ["bi", "bo", "to", "ti"], "tboi", "T"), ["to", "ti"]),
    check("token it (order free)", __spp_select_tags(["it"], ["bi", "bo", "to", "ti"], "tboi", "T"), ["ti"]),
    check("token all", __spp_select_tags(["all"], ["bo", "to"], "tboi", "T"), ["bo", "to"]),
    check("token list", __spp_select_tags(["ti", "bo"], ["bi", "bo", "to", "ti"], "tboi", "T"), ["bo", "ti"]),
    check("selectable skips axis", __spp_selectable_tags(__spp_rev_cylinder_profile(1, 1, 1), "tboi"), ["bo", "to"]),
];

// ------------------------------------------------------------------ cylinder arguments

_t_cargs = [
    check("default", __spp_cyl_args(undef, undef, undef, undef, undef, undef, undef, undef, "z", "T"), [0.5, 0.5, 1]),
    check("d h", __spp_cyl_args(undef, undef, 10, 4, undef, undef, undef, undef, "z", "T"), [5, 5, 4]),
    check("r pair", __spp_cyl_args(undef, [3, 1], undef, 4, undef, undef, undef, undef, "z", "T"), [3, 1, 4]),
    check("size z", __spp_cyl_args([10, 10, 4], undef, undef, undef, undef, undef, undef, undef, "z", "T"), [5, 5, 4]),
    check("size x", __spp_cyl_args([4, 10, 10], undef, undef, undef, undef, undef, undef, undef, "x", "T"), [5, 5, 4]),
    check("size y", __spp_cyl_args([10, 4, 10], undef, undef, undef, undef, undef, undef, undef, "y", "T"), [5, 5, 4]),
    check("size scalar", __spp_cyl_args(6, undef, undef, undef, undef, undef, undef, undef, "z", "T"), [3, 3, 6]),
    check("r1 d2", __spp_cyl_args(undef, undef, undef, 2, 3, undef, undef, 2, "z", "T"), [3, 1, 2]),
    check("size + r1 r2 ratio", __spp_cyl_args([10, 10, 2], undef, undef, undef, 2, 1, undef, undef, "z", "T"), [5, 2.5, 2]),
    check("cone apex", __spp_cyl_args(undef, undef, undef, 3, 2, 0, undef, undef, "z", "T"), [2, 0, 3]),
];

// ------------------------------------------------------------------ tube arguments

_t_targs = [
    check("tube default", __spp_tube_args(undef, undef, undef, undef, undef, undef, undef, "z", "T"), [0.5, 0.5, 1, 1, 1]),
    check("tube r R", __spp_tube_args(undef, undef, 3, undef, 5, undef, 10, "z", "T"), [3, 3, 5, 5, 10]),
    check("tube t R", __spp_tube_args(undef, 1, undef, undef, 5, undef, 2, "z", "T"), [4, 4, 5, 5, 2]),
    check("tube t d", __spp_tube_args(undef, 1, undef, 6, undef, undef, 2, "z", "T"), [3, 3, 4, 4, 2]),
    check("tube D d", __spp_tube_args(undef, undef, undef, 6, undef, 10, 2, "z", "T"), [3, 3, 5, 5, 2]),
    check("tube pairs", __spp_tube_args(undef, 1, [2, 3], undef, undef, undef, 2, "z", "T"), [2, 3, 3, 4, 2]),
    check("tube size", __spp_tube_args([10, 10, 3], 1, undef, undef, undef, undef, undef, "z", "T"), [4, 4, 5, 5, 3]),
    check("tube size x", __spp_tube_args([3, 10, 10], undef, 2, undef, undef, undef, undef, "x", "T"), [2, 2, 5, 5, 3]),
];

// ------------------------------------------------------------------ cylinder profiles

_c0 = cyl([5, 5, 4], []);
_c_bevel_t = cyl([5, 5, 4], [bevel(1, "t")]);
_c_bevel_pair = cyl([5, 5, 4], [bevel([1, 0.5], "b")]);
_c_round_t = cyl([5, 5, 4], [rounding(1, "t")]);
_c_ell = cyl([5, 5, 4], [rounding([2, 1], "t")]);
_c_bev_round = cyl([5, 5, 4], [bevel(1, "t"), rounding(0.2, "t")]);
_c_flare_b = cyl([5, 5, 4], [bevel(-1, "b")]);
_c_flare_r = cyl([5, 5, 4], [rounding([-2, -1], "b")]);
_c_cone = cyl([5, 0, 4], [bevel(1, "b")]);
_c_noop = cyl([5, 5, 4], [bevel(0)]);

_t_cprof = [
    check("plain profile", __spp_profile_points(_c0), [[0, -2], [5, -2], [5, 2], [0, 2]]),
    check("bevel top", pts(_c_bevel_t, "to"), [[5, 1], [4, 2]]),
    check("bevel top keeps bottom", pts(_c_bevel_t, "bo"), [[5, -2]]),
    check("bevel [across, along] bottom", pts(_c_bevel_pair, "bo"), [[4, -2], [5, -1.5]]),
    check("rounding tangent points",
        [pts(_c_round_t, "to")[0], pts(_c_round_t, "to")[len(pts(_c_round_t, "to"))-1]], [[5, 1], [4, 2]]),
    check("rounding arc radius",
        [for (p = pts(_c_round_t, "to")) norm(p - [4, 1])], [for (p = pts(_c_round_t, "to")) 1]),
    check("rounding marks smooth", [for (v = _c_round_t) if (v[2] == "to") v[3]], [for (v = _c_round_t) if (v[2] == "to") false]),
    check("elliptic tangent points",
        [pts(_c_ell, "to")[0], pts(_c_ell, "to")[len(pts(_c_ell, "to"))-1]], [[5, 1], [3, 2]]),
    check("elliptic on ellipse",
        [for (p = pts(_c_ell, "to")) pow((p[0]-3)/2, 2) + pow(p[1]-1, 2)], [for (p = pts(_c_ell, "to")) 1]),
    check("bevel then rounding: ends",
        [pts(_c_bev_round, "to")[0], pts(_c_bev_round, "to")[len(pts(_c_bev_round, "to"))-1]],
        [[5, 1 - 0.2*tan(22.5)], [4 - 0.2*tan(22.5), 2]]),
    check("flare bevel", pts(_c_flare_b, "bo"), [[6, -2], [5, -1]]),
    check("flare rounding ends",
        [pts(_c_flare_r, "bo")[0], pts(_c_flare_r, "bo")[len(pts(_c_flare_r, "bo"))-1]], [[7, -2], [5, -1]]),
    check("flare rounding concave",
        [for (p = pts(_c_flare_r, "bo")) pow((p[0]-7)/2, 2) + pow(p[1]+1, 2)], [for (p = pts(_c_flare_r, "bo")) 1]),
    check("cone bevel uses along on the wall", pts(_c_cone, "bo"), [[4, -2], [5 - 5/4, -1]]),
    check("zero is no-op", _c_noop, _c0),
    check("max x with flare", __spp_max_x(__spp_profile_points(_c_flare_r)), 7),
];

// ------------------------------------------------------------------ flare flags

_t_flags = [
    check("align radius without flare", __spp_cyl_spec([5, 5, 4], [bevel(-1, "b")], false, false, "T")[1], 5),
    check("align radius with flare", __spp_cyl_spec([5, 5, 4], [bevel(-1, "b")], false, true, "T")[1], 6),
    check("flare in size shrinks body",
        __spp_max_x(__spp_cyl_spec([5, 5, 4], [bevel(-1, "b")], true, false, "T")[0]), 5),
    check("flare in size body radius",
        pts(__spp_cyl_spec([5, 5, 4], [bevel(-1, "b")], true, false, "T")[2], "to"), [[4, 2]]),
    check("flare in size, align with flare",
        __spp_cyl_spec([5, 5, 4], [bevel(-1, "b")], true, true, "T")[1], 5),
    check("flare in size, align without flare",
        __spp_cyl_spec([5, 5, 4], [bevel(-1, "b")], true, false, "T")[1], 4),
];

// ------------------------------------------------------------------ tube profiles and chains

_tb = tube([3, 3, 5, 5, 6], [bevel(0.5, "ti"), rounding(-1, "bo")]);
_tb_spec = __spp_tube_spec([3, 3, 5, 5, 6], [bevel(0.5, "ti")], false, false, "T");
_tb_inner_flare = tube([3, 3, 5, 5, 6], [bevel(-1, "i")]);

_t_tube = [
    check("tube plain", __spp_profile_points(tube([3, 3, 5, 5, 6], [])), [[3, -3], [5, -3], [5, 3], [3, 3]]),
    check("tube bevel ti", pts(_tb, "ti"), [[3.5, 3], [3, 2.5]]),
    check("tube untouched to", pts(_tb, "to"), [[5, 3]]),
    check("tube outer body", _tb_spec[0], [[0, -3], [5, -3], [5, 3], [0, 3]]),
    check("tube hole cutter", _tb_spec[1], [[0, 10], [3.5, 10], [3.5, 3], [3, 2.5], [3, -3], [3, -10], [0, -10]]),
    check("tube inner flare", [pts(_tb_inner_flare, "ti"), pts(_tb_inner_flare, "bi")],
        [[[2, 3], [3, 2]], [[3, -2], [2, -3]]]),
    check("tube bevel t takes both", [pts(tube([3, 3, 5, 5, 6], [bevel(0.5, "t")]), "to"),
                                      pts(tube([3, 3, 5, 5, 6], [bevel(0.5, "t")]), "ti")],
        [[[5, 2.5], [4.5, 3]], [[3.5, 3], [3, 2.5]]]),
    check("tube conical", __spp_profile_points(tube([2, 3, 4, 5, 2], [])), [[2, -1], [4, -1], [5, 1], [3, 1]]),
];

// ------------------------------------------------------------------ polygon modes

_t_poly = [
    check("corners scale", __spp_polygon_scale("corners", 6, "T"), 1),
    check("flats scale hex", __spp_polygon_scale("flats", 6, "T"), 2/sqrt(3)),
    check("polyhole scale", __spp_polygon_scale("polyhole", 8, "T"), 1/cos(22.5)),
    check("polyhole sides d=3", __spp_polyhole_sides(1.5), 6),
    check("polyhole sides d=8", __spp_polyhole_sides(4), 16),
    check("polyhole sides minimum", __spp_polyhole_sides(0.5), 3),
    check("polyhole sides rounding", __spp_polyhole_sides(1.6), 6),
    check("wall sides polyhole", __spp_wall_sides(undef, "polyhole", 2, "T"), 8),
    check("wall sides fn", __spp_wall_sides(12, "flats", 2, "T"), 12),
    check("wall sides default", __spp_wall_sides(undef, "corners", 2, "T"), undef),
];

// ------------------------------------------------------------------ sector

_t_sector = [
    check("sector undef", __spp_check_sector(undef, "z", "T"), undef),
    check("sector full is undef", __spp_check_sector(360, "z", "T"), undef),
    check("sector full range is undef", __spp_check_sector([-180, 180], "z", "T"), undef),
    check("sector angle zet z", __spp_check_sector(90, "z", "T"), [0, 90]),
    check("sector range zet z", __spp_check_sector([-45, 45], "z", "T"), [-45, 90]),
    check("sector zet x starts at +y", __spp_check_sector(90, "x", "T"), [90, 90]),
    check("sector zet y starts at +z", __spp_check_sector([10, 100], "y", "T"), [280, 90]),
];

// ------------------------------------------------------------------ face names (grammar)

_t_names = [
    check("names single", __spp_face_names("t"), ["t"]),
    check("names concat", __spp_face_names("tog12"), ["t", "o", "g12"]),
    check("names invalid digit first", __spp_face_names("1g"), undef),
    check("names invalid char", __spp_face_names("g-1"), undef),
    check("names empty", __spp_face_names(""), undef),
    check("letters", __spp_letters("tog12h3"), "togh"),
    check("family matches numbered", __spp_token_matches("g", "og1"), true),
    check("numbered matches itself", __spp_token_matches("g1", "og1"), true),
    check("numbered does not match other", __spp_token_matches("g1", "og2"), false),
    check("numbered does not match bare", __spp_token_matches("g1", "og"), false),
    check("old tokens still work", __spp_token_matches("it", "ti"), true),
    check("axis tag not selectable", __spp_selectable_tags([[0, 0, "_", false], [1, 0, "bo", true]], "tboi"), ["bo"]),
    check("select family", __spp_select_tags(["g"], ["og1", "og2", "to"], "tbog", "T"), ["og1", "og2"]),
];

// ------------------------------------------------------------------ revolvepp

// stepped shaft: d=20 h=5 below, d=10 h=10 above
_shaft = [[0, 0], [10, 0], [10, 5], [5, 5], [5, 15], [0, 15]];
function revp(points) = __spp_revp_profile(points, "T");
function tags(profile) = [for (v = profile) v[2]];
function area(profile) = __spp_signed_area(__spp_profile_points(profile));

_rp = revp(_shaft);
_rp_tagged = revp([[0, 0], [10, 0], [10, 5], [5, 5], [5, 15, "t1"], [0, 15]]);
// the same profile clockwise: the tag stays on the top face (segment starting at [0, 15])
_rp_cw = revp([[0, 15, "t1"], [5, 15], [5, 5], [10, 5], [10, 0], [0, 0]]);
// slanted shoulder forced into the top group
_rp_forced = revp([[0, 0], [10, 0], [10, 5, "t", "f"], [5, 8], [5, 15], [0, 15]]);
_rp_slanted = revp([[0, 0], [10, 0], [10, 5], [5, 8], [5, 15], [0, 15]]);
// a groove tagged "g" on the outer wall, cylinder with a tube-like hole on top
_rp_groove = revp([[0, 0], [10, 0], [10, 4], [8, 5, "g"], [10, 6], [10, 10], [4, 10], [4, 6], [0, 6]]);

_t_revp = [
    check("revp auto tags", tags(_rp[0]), ["_", "bo", "to", "to", "to", "_"]),
    check("revp centered", [for (v = _rp[0]) v[1]], [-7.5, -7.5, -2.5, -2.5, 7.5, 7.5]),
    check("revp height", _rp[1], 15),
    check("revp keep", [for (v = __spp_revp_profile(_shaft, "T", true)[0]) v[1]], [0, 0, 5, 5, 15, 15]),
    check("revp letters", _rp[2], "tboi"),
    check("revp refined tag", tags(_rp_tagged[0]), ["_", "bo", "to", "to", "tot1", "_"]),
    check("revp refined select", __spp_select_tags(["t1"], __spp_selectable_tags(_rp_tagged[0], "tboi"), "tboi", "T"), ["tot1"]),
    check("revp family includes refined", __spp_select_tags(["t"], __spp_selectable_tags(_rp_tagged[0], "tboi"), "tboi", "T"), ["to", "tot1"]),
    check("revp cw = ccw", _rp_cw, _rp_tagged),
    check("revp slanted is o", tags(_rp_slanted[0]), ["_", "bo", "o", "o", "to", "_"]),
    check("revp forced", tags(_rp_forced[0]), ["_", "bo", "to", "to", "to", "_"]),
    check("revp groove", tags(_rp_groove[0]), ["_", "bo", "o", "og", "og", "to", "ti", "ti", "_"]),
    check("revp groove letters", _rp_groove[2], "tboig"),
    check("revp hole wall is i", tags(revp([[0, 0], [10, 0], [10, 10], [4, 10], [4, 6], [0, 6]])[0]),
          ["_", "bo", "to", "ti", "ti", "_"]),
    check("revp collinear point is not an edge", tags(revp([[0, 0], [10, 0], [10, 5], [10, 10], [0, 10]])[0]),
          ["_", "bo", "_", "to", "_"]),
    check("revp torus-like (off axis)", tags(revp([[2, 0], [4, 0], [4, 2], [2, 2]])[0]), ["bi", "bo", "to", "ti"]),
    // rounding of the top edges: two convex (remove) and one concave (fill)
    check("revp concave fill area", area(__spp_profile_apply_mods(_rp[0], [rounding(1, "to")], "tboi", "T", 0)),
          100 - (1 - sin(45))),
    check("revp concave bevel area", area(__spp_profile_apply_mods(_rp[0], [bevel(1, "to")], "tboi", "T", 0)),
          100 - 0.5),
    check("revp spec", let(s = __spp_revp_spec(_shaft, [rounding(-1, "bo")], true, "T")) [s[1], s[3], s[4]], [11, 10, 15]),
    check("revp spec no flare in align", __spp_revp_spec(_shaft, [rounding(-1, "bo")], false, "T")[1], 10),
    check("self intersection found", __spp_first_self_intersection([[0, 0], [2, 2], [2, 0], [0, 2]]), [0, 2]),
    check("simple polygon", __spp_first_self_intersection(__spp_profile_points(_rp[0])), undef),
    check("fold back found", __spp_first_self_intersection([[0, 0], [4, 0], [2, 0], [2, 3]]), [0, 1]),
];

echo("ALL TESTS PASSED");
