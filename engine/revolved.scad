// Revolved solids: profiles of cylinderpp and tubepp, argument parsing
//
// Profiles (x = radius, y = axis, centered in y), see DESIGN.md section 4:
// - cylinder: ba(0,-h/2) bo(R1,-h/2) to(R2,h/2) ta(0,h/2)
//   '-> 'ba'/'ta' lie on the axis and cannot be selected
//   '-> a zero radius base has no edge (cone apex)
// - tube:     bi(r1,-h/2) bo(R1,-h/2) to(R2,h/2) ti(r2,h/2)

include<../utils/solidpp_utils.scad>
include<profile.scad>
include<../modifiers/legacy_modifiers.scad>

// letters usable in 'where' selectors of revolved solids
__SPP_REV_LETTERS = "tboi";


// ------------------------------------------------------------------ helpers

// number or [bottom, top] pair as a pair
function __spp_as_pair(v) = is_num(v) ? [v, v] : v;

// true iff 'v' is a number or a pair of numbers
function __spp_is_num_or_pair(v) =
    is_num(v) || (is_list(v) && len(v) == 2 && is_num(v[0]) && is_num(v[1]));

// checks 'zet' and returns it with the default "z"
function __spp_check_zet(zet, ctx) =
    let(_zet = is_undef(zet) ? "z" : zet)
    assert(is_string(_zet) && len(_zet) == 1 && __spp_char_in(_zet, "xXyYzZ"),
        str("[", ctx, "] argument 'zet' must be one of \"x\", \"y\", \"z\", got ", zet))
    _zet;

// checks 'size' of a revolved solid and returns [d, h] or undef
// '-> 'size' is a number or [x, y, z] in the parent frame, base dimensions must be equal
function __spp_rev_size(size, zet, ctx) =
    is_undef(size) ?
        undef :
        assert(is_num(size) ||
               (is_list(size) && len(size) == 3 && is_num(size[0]) && is_num(size[1]) && is_num(size[2])),
            str("[", ctx, "] argument 'size' must be a number or a list of 3 numbers, got ", size))
        let(
            _s = is_num(size) ? [size, size, size] : size,
            _abh = __solidpp__get_a_b_h_from_size_and_zet(_s, zet)
        )
        assert(_abh[0] == _abh[1],
            str("[", ctx, "] elliptical solids are not supported: both base dimensions of 'size' ",
                "must be equal, got ", size, " for zet=\"", zet, "\""))
        [_abh[0], _abh[2]];


// checks the 'sector' argument and returns undef (full revolution) or [start, angle] in the
// local frame of the solid (degrees from the local +x, counter-clockwise around +zet)
// - 'sector' is undef, an angle (sweep from 0), or [from, to] with 0 < to - from <= 360
// - angles follow the right-hand rule around 'zet' and start at the next axis of the cycle
//   x -> y -> z: +x for zet "z", +y for zet "x", +z for zet "y"
function __spp_check_sector(sector, zet, ctx) =
    is_undef(sector) ?
        undef :
        let(s = is_num(sector) ? [0, sector] : sector)
        assert(is_list(s) && len(s) == 2 && is_num(s[0]) && is_num(s[1]),
            str("[", ctx, "] argument 'sector' must be an angle or [from, to], got ", sector))
        assert(s[1] - s[0] > 0 && s[1] - s[0] <= 360,
            str("[", ctx, "] argument 'sector' must sweep more than 0 and at most 360 degrees, got ", sector))
        s[1] - s[0] == 360 ?
            undef :
            let(
                // angle of the reference axis in the local frame (see the frame of box.scad):
                // zet x: +y is local +v (90), zet y: +z is local -v (270)
                ref = zet == "x" || zet == "X" ? 90 : (zet == "y" || zet == "Y" ? 270 : 0)
            )
            [ref + s[0], s[1] - s[0]];

// ------------------------------------------------------------------ profiles

