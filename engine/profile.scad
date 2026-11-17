// Profile engine: tagged 2D polygons and corner operations
//
// A profile is a closed polygon (counter-clockwise) whose vertices carry edge tags:
//   vertex = [x, y, tag, sharp]
// - tag    edge name = names of its faces, e.g. "bo" (bottom outer), "tog1", see DESIGN.md
//          section 3.3; "_" marks a vertex that is not an edge (axis, collinear point)
// - sharp  true for real corners, false for arc points (cannot be modified again)
//
// Modifiers (see modifiers/edge_modifiers.scad) replace the sharp vertices of the
// selected edges by runs of new vertices that inherit the tag.
//
// Conventions used below:
// - 'A', 'V', 'B' are the previous vertex, the modified vertex, the next vertex (as [x,y])
// - every corner operation returns [points, [leg_A, leg_B]]
//   '-> 'points' replace 'V' and are ordered from 'A' to 'B'
//   '-> 'leg_A'/'leg_B' is the length of the A-V/V-B face consumed by the operation
// - in the profile of a revolved solid, x is the radius and y the axis

include<../modifiers/edge_modifiers.scad>

// ------------------------------------------------------------------ basics

// number of fragments of a circle with radius 'r', same formula as OpenSCAD
// '-> 'fn', 'fa', 'fs' default to $fn, $fa, $fs
function __spp_fragments(r, fn=undef, fa=undef, fs=undef) =
    let(
        _fn = is_undef(fn) ? $fn : fn,
        _fa = is_undef(fa) ? $fa : fa,
        _fs = is_undef(fs) ? $fs : fs
    )
    r < 0.00000095367431640625 ?
        3 :
        _fn > 0 ?
            (_fn >= 3 ? floor(_fn) : 3) :
            ceil(max(min(360/_fa, r*2*PI/_fs), 5));

// [x, y] of a vertex
function __spp_xy(v) = [v[0], v[1]];

// points of a profile (drops tags)
function __spp_profile_points(profile) = [for (v = profile) [v[0], v[1]]];

// maximal x of points or vertices
function __spp_max_x(points) = max([for (p = points) p[0]]);

// unit vector
function __spp_unit(v) =
    let(l = norm(v))
    assert(l > 0, "[SOLIDPP-PROFILE] zero-length face, cannot compute its direction")
    v / l;

// true iff the vertex 'V' of a counter-clockwise polygon is convex (A previous, B next vertex)
// '-> on a concave vertex, bevel and rounding fill the corner (add material)
function __spp_is_convex(A, V, B) = cross(V - A, B - V) > 0;

// true iff the direction 'u' is horizontal (lies in a base plane)
function __spp_is_horizontal(u) = abs(u[1]) <= 1e-9 * norm(u);

// true iff the char 'c' is in the string 's'
function __spp_char_in(c, s) =
    len([for (k = [0:1:len(s)-1]) if (s[k] == c) 1]) > 0;

// true iff all chars of the string 's' are in the string 'allowed'
function __spp_all_chars_in(s, allowed) =
    len([for (k = [0:1:len(s)-1]) if (!__spp_char_in(s[k], allowed)) 1]) == 0;

// true iff 'x' is in the list 'l'
function __spp_in_list(x, l) = len([for (y = l) if (y == x) 1]) > 0;

// unique elements of a list keeping the order
function __spp_unique(l) =
    [for (i = [0:1:len(l)-1]) if (len([for (j = [0:1:i-1]) if (l[j] == l[i]) 1]) == 0) l[i]];

// list in reverse order
function __spp_reverse(l) = [for (i = [len(l)-1:-1:0]) l[i]];

// removes consecutive duplicate vertices (cyclic)
function __spp_dedupe(profile, eps=1e-9) =
    let(n = len(profile))
    [for (i = [0:1:n-1])
        if (norm(__spp_xy(profile[i]) - __spp_xy(profile[(i+n-1)%n])) > eps)
            profile[i]];


// ------------------------------------------------------------------ face names (DESIGN.md 3.3)
//
// A face name is a letter optionally followed by digits: "t", "o", "g", "g12".
// An edge tag is the concatenation of the names of its faces: "to", "tog1".
// A selector token is a concatenation of face names; a bare letter matches its whole family
// ("g" matches "g", "g1", "g2", ...), a numbered name only itself.

