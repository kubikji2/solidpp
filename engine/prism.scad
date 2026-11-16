// Prism family: prismpp built from stacked cross-section rings (see DESIGN.md, section 5.4)
//
// The box engine generalized to a convex base with n sides:
// - local frame (u, v, w) as for cubepp, w being the 'zet' axis; the base polygon is given in (u, v)
// - faces: "t", "b" (bases), "s0" ... "s<n-1>" (side k runs from point k to point k+1),
//   plus the names of user tags of the sides
// - edges: vertical edge k (at point k) between sides k-1 and k, e.g. "s0s1";
//   base edges "ts<k>", "bs<k>"
// - stages A-C of mod_list as for cubepp (no bevel_corners)
// - the engine works relative to the centroid of the base, so the side distances are positive

include<box.scad>

__SPP_PRISM_DEFAULT = "tbs";
__SPP_PRISM_RESERVED = "tbsxXyYzZ";


// ------------------------------------------------------------------ base polygon

// checks a user point of the base and returns [u, v, user names]
function __spp_prism_point(p, k, ctx) =
    assert(is_list(p) && (len(p) == 2 || len(p) == 3) && is_num(p[0]) && is_num(p[1]),
        str("[", ctx, "] point ", k, " must be [x, y] or [x, y, \"tag\"], got ", p))
    assert(len(p) == 2 || !is_undef(__spp_face_names(p[2])),
        str("[", ctx, "] point ", k, ": invalid tag ", p[2], ", use face names (a letter optionally followed ",
            "by digits), e.g. \"g\", \"g1\", \"gh\""))
    let(names = len(p) == 3 ? __spp_unique(__spp_face_names(p[2])) : [])
    assert(len([for (nm = names) if (__spp_char_in(nm[0], __SPP_PRISM_RESERVED)) 1]) == 0,
        str("[", ctx, "] point ", k, ": tag \"", p[2], "\" uses a reserved letter (t b s x X y Y z Z); ",
            "the sides are named s0, s1, ... automatically"))
    [p[0], p[1], names];

// validated base: returns [points CCW, names of the sides, centroid, letters usable in selectors]
// - side k of the result runs from point k to point k+1 and keeps the number of the user's side
//   (user order is kept for counter-clockwise input; clockwise input is reversed, side k is then
//   the user's side k with the opposite direction)
function __spp_prism_base(points, ctx) =
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
        str("[", ctx, "] the base intersects itself: sides ", isect[0], " and ", isect[1]))
    let(
        area = __spp_signed_area(P),
        s = area > 0 ? 1 : -1,
        turns = [for (k = [0:1:n-1]) s * __spp_orient(P[(k+n-1)%n], P[k], P[(k+1)%n])],
        bad = [for (k = [0:1:n-1]) if (turns[k] <= 0) k]
    )
    assert(abs(area) > __SPP_REVP_EPS, str("[", ctx, "] the base has zero area"))
    assert(len(bad) == 0,
        str("[", ctx, "] the base must be strictly convex, point(s) ", bad,
            " are collinear with their neighbours or make the base concave"))
    let(
        // names of the user's side k (from point k to point k+1)
        side = [for (k = [0:1:n-1]) concat([str("s", k)], Q[k][2])],
        // counter-clockwise points and the names of their sides
        pts = s > 0 ? P : [for (k = [n-1:-1:0]) P[k]],
        names = s > 0 ? side : [for (k = [n-1:-1:0]) side[(k+n-1)%n]],
        c = __spp_polygon_centroid(pts),
        letters = __spp_join(__spp_unique(concat(["t", "b", "s"],
            [for (q = Q) for (nm = q[2]) nm[0]])), "")
    )
    [pts, names, c, letters];

// centroid of a polygon
function __spp_polygon_centroid(P) =
    let(
        n = len(P),
        a = __spp_signed_area(P),
        cs = [for (i = [0:1:n-1]) let(p = P[i], q = P[(i+1)%n]) (p + q) * cross(p, q)]
    )
    [for (j = [0:1]) [for (v = cs) v[j]] * [for (v = cs) 1]] / (6*a);