function __spp_rev_cylinder_profile(R1, R2, h) =
    let(h2 = h/2)
    [
        [0, -h2, "ba", false],
        if (R1 > 0) [R1, -h2, "bo", true],
        if (R2 > 0) [R2,  h2, "to", true],
        [0,  h2, "ta", false]
    ];

function __spp_rev_tube_profile(r1, r2, R1, R2, h) =
    let(h2 = h/2)
    [
        [r1, -h2, "bi", true],
        [R1, -h2, "bo", true],
        [R2,  h2, "to", true],
        [r2,  h2, "ti", true]
    ];

// points of the given tag in the profile order
function __spp_rev_tag_points(profile, tag) =
    [for (v = profile) if (v[2] == tag) [v[0], v[1]]];

// outer body of a tube: solid of revolution bounded by the outer chain ('bo', 'to')
function __spp_rev_outer_body(profile) =
    let(c = [each __spp_rev_tag_points(profile, "bo"), each __spp_rev_tag_points(profile, "to")])
    [[0, c[0][1]], each c, [0, c[len(c)-1][1]]];

// hole cutter of a tube: bounded by the inner chain ('ti', 'bi'), protruding by 'e'
function __spp_rev_hole_cutter(profile, e) =
    let(
        c = [each __spp_rev_tag_points(profile, "ti"), each __spp_rev_tag_points(profile, "bi")],
        f = c[0],
        l = c[len(c)-1]
    )
    [[0, f[1] + e], [f[0], f[1] + e], each c, [l[0], l[1] - e], [0, l[1] - e]];


// ------------------------------------------------------------------ cylinderpp

// parses the arguments of cylinderpp, returns [R1, R2, h]
function __spp_cyl_args(size, r, d, h, r1, r2, d1, d2, zet, ctx) =
    let(
        _has_size = !is_undef(size),
        _has_rd = !is_undef(r) || !is_undef(d),
        _has_b = !is_undef(r1) || !is_undef(d1),
        _has_t = !is_undef(r2) || !is_undef(d2),
        _has_12 = _has_b || _has_t
    )
    assert(is_undef(r) || is_undef(d), str("[", ctx, "] use either 'r' or 'd', not both"))
    assert(is_undef(r1) || is_undef(d1), str("[", ctx, "] use either 'r1' or 'd1', not both"))
    assert(is_undef(r2) || is_undef(d2), str("[", ctx, "] use either 'r2' or 'd2', not both"))
    assert(!(_has_rd && _has_12), str("[", ctx, "] 'r|d' cannot be combined with 'r1|d1', 'r2|d2'"))
    assert(!_has_size || (!_has_rd && is_undef(h)),
        str("[", ctx, "] 'size' cannot be combined with 'r|d' or 'h'"))
    assert(_has_b == _has_t, str("[", ctx, "] both 'r1|d1' and 'r2|d2' must be defined"))
    assert(is_undef(r) || __spp_is_num_or_pair(r),
        str("[", ctx, "] argument 'r' must be a number or [bottom, top], got ", r))
    assert(is_undef(d) || __spp_is_num_or_pair(d),
        str("[", ctx, "] argument 'd' must be a number or [bottom, top], got ", d))
    assert(is_undef(r1) || is_num(r1), str("[", ctx, "] argument 'r1' must be a number, got ", r1))
    assert(is_undef(r2) || is_num(r2), str("[", ctx, "] argument 'r2' must be a number, got ", r2))
    assert(is_undef(d1) || is_num(d1), str("[", ctx, "] argument 'd1' must be a number, got ", d1))
    assert(is_undef(d2) || is_num(d2), str("[", ctx, "] argument 'd2' must be a number, got ", d2))
    assert(is_undef(h) || is_num(h), str("[", ctx, "] argument 'h' must be a number, got ", h))
    let(
        _dh = __spp_rev_size(size, zet, ctx),
        _dd = _has_12 ?
                [is_undef(d1) ? 2*r1 : d1, is_undef(d2) ? 2*r2 : d2] :
                !is_undef(d) ?
                    __spp_as_pair(d) :
                    !is_undef(r) ?
                        2*__spp_as_pair(r) :
                        _has_size ?
                            [_dh[0], _dh[0]] :
                            [1, 1]
    )
    assert(_dd[0] >= 0 && _dd[1] >= 0 && max(_dd) > 0,
        str("[", ctx, "] radii must be non-negative and at least one must be positive"))
    let(
        // with 'size' and 'r1|d1, r2|d2', the greater base fits the 'size'
        __dd = _has_size && _has_12 ? _dd * (_dh[0] / max(_dd)) : _dd,
        _h = _has_size ? _dh[1] : (is_undef(h) ? 1 : h)
    )
    assert(_h > 0, str("[", ctx, "] height must be positive, got ", _h))
    [__dd[0]/2, __dd[1]/2, _h];

