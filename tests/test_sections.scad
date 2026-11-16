// Tests of the section shapes (teardrop, serration) of cylinderpp and tubepp (no geometry).
// Run: openscad -o /tmp/out.echo tests/test_sections.scad
// A failed test stops with an assert naming the test; the last echo is "ALL TESTS PASSED".

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

function sum(l) = len(l) == 0 ? 0 : l[0] + sum([for (i = [1:1:len(l)-1]) l[i]]);
function area(p) = let(n = len(p)) sum([for (i = [0:1:n-1]) cross(p[i], p[(i+1)%n])]) / 2;

// point of the outline farthest in the direction 'u'
function farthest(p, u) = let(d = [for (q = p) q*u], m = max(d)) [for (i = [0:1:len(p)-1]) if (d[i] == m) p[i]][0];

$fn = 0; $fa = 12; $fs = 2;

r = 5;
fine = 720;

// ------------------------------------------------------------------ constructors and resolution

_t_res = [
    check("teardrop record", teardrop(), ["__SPP_SECTION__", "teardrop", undef, 45, "point"]),
    check("serration record", serration(6, 0.2), ["__SPP_SECTION__", "serration", 6, 0.2, "triangle", undef]),
    check("undef is plain", __spp_is_plain_section(__spp_resolve_section(undef, "z", "T", "section")), true),
    check("default up zet z is x (-x)", __spp_resolve_section(teardrop(), "z", "T", "section")[0][2], [-1, 0]),
    check("default up zet x is Z", __spp_resolve_section(teardrop(), "x", "T", "section")[0][2], [-1, 0]),
    check("default up zet y is Z", __spp_resolve_section(teardrop(), "y", "T", "section")[0][2], [0, -1]),
    check("up Y zet z", __spp_resolve_section(teardrop(up="Y"), "z", "T", "section")[0][2], [0, 1]),
    check("combo", __spp_resolve_section([teardrop(cap="bridge"), serration(8, 0.3, "round")], "z", "T", "section"),
        [[45, "bridge", [-1, 0]], [8, 0.3, "round", undef]]),
    check("serration only", __spp_resolve_section(serration(8, 0.3), "z", "T", "section"),
        [undef, [8, 0.3, "triangle", undef]]),
];

// ------------------------------------------------------------------ outlines

_td = __spp_teardrop_outline(r, fine, 45, "point", [0, 1]);
_tb = __spp_teardrop_outline(r, fine, 45, "bridge", [0, 1]);
_t30 = __spp_teardrop_outline(r, fine, 30, "point", [0, 1]);
_tx = __spp_teardrop_outline(r, 32, 45, "point", [-1, 0]);

_t_outline = [
    check("teardrop area", area(_td), r*r*(1 + 3*PI/4), 0.01),
    check("bridged teardrop area", area(_tb), r*r*(1 + 3*PI/4) - pow((sqrt(2) - 1)*r, 2), 0.01),
    check("teardrop tip", farthest(_td, [0, 1]), [0, r*sqrt(2)]),
    check("teardrop angle 30 tip", farthest(_t30, [0, 1]), [0, r/sin(60)]),
    check("bridged teardrop stays in the circle box", farthest(_tb, [0, 1])[1], r),
    check("bridge width", let(t = [for (p = _tb) if (abs(p[1] - r) < 1e-9) p[0]]) max(t) - min(t), 2*(sqrt(2) - 1)*r),
    check("teardrop rotated to -x", farthest(_tx, [-1, 0]), [-r*sqrt(2), 0]),
    check("teardrop is counter-clockwise", area(_tx) > 0, true),
    check("circle outline", len(__spp_section_outline(r, 8, undef, "corners", "T")), 8),
    check("flats outline", norm(__spp_section_outline(r, 6, undef, "flats", "T")[0]), r/cos(30)),
    // offset of a teardrop is the teardrop of the smaller radius
    check("teardrop offset", area(__spp_section_ring(_td, r, 3, 100)), 9*(1 + 3*PI/4), 0.01),
];

// ------------------------------------------------------------------ serration

_c = __spp_circle_outline(r, fine);
_tri = __spp_serrate(_c, __spp_serration_plan(_c, [12, 0.4, "triangle", undef], undef, r, "T"), [12, 0.4, "triangle", undef]);
// fine arcs of the round grooves
_rnd = let($fa = 1, $fs = 0.01)
    __spp_serrate(_c, __spp_serration_plan(_c, [12, 0.4, "round", undef], undef, r, "T"), [12, 0.4, "round", undef]);
_seg = r*r/2*(2*asin(0.4/r)*PI/180 - sin(2*asin(0.4/r)));
_td_tri = __spp_serrate(_td, __spp_serration_plan(_td, [8, 0.3, "triangle", undef], [45, "point", [0, 1]], r, "T"),
                        [8, 0.3, "triangle", undef]);
_tb_rnd = let($fa = 1, $fs = 0.01)
    __spp_serrate(_tb, __spp_serration_plan(_tb, [8, 0.3, "round", undef], [45, "bridge", [0, 1]], r, "T"),
                  [8, 0.3, "round", undef]);