function __spp_is_letter(c) =
    let(k = ord(c)) (k >= 65 && k <= 90) || (k >= 97 && k <= 122);

function __spp_is_digit(c) =
    let(k = ord(c)) k >= 48 && k <= 57;

// substring [a, b)
function __spp_substr(s, a, b) = b <= a ? "" : __spp_join([for (k = [a:1:b-1]) s[k]], "");

// face names of the string 's' ("tog1" -> ["t", "o", "g1"]), undef if 's' is not a valid name list
function __spp_face_names(s) =
    !is_string(s) || len(s) == 0 || !__spp_is_letter(s[0]) ?
        undef :
        len([for (k = [0:1:len(s)-1]) if (!__spp_is_letter(s[k]) && !__spp_is_digit(s[k])) 1]) > 0 ?
            undef :
            let(starts = [for (k = [0:1:len(s)-1]) if (__spp_is_letter(s[k])) k])
            [for (j = [0:1:len(starts)-1])
                __spp_substr(s, starts[j], j < len(starts)-1 ? starts[j+1] : len(s))];

// letters of the string 's' (digits dropped)
function __spp_letters(s) = __spp_join([for (k = [0:1:len(s)-1]) if (__spp_is_letter(s[k])) s[k]], "");

// true iff the token face name 'tn' matches the face name 'fn'
// '-> equal names, or a bare letter matching its family
function __spp_name_matches(tn, fn) = tn == fn || (len(tn) == 1 && fn[0] == tn);


// ------------------------------------------------------------------ edge selection

// true iff the selector token 'tk' selects the edge 'tag'
// '-> every face name of the token must match a face of the edge
function __spp_token_matches(tk, tag) =
    let(tns = __spp_face_names(tk), fns = __spp_face_names(tag))
    tk == "all" ||
    !is_undef(tns) && !is_undef(fns) &&
    len([for (tn = tns) if (len([for (fn = fns) if (__spp_name_matches(tn, fn)) 1]) == 0) 1]) == 0;

// tags of the profile that can be selected (valid names, all letters in 'letters')
// '-> vertices that are not edges (axis, collinear points) carry the tag "_"
function __spp_selectable_tags(profile, letters) =
    __spp_unique([for (v = profile)
        if (!is_undef(__spp_face_names(v[2])) && __spp_all_chars_in(__spp_letters(v[2]), letters)) v[2]]);

// resolves the 'tokens' to the list of selected tags, checks the tokens
function __spp_select_tags(tokens, selectable, letters, ctx) =
    let(
        _checks = [for (tk = tokens)
            assert(tk == "all" || (!is_undef(__spp_face_names(tk)) && __spp_all_chars_in(__spp_letters(tk), letters)),
                str(ctx, ": invalid selector \"", tk, "\", use face names (letters of \"", letters,
                    "\", optionally followed by digits) or \"all\""))
            assert(len([for (tag = selectable) if (__spp_token_matches(tk, tag)) 1]) > 0,
                str(ctx, ": selector \"", tk, "\" matches no edge, available edges are ", selectable))
            0]
    )
    [for (tag = selectable)
        if (len([for (tk = tokens) if (__spp_token_matches(tk, tag)) 1]) > 0)
            tag];


// ------------------------------------------------------------------ arcs

// arc tangent to two faces meeting at 'V'
// - 'u1', 'u2' are unit directions from 'V' along the faces
// - 'r' is the arc radius, 'frag_r' the radius used to compute the number of fragments
// returns [points from the tangent point on 'u1' to the one on 'u2', tangent distance]
// '-> collinear faces return [[V], 0]
function __spp_fillet_arc(V, u1, u2, r, frag_r) =
    let(theta = acos(max(-1, min(1, u1 * u2))))
    theta > 179.9999 ?
        [[V], 0] :
        assert(theta > 0.0001, "[SOLIDPP-PROFILE] cannot round a zero-angle corner")
        let(
            t = r / tan(theta/2),
            T1 = V + u1*t,
            T2 = V + u2*t,
            C = V + __spp_unit(u1 + u2) * (r / sin(theta/2)),
            a1 = atan2(T1[1]-C[1], T1[0]-C[0]),
            a2 = atan2(T2[1]-C[1], T2[0]-C[0]),
            d0 = a2 - a1,
            d = d0 > 180 ? d0 - 360 : (d0 < -180 ? d0 + 360 : d0),
            n = max(1, ceil(__spp_fragments(frag_r) * abs(d) / 360))
        )
        [   [   T1,
                for (k = [1:1:n-1]) C + r*[cos(a1 + d*k/n), sin(a1 + d*k/n)],
                T2
            ],
            t
        ];