// modified profile of a cylinder
function __spp_cyl_profile(R1, R2, h, mods, ctx) =
    __spp_profile_apply_mods(__spp_rev_cylinder_profile(R1, R2, h), mods, __SPP_REV_LETTERS, ctx, 0);

// complete data of a cylinder
// returns [profile points, radius used for alignment, modified tagged profile, body radius, [R1, R2] of the body]
function __spp_cyl_spec(args, mods, flare_in_size, flare_in_align, ctx) =
    let(
        R1 = args[0], R2 = args[1], h = args[2],
        p0 = __spp_cyl_profile(R1, R2, h, mods, ctx),
        nominal = max(R1, R2),
        grow = __spp_max_x(p0) - nominal,
        shrink = flare_in_size && grow > 1e-9 ? grow : 0,
        _R1 = R1 > 0 ? R1 - shrink : 0,
        _R2 = R2 > 0 ? R2 - shrink : 0
    )
    assert((R1 == 0 || _R1 > 0) && (R2 == 0 || _R2 > 0),
        str("[", ctx, "] flare_in_size: the flare is wider than the radius"))
    let(
        p = shrink > 0 ? __spp_cyl_profile(_R1, _R2, h, mods, ctx) : p0,
        body_r = nominal - shrink,
        full_r = max(body_r, __spp_max_x(p))
    )
    [__spp_profile_points(p), flare_in_align ? full_r : body_r, p, body_r, [_R1, _R2]];


// ------------------------------------------------------------------ tubepp

// parses the arguments of tubepp, returns [r1, r2, R1, R2, h] (hole radii, outer radii)
function __spp_tube_args(size, t, r, d, R, D, h, zet, ctx) =
    assert(is_undef(r) || is_undef(d), str("[", ctx, "] use either 'r' or 'd', not both"))
    assert(is_undef(R) || is_undef(D), str("[", ctx, "] use either 'R' or 'D', not both"))
    assert(is_undef(size) || (is_undef(R) && is_undef(D) && is_undef(h)),
        str("[", ctx, "] 'size' cannot be combined with 'R|D' or 'h'"))
    assert(is_undef(t) || __spp_is_num_or_pair(t),
        str("[", ctx, "] argument 't' must be a number or [bottom, top], got ", t))
    assert(is_undef(r) || __spp_is_num_or_pair(r),
        str("[", ctx, "] argument 'r' must be a number or [bottom, top], got ", r))
    assert(is_undef(d) || __spp_is_num_or_pair(d),
        str("[", ctx, "] argument 'd' must be a number or [bottom, top], got ", d))
    assert(is_undef(R) || __spp_is_num_or_pair(R),
        str("[", ctx, "] argument 'R' must be a number or [bottom, top], got ", R))
    assert(is_undef(D) || __spp_is_num_or_pair(D),
        str("[", ctx, "] argument 'D' must be a number or [bottom, top], got ", D))
    assert(is_undef(h) || is_num(h), str("[", ctx, "] argument 'h' must be a number, got ", h))
    let(
        _dh = __spp_rev_size(size, zet, ctx),
        _ri = !is_undef(d) ? __spp_as_pair(d)/2 : (!is_undef(r) ? __spp_as_pair(r) : undef),
        _Ro = !is_undef(_dh) ?
                [_dh[0], _dh[0]]/2 :
                !is_undef(D) ?
                    __spp_as_pair(D)/2 :
                    (!is_undef(R) ? __spp_as_pair(R) : undef),
        _t = is_undef(t) ? undef : __spp_as_pair(t),
        _n = (is_undef(_ri) ? 0 : 1) + (is_undef(_Ro) ? 0 : 1) + (is_undef(_t) ? 0 : 1)
    )
    assert(_n == 0 || _n == 2,
        str("[", ctx, "] exactly two of 't', 'r|d', 'R|D' must be defined ('size' counts as 'R|D')"))
    let(
        ri = _n == 0 ? [0.5, 0.5] : (is_undef(_ri) ? _Ro - _t : _ri),
        Ro = _n == 0 ? [1, 1] : (is_undef(_Ro) ? _ri + _t : _Ro),
        _h = !is_undef(_dh) ? _dh[1] : (is_undef(h) ? 1 : h)
    )
    assert(ri[0] > 0 && ri[1] > 0, str("[", ctx, "] hole radius must be positive, got ", ri))
    assert(Ro[0] > ri[0] && Ro[1] > ri[1],
        str("[", ctx, "] outer radius ", Ro, " must be greater than the hole radius ", ri))
    assert(_h > 0, str("[", ctx, "] height must be positive, got ", _h))
    [ri[0], ri[1], Ro[0], Ro[1], _h];

