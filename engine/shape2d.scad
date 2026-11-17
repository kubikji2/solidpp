// 2D shapes: corner modifiers of polygons (see DESIGN.md, section 6)
//
// - a 2D outline is a list of sides; side k runs from point k to point k+1 and has names
//   (squarepp: "y", "X", "Y", "x"; polygonpp: "s<k>" plus the names of a tag)
// - corner k lies between the sides k-1 and k and is named by both: "xY", "s0s1"
// - positive values: a token selects the corners whose sides include all its names (any order)
// - negative values (flares): the first name of a token is the base side, which is extended
//   beyond the corner; the other names select which of its two corners: "y" both corners of the
//   side y, "yX" only the one shared with X; a corner may get only one base side
// - concave corners are filled by positive values, flares need convex corners

include<profile.scad>


// ------------------------------------------------------------------ outline

// validated outline of polygonpp: returns [points CCW, names of the sides, letters, corner flags]
// - side k of the result keeps the number of the user's side (as in prismpp)
// - corner flags: false for points that are not corners (collinear with their neighbours)
function __spp_2d_base(points, ctx) =
    assert(is_list(points) && len(points) >= 3,
        str("[", ctx, "] argument 'points' must be a list of at least 3 points, got ", points))
    let(
        n = len(points),
        Q = [for (k = [0:1:n-1]) __spp_prism_point(points[k], k, ctx)],
        P = [for (q = Q) [q[0], q[1]]],
        _dup = [for (k = [0:1:n-1])
            assert(norm(P[(k+1)%n] - P[k]) > __SPP_REVP_EPS,
                str("[", ctx, "] points ", k, " and ", (k+1)%n, " are equal (zero-length side)"))
            0],
        isect = __spp_first_self_intersection(P)
    )
    assert(is_undef(isect),
        str("[", ctx, "] the outline intersects itself: sides ", isect[0], " and ", isect[1]))
    let(area = __spp_signed_area(P))
    assert(abs(area) > __SPP_REVP_EPS, str("[", ctx, "] the outline has zero area"))
    let(
        s = area > 0 ? 1 : -1,
        side = [for (k = [0:1:n-1]) concat([str("s", k)], Q[k][2])],
        pts = s > 0 ? P : [for (k = [n-1:-1:0]) P[k]],
        names = s > 0 ? side : [for (k = [n-1:-1:0]) side[(k+n-1)%n]],
        corner = [for (k = [0:1:n-1]) __spp_orient(pts[(k+n-1)%n], pts[k], pts[(k+1)%n]) != 0],
        letters = __spp_join(__spp_unique(concat(["s"], [for (q = Q) for (nm = q[2]) nm[0]])), "")
    )
    [pts, names, letters, corner];

// tagged profile of an outline: [x, y, tag, sharp], "_" for points that are not corners
// - 'tag_of' function(names of the two sides) -> tag
function __spp_2d_profile(pts, names, corner, tag_of) =
    let(n = len(pts))
    [for (k = [0:1:n-1])
        corner[k] ?
            [pts[k][0], pts[k][1], tag_of(concat(names[(k+n-1)%n], names[k])), true] :
            [pts[k][0], pts[k][1], "_", false]];


// ------------------------------------------------------------------ selection

// true iff the token face name 'tn' matches one of the names 'fns'
function __spp_2d_name_in(tn, fns) = len([for (fn = fns) if (__spp_name_matches(tn, fn)) 1]) > 0;

// per vertex of 'profile': undef (not selected), "" (selected) or "A"/"B" (base side of a flare)
// - 'sides' names of the side from vertex i to i+1 of the profile (__spp_2d_sides)
// - a corner is selectable if it is sharp and both its sides are original sides
function __spp_2d_select(tokens, neg, profile, sides, letters, mctx) =
    let(
        n = len(profile),
        // corner i: [names of the side before, names of the side after], undef if not selectable
        cs = [for (i = [0:1:n-1])
            profile[i][3] ? [sides[(i+n-1)%n], sides[i]] : undef],
        _tk = [for (tk = tokens)
            assert(tk == "all" || (!is_undef(__spp_face_names(tk)) && __spp_all_chars_in(__spp_letters(tk), letters)),
                str(mctx, ": invalid selector \"", tk, "\", use face names (letters of \"", letters,
                    "\", optionally followed by digits) or \"all\""))
            assert(!neg || tk != "all",
                str(mctx, ": a flare (negative value) needs a base side, name it first, e.g. \"y\" or \"yX\"; ",
                    "\"all\" has none"))
            0],
        // per token: list of [corner index, base]
        hits = [for (tk = tokens)
            let(
                tns = tk == "all" ? [] : __spp_face_names(tk),
                // positive values select by the corner tag (also the corners of an earlier bevel)
                tagged = [for (i = [0:1:n-1]) if (__spp_token_matches(tk, profile[i][2])) i],
                _done = assert(neg || len(tagged) == 0 || len([for (i = tagged) if (profile[i][3]) 1]) > 0,
                            str(mctx, ": corner(s) \"", profile[tagged[0]][2], "\" already rounded"))
                        0,
                h = !neg ?
                        [for (i = tagged) if (profile[i][3]) [i, ""]] :
                        let(rest = [for (j = [1:1:len(tns)-1]) tns[j]])
                        [for (i = [0:1:n-1])
                            if (!is_undef(cs[i]))
                                let(
                                    faces = concat(cs[i][0], cs[i][1]),
                                    rest_ok = len([for (tn = rest) if (!__spp_2d_name_in(tn, faces)) 1]) == 0,
                                    on_a = __spp_2d_name_in(tns[0], cs[i][0]),
                                    on_b = __spp_2d_name_in(tns[0], cs[i][1])
                                )
                                if (rest_ok && (on_a || on_b))
                                    [i, on_a && on_b ? "AB" : (on_a ? "A" : "B")]]
            )
            assert(len(h) > 0, str(mctx, ": selector \"", tk, "\" matches no corner (points collinear with ",
                "their neighbours are not corners)"))
            h],
        all_hits = [for (h = hits) each h],
        ops = [for (i = [0:1:n-1])
            let(b = __spp_unique([for (h = all_hits) if (h[0] == i) h[1]]))
            assert(len(b) <= 1 && (len(b) == 0 || b[0] != "AB"),
                str(mctx, ": corner \"", profile[i][2], "\" would be flared from both of its sides, ",
                    "select a single base side (the first name of a token)"))
            len(b) == 0 ? undef : b[0]]
    )
    ops;