// same as __spp_fillet_arc, but elliptical with semi-axes 'ab' = [a (x-axis), b (y-axis)]
// '-> computed as a circle of radius b in the plane scaled by b/a in the x-axis
function __spp_fillet_arc_elliptic(V, u1, u2, ab) =
    let(
        s = ab[1] / ab[0],
        Vs = [V[0]*s, V[1]],
        u1s = __spp_unit([u1[0]*s, u1[1]]),
        u2s = __spp_unit([u2[0]*s, u2[1]]),
        res = __spp_fillet_arc(Vs, u1s, u2s, ab[1], max(ab))
    )
    [for (p = res[0]) [p[0]/s, p[1]]];


// ------------------------------------------------------------------ corner operations

// length of the bevel leg on a face with unit direction 'u' (from the corner)
// '-> 'across' is projected to x, 'along' to y
function __spp_bevel_leg(u, val, is_across) =
    is_across ?
        assert(abs(u[0]) > 1e-9, "[SOLIDPP-PROFILE] cannot measure 'across' on a face parallel to the axis")
        val[0] / abs(u[0]) :
        assert(abs(u[1]) > 1e-9, "[SOLIDPP-PROFILE] cannot measure 'along' on a face in a base plane")
        val[1] / abs(u[1]);

// chamfer of a convex corner
// '-> of the two faces, the one closer to horizontal takes 'across', the other one 'along'
function __spp_corner_bevel(A, V, B, val) =
    let(
        uA = __spp_unit(A - V),
        uB = __spp_unit(B - V),
        a_is_across = abs(uA[0]) >= abs(uB[0]),
        lA = __spp_bevel_leg(uA, val, a_is_across),
        lB = __spp_bevel_leg(uB, val, !a_is_across)
    )
    [[V + uA*lA, V + uB*lB], [lA, lB]];

// rounding of a convex corner, 'val' = ellipse semi-axes [across, along]
function __spp_corner_round(A, V, B, val) =
    let(
        pts = __spp_fillet_arc_elliptic(V, __spp_unit(A - V), __spp_unit(B - V), val),
        lA = norm(pts[0] - V),
        lB = norm(pts[len(pts)-1] - V)
    )
    [pts, [lA, lB]];

// flare: material added in the corner between the base and the wall
// - 'kind' is "bevel" or "rounding", 'val' are the (positive) sizes [across, along]
// - 'base' "A" (the face towards A) or "B" is the face that is extended beyond 'V';
//   undef: the horizontal face (exactly one of the faces at 'V' must be horizontal)
// - 'metric' "projected": sizes measured along x/y (ellipse with the semi-axes 'val');
//   "along": sizes measured along the faces (circle of the radius val[0])
function __spp_corner_flare(kind, A, V, B, val, ctx, base=undef, metric="projected") =
    let(
        uA = __spp_unit(A - V),
        uB = __spp_unit(B - V),
        hA = __spp_is_horizontal(uA),
        hB = __spp_is_horizontal(uB)
    )
    assert(__spp_is_convex(A, V, B),
        str(ctx, ": a flare (negative value) needs a convex edge, use a positive value to fill a concave edge"))
    assert(!is_undef(base) || hA != hB,
        str(ctx, ": a flare (negative value) needs an unmodified base edge, ",
            "i.e. exactly one adjacent face in a base plane"))
    let(
        a_is_base = is_undef(base) ? hA : base == "A",
        // continuation of the base beyond 'V'
        ext = a_is_base ? -uA : -uB,
        // wall direction from 'V'
        wall = a_is_base ? uB : uA,
        // points ordered from the base to the wall
        pts = kind == "bevel" ?
                (metric == "along" ?
                    [V + ext*val[0], V + wall*val[1]] :
                    let(ext_h = abs(ext[0]) >= abs(wall[0]))
                    [V + ext*__spp_bevel_leg(ext, val, ext_h), V + wall*__spp_bevel_leg(wall, val, !ext_h)]) :
                (metric == "along" ?
                    __spp_fillet_arc(V, ext, wall, val[0], val[0])[0] :
                    __spp_fillet_arc_elliptic(V, ext, wall, val)),
        wall_leg = norm(pts[len(pts)-1] - V)
    )
    a_is_base ?
        [pts, [0, wall_leg]] :
        [__spp_reverse(pts), [wall_leg, 0]];