// modified profile of a tube
function __spp_tube_profile(a, mods, ctx) =
    __spp_profile_apply_mods(__spp_rev_tube_profile(a[0], a[1], a[2], a[3], a[4]),
        mods, __SPP_REV_LETTERS, ctx, 0);

// complete data of a tube
// returns [outer body points, hole cutter points, radius used for alignment, modified tagged profile,
//          body radius, [r1, r2, R1, R2, h] of the body]
function __spp_tube_spec(args, mods, flare_in_size, flare_in_align, ctx) =
    let(
        p0 = __spp_tube_profile(args, mods, ctx),
        nominal = max(args[2], args[3]),
        grow = __spp_max_x(p0) - nominal,
        shrink = flare_in_size && grow > 1e-9 ? grow : 0,
        _args = [args[0], args[1], args[2] - shrink, args[3] - shrink, args[4]]
    )
    assert(_args[2] > _args[0] && _args[3] > _args[1],
        str("[", ctx, "] flare_in_size: the flare is wider than the tube wall"))
    let(
        p = shrink > 0 ? __spp_tube_profile(_args, mods, ctx) : p0,
        body_r = nominal - shrink,
        full_r = max(body_r, __spp_max_x(p))
    )
    [__spp_rev_outer_body(p), __spp_rev_hole_cutter(p, args[4] + 1), flare_in_align ? full_r : body_r, p, body_r, _args];


// ------------------------------------------------------------------ revolvepp
//
// The user profile is a list of points [x, y], [x, y, "tag"] or [x, y, "tag", "f"]
// (x = radius >= 0, y = position along 'zet'). The segment from point i to point i+1
// is a face of the solid; its names are the automatic one (t, b, o, i, see below)
// plus the names of the tag of point i. A vertex is an edge named by both its faces.
//
// automatic names (outward normal n of the segment):
// - on the axis (x = 0 at both ends): not a face
// - horizontal, n up / down:           "t" / "b"
// - otherwise n away from / to the axis: "o" / "i"
// a tag must not use the letters x X y Y z Z (reserved for the parent frame); it may use
// t, b, o, i only to refine a face that already has that name (e.g. "t1" on a top face),
// adding a segment to another default group requires the flag "f" (forced)

__SPP_REVP_DEFAULT = "tboi";
__SPP_REVP_RESERVED = "xXyYzZ";
__SPP_REVP_EPS = 1e-9;

// signed area of a polygon (positive = counter-clockwise)
function __spp_signed_area(P) =
    let(n = len(P))
    0.5 * [for (i = [0:1:n-1]) cross(P[i], P[(i+1)%n])] * [for (i = [0:1:n-1]) 1];