// canonical tag of a set of face names: t, b, then the sides by number, then the others
function __spp_prism_tag(names) =
    let(
        u = __spp_unique(names),
        tb = [for (c = ["t", "b"]) if (__spp_in_list(c, u)) c],
        sides = __spp_sort([for (nm = u) if (nm[0] == "s") __spp_parse_uint(nm, 1)]),
        rest = [for (nm = u) if (nm != "t" && nm != "b" && nm[0] != "s") nm]
    )
    __spp_join(concat(tb, [for (k = sides) str("s", k)], rest), "");

// unsigned integer from the digits of 's' starting at 'i'
function __spp_parse_uint(s, i, acc=0) =
    i >= len(s) ? acc : __spp_parse_uint(s, i+1, acc*10 + ord(s[i]) - 48);

// edges of the prism: list of [tag, kind, index]
// - kind "v": vertical edge at point 'index' (between the sides index-1 and index)
// - kind "t"/"b": top/bottom edge of side 'index'
function __spp_prism_edges(names) =
    let(n = len(names))
    concat(
        [for (k = [0:1:n-1]) [__spp_prism_tag(concat(names[(k+n-1)%n], names[k])), "v", k]],
        [for (k = [0:1:n-1]) [__spp_prism_tag(concat(["t"], names[k])), "t", k]],
        [for (k = [0:1:n-1]) [__spp_prism_tag(concat(["b"], names[k])), "b", k]]);


// ------------------------------------------------------------------ selectors

// true iff the edge 'e' (see __spp_prism_edges) is parallel to the parent axis 'a' (0, 1, 2)
// - 'pts' counter-clockwise base points
function __spp_prism_edge_parallel(e, a, pts, zet) =
    let(
        n = len(pts),
        d = e[1] == "v" ?
                [0, 0, 1] :
                let(q = pts[(e[2]+1)%n] - pts[e[2]]) [q[0], q[1], 0],
        dp = __spp_box_to_parent_position(d, zet),
        others = [for (j = [0:2]) if (j != a) abs(dp[j])]
    )
    max(others) <= 1e-9 * norm(dp);

// edges matched by the token 'tk'
function __spp_prism_token_edges(tk, edges, pts, letters, zet, ctx) =
    tk == "all" ?
        edges :
        len(tk) == 7 && (tk[0] == "x" || tk[0] == "y" || tk[0] == "z") && __spp_substr(tk, 1, 7) == "-edges" ?
            let(a = tk[0] == "x" ? 0 : (tk[0] == "y" ? 1 : 2))
            [for (e = edges) if (__spp_prism_edge_parallel(e, a, pts, zet)) e] :
            assert(!is_undef(__spp_face_names(tk)) && __spp_all_chars_in(__spp_letters(tk), letters),
                str(ctx, ": invalid selector \"", tk, "\", use face names (letters of \"", letters,
                    "\", optionally followed by digits, e.g. \"t\", \"s\", \"ts2\", \"s0s1\"), ",
                    "\"x-edges\", \"y-edges\", \"z-edges\" or \"all\""))
            [for (e = edges) if (__spp_token_matches(tk, e[0])) e];

// edges selected by the list of tokens, each token must match something
function __spp_prism_select(tokens, edges, pts, letters, zet, ctx) =
    let(
        per_token = [for (tk = tokens)
            let(m = __spp_prism_token_edges(tk, edges, pts, letters, zet, ctx))
            assert(len(m) > 0, str(ctx, ": selector \"", tk, "\" matches no edge"))
            m]
    )
    [for (e = edges) if (len([for (m = per_token) if (__spp_in_list(e, m)) 1]) > 0) e];


// ------------------------------------------------------------------ stages