// applies one modifier to a 2D outline profile
// - 'orig' [points CCW, names of the sides] of the original outline
// - 'metric' "projected" (axis-aligned sides, [x, y] values) or "along" (single numbers)
function __spp_2d_apply_mod(profile, mod, orig, letters, metric, ctx) =
    let(
        kind = mod[__SPP_EDGE_MOD_KIND_IDX],
        val = mod[__SPP_EDGE_MOD_VALUE_IDX],
        tokens = mod[__SPP_EDGE_MOD_WHERE_IDX],
        shown = val[0] == val[1] ? val[0] : val,
        mctx = str("[", ctx, "] ", kind, "(", shown, tokens == ["all"] ? "" : str(", where=", tokens), ")")
    )
    assert(metric == "projected" || val[0] == val[1],
        str(mctx, ": the value must be a single number (the sides have any direction)"))
    val[0] == 0 && val[1] == 0 ?
        profile :
        let(
            ops = __spp_2d_select(tokens, val[0] < 0, profile, __spp_2d_sides(profile, orig), letters, mctx),
            _check_sharp = [for (i = [0:1:len(profile)-1])
                assert(is_undef(ops[i]) || profile[i][3],
                    str(mctx, ": corner \"", profile[i][2], "\" is already rounded"))
                0]
        )
        __spp_profile_apply_ops(profile, kind, val, ops, mctx, undef, metric);

function __spp_2d_apply_mods(profile, mods, orig, letters, metric, ctx, idx=0) =
    idx >= len(mods) ?
        profile :
        __spp_2d_apply_mods(__spp_2d_apply_mod(profile, mods[idx], orig, letters, metric, ctx),
                            mods, orig, letters, metric, ctx, idx+1);

// names of the side from vertex i to vertex i+1 of a (modified) profile: the original side that
// contains the segment (both ends on its line, same direction), [] for a cut or an arc
// - 'orig' [points CCW, names of the sides] of the original outline
function __spp_2d_sides(profile, orig) =
    let(
        P = orig[0],
        m = len(P),
        lines = [for (k = [0:1:m-1])
            let(d = __spp_unit(P[(k+1)%m] - P[k]))
            [[d[1], -d[0]], [d[1], -d[0]]*P[k], d, 1e-7*(1 + norm(P[k]))]],
        n = len(profile)
    )
    [for (i = [0:1:n-1])
        let(
            a = __spp_xy(profile[i]),
            b = __spp_xy(profile[(i+1)%n]),
            on = [for (k = [0:1:m-1])
                let(L = lines[k])
                if (abs(L[0]*a - L[1]) <= L[3] && abs(L[0]*b - L[1]) <= L[3] && (b - a)*L[2] > 0) k]
        )
        len(on) == 0 ? [] : orig[1][on[0]]];

// checks the modifiers of a 2D shape: bevel() and rounding() only
// - 'values' description of the accepted values for the messages
function __spp_2d_mods(mod_list, ctx, values="a number or [dx, dy]") =
    let(l = is_undef(mod_list) ? [] : (is_list(mod_list) && !is_string(mod_list[0]) ? mod_list : [mod_list]))
    assert(len([for (m = l) if (__spp_is_legacy_mod(m)) 1]) == 0,
        str("[", ctx, "] old modifiers are not supported, use bevel() and rounding()"))
    assert(len([for (m = l) if (is_list(m) && m[0] == "__SPP_EDGE_MOD__" && is_list(m[2]) && len(m[2]) == 3) 1]) == 0,
        str("[", ctx, "] a 2D shape takes ", values, " as the value of bevel() and rounding()"))
    __spp_resolve_mod_list(mod_list, "revolved", ctx);