// orientation of the triple, with tolerance relative to the size of the segments
function __spp_orient(a, b, c) =
    let(v = cross(b - a, c - a), tol = __SPP_REVP_EPS * (1 + norm(b - a)) * (1 + norm(c - a)))
    v > tol ? 1 : (v < -tol ? -1 : 0);

// true iff 'c' (collinear with a-b) lies on the segment a-b
function __spp_on_segment(a, b, c) =
    min(a[0], b[0]) - __SPP_REVP_EPS <= c[0] && c[0] <= max(a[0], b[0]) + __SPP_REVP_EPS &&
    min(a[1], b[1]) - __SPP_REVP_EPS <= c[1] && c[1] <= max(a[1], b[1]) + __SPP_REVP_EPS;

// true iff the segments p1-p2 and q1-q2 intersect (touching included)
function __spp_segments_intersect(p1, p2, q1, q2) =
    let(
        o1 = __spp_orient(p1, p2, q1), o2 = __spp_orient(p1, p2, q2),
        o3 = __spp_orient(q1, q2, p1), o4 = __spp_orient(q1, q2, p2)
    )
    (o1 * o2 < 0 && o3 * o4 < 0) ||
    (o1 == 0 && __spp_on_segment(p1, p2, q1)) ||
    (o2 == 0 && __spp_on_segment(p1, p2, q2)) ||
    (o3 == 0 && __spp_on_segment(q1, q2, p1)) ||
    (o4 == 0 && __spp_on_segment(q1, q2, p2));

// first pair [i, j] of intersecting segments of the closed polygon, undef if it is simple
// '-> adjacent segments may only share their common point (no folding back)
function __spp_first_self_intersection(P) =
    let(
        n = len(P),
        bad = [for (i = [0:1:n-1]) for (j = [i+1:1:n-1])
            let(adjacent = j == i+1 || (i == 0 && j == n-1))
            if (adjacent ?
                    // folding back: collinear and pointing in opposite directions
                    let(a = j == i+1 ? i : j, b = j == i+1 ? j : i,
                        u = P[(a+1)%n] - P[a], v = P[(b+1)%n] - P[b])
                    __spp_orient(P[a], P[(a+1)%n], P[(b+1)%n]) == 0 && u*v < 0 :
                    __spp_segments_intersect(P[i], P[(i+1)%n], P[j], P[(j+1)%n]))
                [i, j]]
    )
    len(bad) == 0 ? undef : bad[0];

// checks a user point and returns [x, y, names, forced]
function __spp_revp_point(p, k, ctx) =
    assert(is_list(p) && len(p) >= 2 && len(p) <= 4 && is_num(p[0]) && is_num(p[1]),
        str("[", ctx, "] point ", k, " must be [x, y], [x, y, \"tag\"] or [x, y, \"tag\", \"f\"], got ", p))
    assert(p[0] >= 0, str("[", ctx, "] point ", k, " has a negative radius (x = ", p[0], "), the profile ",
        "must lie in x >= 0 (x is the distance from the axis)"))
    assert(len(p) < 3 || !is_undef(__spp_face_names(p[2])),
        str("[", ctx, "] point ", k, ": invalid tag ", p[2], ", use face names (a letter optionally followed ",
            "by digits), e.g. \"g\", \"g1\", \"gh\""))
    assert(len(p) < 4 || p[3] == "f",
        str("[", ctx, "] point ", k, ": the fourth element must be \"f\" (force a default face name), got ", p[3]))
    let(names = len(p) >= 3 ? __spp_unique(__spp_face_names(p[2])) : [])
    assert(len([for (nm = names) if (__spp_char_in(nm[0], __SPP_REVP_RESERVED)) 1]) == 0,
        str("[", ctx, "] point ", k, ": tag \"", p[2], "\" uses a reserved letter (x X y Y z Z)"))
    [p[0], p[1], names, len(p) == 4];