// splits the modifiers into stages, returns [A, B, C] as __spp_box_stages
// - A: cross-section modifiers (2D engine, tags of the vertical edges)
// - B: list of n lists (one per side) of profile modifiers (tags "bo"/"to")
// - C: cut modifiers (2D engine, tags of the vertical edges)
function __spp_prism_stages(mods, edges, pts, letters, zet, ctx, idx=0, A=[], B=undef, C=[],
                            seen_base=false, seen_cut=false) =
    let(n = len(pts), _B0 = is_undef(B) ? [for (k = [0:1:n-1]) []] : B)
    idx >= len(mods) ?
        [A, _B0, C] :
        let(
            m = mods[idx],
            tokens = m[__SPP_EDGE_MOD_WHERE_IDX],
            kind = m[__SPP_EDGE_MOD_KIND_IDX],
            v = m[__SPP_EDGE_MOD_VALUE_IDX],
            mctx = str("[", ctx, "] ", kind, "(", v, ", where=", tokens, ")"),
            sel = __spp_prism_select(tokens, edges, pts, letters, zet, mctx),
            vert = [for (e = sel) if (e[1] == "v") e[0]],
            base = [for (e = sel) if (e[1] != "v") e],
            is_neg = v[0] < 0
        )
        assert(!is_neg || len(vert) == 0,
            str(mctx, ": negative values (flares) are allowed only on base edges (perpendicular to 'zet'), ",
                "the selection contains edges parallel to 'zet': ", vert))
        assert(len(base) == 0 || !seen_cut,
            str(mctx, ": a modifier of base edges cannot follow a cut of edges parallel to 'zet' ",
                "(a vertical-edge modifier placed after a base-edge modifier); reorder 'mod_list'"))
        let(
            vmod = len(vert) > 0 ? __spp_box_mod2d(kind, v, vert) : undef,
            _A = !is_undef(vmod) && !seen_base ? concat(A, [vmod]) : A,
            _C = !is_undef(vmod) && seen_base ? concat(C, [vmod]) : C,
            _seen_cut = seen_cut || (!is_undef(vmod) && seen_base),
            _B = [for (k = [0:1:n-1])
                let(tags = [
                    if (len([for (e = base) if (e[1] == "b" && e[2] == k) 1]) > 0) "bo",
                    if (len([for (e = base) if (e[1] == "t" && e[2] == k) 1]) > 0) "to"])
                len(tags) > 0 ? concat(_B0[k], [__spp_box_mod2d(kind, v, tags)]) : _B0[k]]
        )
        __spp_prism_stages(mods, edges, pts, letters, zet, ctx, idx+1, _A, _B, _C,
            seen_base || len(base) > 0, _seen_cut);


// ------------------------------------------------------------------ rings

// counter-clockwise angle from the direction 'a' to the direction 'b', in [0, 360)
function __spp_ccw_angle(a, b) = let(t = atan2(cross(a, b), a*b)) t < 0 ? t + 360 : t;

// weights of the side insets for an edge of the cross-section with the outward normal 'nr'
// - 'N' outward normals of the sides (counter-clockwise)
// - an edge parallel to side k takes its inset; an edge between the sides k-1 and k (a modified
//   corner) blends them: w_k = sin²θ / (sin²θ + sin²(φ-θ)), θ = angle from N[k-1], φ = angle of the
//   corner (cos² / sin² for the right angle of cubepp)
function __spp_prism_weights(nr, N) =
    let(
        n = len(N),
        same = [for (k = [0:1:n-1]) if (nr*N[k] >= 1 - 1e-9) k]
    )
    len(same) > 0 ?
        [for (k = [0:1:n-1]) k == same[0] ? 1 : 0] :
        let(
            br = [for (k = [0:1:n-1])
                let(phi = __spp_ccw_angle(N[(k+n-1)%n], N[k]), th = __spp_ccw_angle(N[(k+n-1)%n], nr))
                if (th < phi) [k, th, phi]],
            // a modified corner always lies between two sides; fall back to the closest side
            k = len(br) > 0 ? br[0][0] : undef,
            th = len(br) > 0 ? br[0][1] : 0,
            phi = len(br) > 0 ? br[0][2] : 1,
            a = pow(sin(th), 2),
            b = pow(sin(phi - th), 2),
            wk = a / (a + b),
            best = [for (j = [0:1:n-1]) if (nr*N[j] >= max([for (M = N) nr*M]) - 1e-12) j][0]
        )
        is_undef(k) ?
            [for (j = [0:1:n-1]) j == best ? 1 : 0] :
            [for (j = [0:1:n-1]) j == k ? wk : (j == (k+n-1)%n ? 1 - wk : 0)];