// chamfer of a corner with the legs measured along the faces ('val' = [leg on A, leg on B])
function __spp_corner_bevel_along(A, V, B, val) =
    let(uA = __spp_unit(A - V), uB = __spp_unit(B - V))
    [[V + uA*val[0], V + uB*val[1]], [val[0], val[1]]];

// circular rounding of a corner with the radius val[0]
function __spp_corner_round_along(A, V, B, val) =
    let(res = __spp_fillet_arc(V, __spp_unit(A - V), __spp_unit(B - V), val[0], val[0]))
    [res[0], [res[1], res[1]]];

// dispatches the corner operation
// - 'neg' true for flares, 'val' are positive sizes
// - 'base', 'metric' see __spp_corner_flare; "along" measures the legs along the faces (any
//   direction of the faces, circular rounding), "projected" along x/y (profiles, boxes)
function __spp_corner_op(kind, neg, A, V, B, val, ctx, base=undef, metric="projected") =
    let(
        _A = __spp_xy(A),
        _V = __spp_xy(V),
        _B = __spp_xy(B)
    )
    neg ?
        __spp_corner_flare(kind, _A, _V, _B, val, ctx, base, metric) :
        metric == "along" ?
            (kind == "bevel" ?
                __spp_corner_bevel_along(_A, _V, _B, val) :
                __spp_corner_round_along(_A, _V, _B, val)) :
            (kind == "bevel" ?
                __spp_corner_bevel(_A, _V, _B, val) :
                __spp_corner_round(_A, _V, _B, val));


// ------------------------------------------------------------------ applying modifiers

// applies a single edge modifier to the profile
// - 'letters' are the letters usable in selectors (e.g. "tboi")
// - 'metric' see __spp_corner_op
function __spp_profile_apply_mod(profile, mod, letters, ctx, min_x=undef, metric="projected") =
    let(
        kind = mod[__SPP_EDGE_MOD_KIND_IDX],
        val = mod[__SPP_EDGE_MOD_VALUE_IDX],
        tokens = mod[__SPP_EDGE_MOD_WHERE_IDX],
        mctx = str("[", ctx, "] ", __spp_mod_call(mod, val[0] == val[1] ? val[0] : val)),
        selectable = __spp_selectable_tags(profile, letters),
        sel = __spp_select_tags(tokens, selectable, letters, mctx)
    )
    val[0] == 0 && val[1] == 0 ?
        profile :
        let(
            _check_sharp = [for (tag = sel)
                assert(len([for (v = profile) if (v[2] == tag && v[3]) 1]) > 0,
                    str(mctx, ": edge \"", tag, "\" is already rounded"))
                0],
            // per vertex: undef (not selected) or "" (selected, flares on the horizontal face)
            ops = [for (v = profile) v[3] && __spp_in_list(v[2], sel) ? "" : undef]
        )
        __spp_profile_apply_ops(profile, kind, val, ops, mctx, min_x, metric);