_t_serr = [
    check("triangle points", len(_tri), 24),
    check("triangle tips on the circle", [for (i = [0:2:23]) norm(_tri[i])], [for (i = [0:11]) r], 1e-3),
    check("triangle area", area(_tri), 12*r*(r - 0.4)*sin(15), 0.01),
    check("round area", area(_rnd), PI*r*r - 12*(PI*0.16/2 + _seg), 0.01),
    // teardrop: grooves only on the circular part, the tip faces and the cap stay plain
    check("teardrop + triangle: tip untouched",
        [for (q = _td_tri) if (q[1] > r*sin(45) + 1e-6) q], [[0, r*sqrt(2)]]),
    check("teardrop + triangle: starts and ends at the tangent points",
        [_td_tri[0], _td_tri[2*8]], [r*[cos(135), sin(135)], r*[cos(45), sin(45)]]),
    check("teardrop + triangle: points", len(_td_tri), 2*8 + 1 + 1),
    check("teardrop + round: tip untouched",
        [for (q = _tb_rnd) if (q[1] > r*sin(45) + 1e-6) q], [for (q = _tb) if (q[1] > r*sin(45) + 1e-6) q]),
    check("teardrop + round: grooves inside the circular part",
        len([for (q = _tb_rnd) if (norm(q) < r - 1e-6 && q[1] > r*sin(45) - 1e-6) 1]), 0),
    check("teardrop + round: area", area(_tb_rnd), area(_tb) - 8*(PI*0.09/2 + r*r/2*(2*asin(0.3/r)*PI/180 - sin(2*asin(0.3/r)))), 0.01),
];

// ------------------------------------------------------------------ chains and regions

_p_bevel = __spp_cyl_profile(5, 5, 6, [bevel(1)], "T");
_p_meet = __spp_cyl_profile(5, 5, 2, [rounding(1)], "T");
_p_tube = __spp_tube_profile([2, 2, 5, 5, 8], [bevel(0.5, "ti")], "T");
_p_cone_hole = __spp_tube_profile([2, 3, 5, 5, 8], [], "T");

_t_chain = [
    check("outer chain with bevels", __spp_rev_outer_chain(_p_bevel, 6, 5, 5),
        [[[4, -3], [5, -2], [5, 2], [4, 3]], [-2, 2], [[5, -3], [5, 3]]]),
    check("no straight part when roundings meet", __spp_rev_outer_chain(_p_meet, 2, 5, 5)[1], undef),
    check("cone apex chain", __spp_rev_outer_chain(__spp_cyl_profile(5, 0, 4, [], "T"), 4, 5, 0)[0],
        [[5, -2], [0, 2]]),
    check("inner chain: unmodified end runs through the protrusion",
        __spp_rev_inner_chain(_p_tube, 8, 1, 2, 2),
        [[[2, -5], [2, -4], [2, 3.5], [2.5, 4], [2.5, 5]], [-5, 3.5], [[2, -4], [2, 4]]]),
    check("inner chain of a conical hole continues the wall line",
        __spp_rev_inner_chain(_p_cone_hole, 8, 1, 2, 3)[0][0], [2 - 1/8, -5]),
    check("protrusion of a steep conical hole", __spp_rev_inner_protrusion(1, 5, 4), 0.5),
];

// ------------------------------------------------------------------ pieces

_pc_td = __spp_section_pieces([[5, -3], [5, 3]], [-3, 3], [[5, -3], [5, 3]], 5, [[45, "point", [0, 1]], undef], 32, "corners", "T");
_pc_sr = __spp_section_pieces([[4, -3], [5, -2], [5, 2], [4, 3]], [-2, 2], [[5, -3], [5, 3]], 5,
                              [undef, [8, 0.3, "triangle", undef]], 32, "corners", "T");
_pc_fl = __spp_section_pieces([[6, -3], [5, -2], [5, 3]], [-2, 3], [[5, -3], [5, 3]], 5, [[45, "point", [0, 1]], undef], 32, "corners", "T");

_t_pieces = [
    check("teardrop: one hull", [for (p = _pc_td) p[0]], ["hull"]),
    check("serration: bottom hull, prism, top hull", [for (p = _pc_sr) p[0]], ["hull", "prism", "hull"]),
    check("serration prism heights", [_pc_sr[1][1][0], _pc_sr[1][2][0]], [-2, 2]),
    check("serration prism points", len(_pc_sr[1][1][1]), 16),
    check("flare: slab and hull", [for (p = _pc_fl) [p[0], len(p[1])]], [["hull", 2], ["hull", 2]]),
    // flare at the small end of a cone: outside the slanted wall line, although inside the larger radius
    check("cone flare at the small end",
        [for (p = __spp_section_pieces([[5, -3], [2, 2], [3, 3]], [-3, 2], [[5, -3], [2, 3]], 5,
                                       [[45, "point", [0, 1]], undef], 32, "corners", "T")) [p[0], len(p[1])]],
        [["hull", 2], ["hull", 2]]),
];

echo("ALL TESTS PASSED");