// automatic face name of the segment a->b of a polygon with orientation 's' (+1 CCW, -1 CW)
// '-> undef for a segment on the axis
function __spp_revp_auto_name(a, b, s) =
    a[0] <= __SPP_REVP_EPS && b[0] <= __SPP_REVP_EPS ?
        undef :
        let(d = b - a, nrm = s * [d[1], -d[0]])
        abs(d[1]) <= __SPP_REVP_EPS * norm(d) ?
            (nrm[1] > 0 ? "t" : "b") :
            (nrm[0] > 0 ? "o" : "i");

// names of the segment k (auto name first, then the tag names), checks the tag
function __spp_revp_segment_names(auto, q, k, ctx) =
    let(
        defaults = [for (nm = q[2]) if (__spp_char_in(nm[0], __SPP_REVP_DEFAULT)) nm],
        added = [for (nm = defaults) if (is_undef(auto) || nm[0] != auto) nm]
    )
    assert(!is_undef(auto) || len(q[2]) == 0,
        str("[", ctx, "] point ", k, ": the segment from this point lies on the axis, it is not a face ",
            "and cannot be tagged"))
    assert(q[3] || len(added) == 0,
        str("[", ctx, "] point ", k, ": tag name(s) ", added, " would add the segment (automatic name \"", auto,
            "\") to a default group (t, b, o, i); if intended, force it with [x, y, \"", __spp_join(q[2], ""),
            "\", \"f\"]"))
    assert(!q[3] || len(added) > 0,
        str("[", ctx, "] point ", k, ": flag \"f\" given, but the tag adds the segment to no other default ",
            "group (t, b, o, i)"))
    __spp_unique(concat(is_undef(auto) ? [] : [auto], q[2]));

// canonical tag of a set of face names: default letters in the order t, b, o, i, then the others
function __spp_revp_tag(names) =
    let(
        u = __spp_unique(names),
        d = [for (c = ["t", "b", "o", "i"]) if (__spp_in_list(c, u)) c],
        rest = [for (nm = u) if (!__spp_in_list(nm, d)) nm]
    )
    __spp_join(concat(d, rest), "");

// validated, tagged and centered profile of revolvepp
// - 'keep' true keeps the y coordinates of the points (no centering)
// returns [tagged CCW profile (y centered), height, letters usable in selectors]
function __spp_revp_profile(points, ctx, keep=false) =
    assert(is_list(points) && len(points) >= 3,
        str("[", ctx, "] argument 'points' must be a list of at least 3 points, got ", points))
    let(
        n = len(points),
        Q = [for (k = [0:1:n-1]) __spp_revp_point(points[k], k, ctx)],
        P = [for (q = Q) [q[0], q[1]]],
        _dup = [for (k = [0:1:n-1])
            assert(norm(P[(k+1)%n] - P[k]) > __SPP_REVP_EPS,
                str("[", ctx, "] points ", k, " and ", (k+1)%n, " are equal (zero-length segment)"))
            0],
        isect = __spp_first_self_intersection(P)
    )
    assert(is_undef(isect),
        str("[", ctx, "] the profile intersects itself: segments starting at points ", isect[0], " and ", isect[1]))
    let(area = __spp_signed_area(P))
    assert(abs(area) > __SPP_REVP_EPS, str("[", ctx, "] the profile has zero area"))
    let(
        s = area > 0 ? 1 : -1,
        seg = [for (k = [0:1:n-1])
            __spp_revp_segment_names(__spp_revp_auto_name(P[k], P[(k+1)%n], s), Q[k], k, ctx)],
        // vertex k lies between the segments k-1 and k
        verts = [for (k = [0:1:n-1])
            let(
                A = P[(k+n-1)%n], V = P[k], B = P[(k+1)%n],
                on_axis = V[0] <= __SPP_REVP_EPS,
                straight = __spp_orient(A, V, B) == 0,
                names = concat(seg[(k+n-1)%n], seg[k])
            )
            on_axis || straight || len(names) == 0 ?
                [V[0], V[1], "_", false] :
                [V[0], V[1], __spp_revp_tag(names), true]],
        ccw = s > 0 ? verts : __spp_reverse(verts),
        ys = [for (p = P) p[1]],
        y0 = keep ? 0 : (min(ys) + max(ys)) / 2,
        letters = __spp_join(__spp_unique(concat(["t", "b", "o", "i"],
            [for (sn = seg) for (nm = sn) nm[0]])), "")
    )
    [[for (v = ccw) [v[0], v[1] - y0, v[2], v[3]]], max(ys) - min(ys), letters];