// applies the corner operation of one modifier at the selected vertices
// - 'ops' per vertex: undef (not selected), "" (selected) or "A"/"B" (the base side of a flare)
// - 'val' signed sizes [across, along] ("along" metric: [leg, leg] or [r, r])
function __spp_profile_apply_ops(profile, kind, val, ops, mctx, min_x=undef, metric="projected") =
        let(
            n = len(profile),
            is_sel = [for (o = ops) !is_undef(o)],
            neg = val[0] < 0,
            aval = [abs(val[0]), abs(val[1])],
            res = [for (i = [0:1:n-1])
                is_sel[i] ?
                    __spp_corner_op(kind, neg,
                        profile[(i+n-1)%n], profile[i], profile[(i+1)%n],
                        aval, str(mctx, " at edge \"", profile[i][2], "\""),
                        ops[i] == "" ? undef : ops[i], metric) :
                    undef],
            // the corners at both ends of a face must not consume more than the face length
            _check_fit = [for (i = [0:1:n-1])
                let(
                    j = (i+1)%n,
                    L = norm(__spp_xy(profile[j]) - __spp_xy(profile[i])),
                    lo = is_sel[i] ? res[i][1][1] : 0,
                    li = is_sel[j] ? res[j][1][0] : 0
                )
                assert(lo + li <= L + 1e-9*(1 + L),
                    str(mctx, ": does not fit, edges \"", profile[i][2], "\" and \"", profile[j][2],
                        "\" need ", lo + li, " of the face between them, but it is only ", L, " long"))
                0],
            out = __spp_dedupe([for (i = [0:1:n-1])
                each (is_sel[i] ?
                    [for (q = res[i][0]) [q[0], q[1], profile[i][2], kind == "bevel"]] :
                    [profile[i]])]),
            _check_axis = [for (v = out)
                assert(is_undef(min_x) || v[0] >= min_x - 1e-9,
                    str(mctx, ": the result crosses the axis of revolution"))
                0]
        )
        out;

// applies the list of edge modifiers in reading order
function __spp_profile_apply_mods(profile, mods, letters, ctx, min_x=undef, idx=0, metric="projected") =
    idx >= len(mods) ?
        profile :
        __spp_profile_apply_mods(
            __spp_profile_apply_mod(profile, mods[idx], letters, ctx, min_x, metric),
            mods, letters, ctx, min_x, idx+1, metric);


// ------------------------------------------------------------------ polygonal walls

// scale applied to a revolved profile so that the polygon with 'n' sides
// has its corners ("corners", OpenSCAD default) or its flats ("flats", "polyhole") on the circle
function __spp_polygon_scale(mode, n, ctx) =
    assert(mode == "corners" || mode == "flats" || mode == "polyhole",
        str("[", ctx, "] polygon mode must be \"corners\", \"flats\" or \"polyhole\", got ", mode))
    mode == "corners" ? 1 : 1 / cos(180 / n);

// number of sides of a polyhole (nophead) of radius 'R': max(round(2*d), 3), d in mm
function __spp_polyhole_sides(R) = max(round(4*R), 3);

// number of sides of a wall: the polyhole count for "polyhole", otherwise 'fn'
// (undef means $fn/$fa/$fs)
// - 'R' nominal radius of the wall
function __spp_wall_sides(fn, mode, R, ctx) =
    mode == "polyhole" ?
        assert(is_undef(fn),
            str("[", ctx, "] polygon mode \"polyhole\" chooses the number of sides, do not set 'fn'"))
        __spp_polyhole_sides(R) :
        fn;

// checks the 'fn' argument (undef or integer >= 3)
function __spp_check_fn(fn, name, ctx) =
    assert(is_undef(fn) || (is_num(fn) && fn >= 3 && fn == floor(fn)),
        str("[", ctx, "] argument '", name, "' must be undef or an integer >= 3, got ", fn))
    fn;

// revolves 'points' (x = radius, y = axis) around the z-axis
// - 'fn' number of sides, undef uses $fn/$fa/$fs
// - 'polygon_mode' "corners" | "flats" | "polyhole"
// - 'sector' undef (full revolution) or [start, angle] in the local frame (degrees from +x,
//   counter-clockwise), see __spp_check_sector
// - 'nominal_r' nominal radius of the wall (number of sides of a polyhole)
// - 'convexity' passed to rotate_extrude (preview of non-convex profiles)
module __spp_revolve(points, fn, polygon_mode, ctx, sector=undef, nominal_r=undef, convexity=1)
{
    _fn = __spp_wall_sides(fn, polygon_mode, nominal_r, ctx);
    _n = is_undef(_fn) ? __spp_fragments(__spp_max_x(points)) : _fn;
    _k = __spp_polygon_scale(polygon_mode, _n, ctx);

    if (is_undef(sector))
        scale([_k, _k, 1])
            rotate_extrude(convexity=convexity, $fn = is_undef(_fn) ? $fn : _fn)
                polygon(points);
    else
        rotate([0, 0, sector[0]])
            scale([_k, _k, 1])
                rotate_extrude(angle=sector[1], convexity=convexity, $fn = is_undef(_fn) ? $fn : _fn)
                    polygon(points);
}