// complete data of a prism in the local frame (base centered on w = 0)
// returns [rings, is convex, [], local body box, local box with flares, flare range] as __spp_box_spec
// - 'base' result of __spp_prism_base, 'stages' result of __spp_prism_stages
function __spp_prism_spec(base, h, stages, ctx) =
    let(
        c = base[2],
        pts = [for (p = base[0]) p - c],
        n = len(pts),
        N = __spp_edge_normals(pts),
        W = [for (k = [0:1:n-1]) N[k]*pts[k]],
        tags = [for (e = __spp_prism_edges(base[1])) if (e[1] == "v") e[0]],
        // side profiles (x = distance of the side from the centroid)
        chains = [for (k = [0:1:n-1])
            let(
                sctx = str(ctx, "] [base edges of face ", __spp_prism_tag(base[1][k]), " (bo = bottom, to = top)"),
                p = __spp_profile_apply_mods(__spp_rev_cylinder_profile(W[k], W[k], h), stages[1][k],
                        __SPP_REV_LETTERS, sctx, 0)
            )
            [each __spp_rev_tag_points(p, "bo"), each __spp_rev_tag_points(p, "to")]],
        // cross-section (stage A)
        poly = [for (k = [0:1:n-1]) [pts[k][0], pts[k][1], tags[k], true]],
        section = __spp_profile_apply_mods(poly, stages[0], base[3], str(ctx, "] [edges parallel to 'zet'")),
        sec_pts = __spp_profile_points(section),
        weights = [for (nr = __spp_edge_normals(sec_pts)) __spp_prism_weights(nr, N)],
        // straight cuts (stage C)
        cut = __spp_profile_apply_mods(poly, stages[2], base[3], str(ctx, "] [cut of edges parallel to 'zet'")),
        cut_hps = let(m = len(cut))
            [for (i = [0:1:m-1])
                let(P = cut[i], Q = cut[(i+1)%m])
                if (P[2] == Q[2])
                    let(d = __spp_unit(__spp_xy(Q) - __spp_xy(P)), nr = [d[1], -d[0]])
                    [nr, nr*__spp_xy(P)]],
        // rings
        levels = __spp_unique_sorted(__spp_sort([for (ch = chains) each [for (p = ch) p[1]]])),
        tables = [for (ch = chains) [for (p = ch) [p[1], p[0]]]],
        g = [for (k = [0:1:n-1]) max(0, __spp_max_x(chains[k]) - W[k])],
        bound = 2*(max(W) + max(g) + 1) + 2*max([for (p = pts) norm(p)]),
        xs = [for (w = levels) [for (k = [0:1:n-1]) lookup(w, tables[k])]],
        rings = [for (j = [0:1:len(levels)-1])
            let(
                shifts = [for (wt = weights) wt*[for (k = [0:1:n-1]) W[k] - xs[j][k]]],
                ring = __spp_convex_offset(sec_pts, shifts, bound)
            )
            [levels[j], [for (p = __spp_clip_halfplanes(ring, cut_hps)) p + c]]],
        no_flare = [for (j = [0:1:len(levels)-1])
            if (len([for (k = [0:1:n-1]) if (xs[j][k] > W[k] + 1e-9) 1]) == 0) j],
        flare_range = len(no_flare) == 0 ? [len(levels)-1, 0] : [no_flare[0], no_flare[len(no_flare)-1]],
        is_convex = len(no_flare) == len(levels),
        all_pts = [for (r = rings) each r[1]],
        body_box = [[min([for (p = base[0]) p[0]]), min([for (p = base[0]) p[1]]), -h/2],
                    [max([for (p = base[0]) p[0]]), max([for (p = base[0]) p[1]]),  h/2]],
        full_box = [[min(body_box[0][0], min([for (p = all_pts) p[0]])), min(body_box[0][1], min([for (p = all_pts) p[1]])), -h/2],
                    [max(body_box[1][0], max([for (p = all_pts) p[0]])), max(body_box[1][1], max([for (p = all_pts) p[1]])),  h/2]]
    )
    [rings, is_convex, [], body_box, full_box, flare_range];