// complete data of revolvepp
// returns [profile points, radius used for alignment, modified tagged profile, body radius, height]
// - 'keep' true keeps the y coordinates of the points (align="keep")
function __spp_revp_spec(points, mods, flare_in_align, ctx, keep=false) =
    let(
        pr = __spp_revp_profile(points, ctx, keep),
        p0 = pr[0],
        body_r = __spp_max_x(p0)
    )
    assert(body_r > 0, str("[", ctx, "] the profile lies on the axis"))
    let(
        p = __spp_profile_apply_mods(p0, mods, pr[2], ctx, 0),
        full_r = max(body_r, __spp_max_x(p))
    )
    [__spp_profile_points(p), flare_in_align ? full_r : body_r, p, body_r, pr[1]];


// ------------------------------------------------------------------ toruspp

// parses the arguments of toruspp, returns [r, R, t, h] (inner radius, outer radius,
// radial width and height of the tube)
// - exactly two of 't', 'r|d', 'R|D' (none: r=0.5, R=1); 'h' defaults to 't'
function __spp_torus_args(t, r, d, R, D, h, ctx) =
    assert(is_undef(r) || is_undef(d), str("[", ctx, "] use either 'r' or 'd', not both"))
    assert(is_undef(R) || is_undef(D), str("[", ctx, "] use either 'R' or 'D', not both"))
    assert(is_undef(t) || is_num(t), str("[", ctx, "] argument 't' must be a number, got ", t))
    assert(is_undef(r) || is_num(r), str("[", ctx, "] argument 'r' must be a number, got ", r))
    assert(is_undef(d) || is_num(d), str("[", ctx, "] argument 'd' must be a number, got ", d))
    assert(is_undef(R) || is_num(R), str("[", ctx, "] argument 'R' must be a number, got ", R))
    assert(is_undef(D) || is_num(D), str("[", ctx, "] argument 'D' must be a number, got ", D))
    assert(is_undef(h) || is_num(h), str("[", ctx, "] argument 'h' must be a number, got ", h))
    let(
        _ri = !is_undef(d) ? d/2 : r,
        _Ro = !is_undef(D) ? D/2 : R,
        _n = (is_undef(_ri) ? 0 : 1) + (is_undef(_Ro) ? 0 : 1) + (is_undef(t) ? 0 : 1)
    )
    assert(_n == 0 || _n == 2,
        str("[", ctx, "] exactly two of 't', 'r|d', 'R|D' must be defined"))
    let(
        ri = _n == 0 ? 0.5 : (is_undef(_ri) ? _Ro - t : _ri),
        Ro = _n == 0 ? 1 : (is_undef(_Ro) ? _ri + t : _Ro),
        _t = Ro - ri,
        _h = is_undef(h) ? _t : h
    )
    assert(ri >= 0, str("[", ctx, "] inner radius must be non-negative, got ", ri))
    assert(_t > 0, str("[", ctx, "] outer radius ", Ro, " must be greater than the inner radius ", ri))
    assert(_h > 0, str("[", ctx, "] height must be positive, got ", _h))
    [ri, Ro, _t, _h];

// profile of a torus: ellipse with the semi-axes [t/2, h/2] centered at x = r + t/2
// '-> built on the circle of the larger semi-axis and scaled, so the vertices lie on the ellipse
//     and the number of fragments follows $fn/$fa/$fs as for circlepp
function __spp_torus_profile(r, t, h) =
    let(
        a = t/2,
        b = h/2,
        m = max(a, b),
        n = __spp_fragments(m)
    )
    [for (k = [0:1:n-1]) [r + a + a*cos(360*k/n), b*sin(360*k/n)]];
