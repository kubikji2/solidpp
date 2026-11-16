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
