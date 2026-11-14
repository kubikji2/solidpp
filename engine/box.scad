// Box family: cubepp built from stacked cross-section rings (see DESIGN.md, section 5)
//
// Local frame: the box is built centered in a local frame (u, v, w), w being the 'zet' axis,
// and then rotated by the 'zet' rotation. Local faces use the letters
//   x/X (u low/high), y/Y (v low/high), z/Z (w low/high = bottom/top)
// User selectors use the letters of the parent frame and 't'/'b'; they are mapped to
// local letters by the frame of the given 'zet'.
//
// Local names:
// - vertical edges (parallel to w): "xy", "Xy", "XY", "xY"     (u letter, v letter)
// - base edges:                     "zx", "zX", ..., "ZY"      (w letter, side letter)
// - corners:                        "zxy", ..., "ZXY"          (w, u, v letters)
//
// Stages of mod_list (in reading order, each modifier split into its vertical part first
// and then its base part):
// A) vertical part before any base part -> rounds/chamfers the corners of the cross-section,
//    the base modifiers then follow these corners (swept)
// B) base parts -> profile of each side face (same engine as the revolved solids),
//    giving the inset of the side at every height
// C) vertical part after a base part -> straight cut through the whole height
// D) bevel_corners -> plane cuts of the corners, applied last

include<revolved.scad>

__SPP_BOX_SIDES = ["x", "X", "y", "Y"];
__SPP_BOX_SIDE_NORMALS = [[-1, 0], [1, 0], [0, -1], [0, 1]];
__SPP_BOX_VERTICAL_EDGES = ["xy", "Xy", "XY", "xY"];
__SPP_BOX_BASE_EDGES = ["zx", "zX", "zy", "zY", "Zx", "ZX", "Zy", "ZY"];
__SPP_BOX_EDGES = concat(__SPP_BOX_VERTICAL_EDGES, __SPP_BOX_BASE_EDGES);
__SPP_BOX_CORNERS = ["zxy", "zXy", "zXY", "zxY", "Zxy", "ZXy", "ZXY", "ZxY"];
__SPP_BOX_AXES_LETTERS = ["xX", "yY", "zZ"];


// ------------------------------------------------------------------ frame

// for local axes u, v, w: [parent axis index, direction sign]
// '-> must match __solidpp__get_rotation_from_zet
function __spp_box_frame(zet) =
    zet == "x" || zet == "X" ?
        [[2, -1], [1, 1], [0, 1]] :
        zet == "y" || zet == "Y" ?
            [[0, 1], [2, -1], [1, 1]] :
            [[0, 1], [1, 1], [2, 1]];

// parent-frame letter of a local letter
function __spp_box_local_to_parent_letter(c, zet) =
    let(
        k = c == "x" || c == "X" ? 0 : (c == "y" || c == "Y" ? 1 : 2),
        is_high = c == "X" || c == "Y" || c == "Z",
        f = __spp_box_frame(zet)[k],
        high = f[1] > 0 ? is_high : !is_high
    )
    high ? ["X", "Y", "Z"][f[0]] : ["x", "y", "z"][f[0]];

// local letter of a parent-frame letter (or 't'/'b'), undef if invalid
function __spp_box_parent_to_local_letter(c, zet) =
    c == "t" ?
        "Z" :
        c == "b" ?
            "z" :
            let(cands = [for (l = ["x", "X", "y", "Y", "z", "Z"]) if (__spp_box_local_to_parent_letter(l, zet) == c) l])
            len(cands) == 1 ? cands[0] : undef;

// vector of the parent frame (extents) to the local frame
function __spp_box_to_local_extents(v, zet) =
    let(f = __spp_box_frame(zet))
    [v[f[0][0]], v[f[1][0]], v[f[2][0]]];

// vector of the local frame (extents) to the parent frame
function __spp_box_to_parent_extents(v, zet) =
    let(f = __spp_box_frame(zet))
    [for (j = [0:2]) v[[for (k = [0:2]) if (f[k][0] == j) k][0]]];

// position of the local frame to the parent frame
function __spp_box_to_parent_position(p, zet) =
    let(f = __spp_box_frame(zet))
    [for (j = [0:2]) let(k = [for (k = [0:2]) if (f[k][0] == j) k][0]) p[k] * f[k][1]];

// parent-frame name of a local name (used as tags, so that messages use the parent letters)
function __spp_box_parent_name(n, zet) =
    __spp_join([for (k = [0:1:len(n)-1]) __spp_box_local_to_parent_letter(n[k], zet)], "");

// value of a modifier as local extents [eu, ev, ew]
// '-> [across, along] is [across, across, along]
function __spp_box_local_value(v, zet) =
    len(v) == 2 ?
        [v[0], v[0], v[1]] :
        __spp_box_to_local_extents(v, zet);


// ------------------------------------------------------------------ selectors

// local names matched by the token 'tk' among 'names'
// - "all", "<a>-edges" (edges parallel to the parent axis a), or letters of the parent frame
//   and 't'/'b'; a token matches every name containing all its letters
function __spp_box_token_names(tk, names, zet, ctx) =
    tk == "all" ?
        names :
        len(tk) == 7 && (tk[0] == "x" || tk[0] == "y" || tk[0] == "z") &&
        tk[1] == "-" && tk[2] == "e" && tk[3] == "d" && tk[4] == "g" && tk[5] == "e" && tk[6] == "s" ?
            let(
                // local axis parallel to the parent axis tk[0]
                a = tk[0] == "x" ? 0 : (tk[0] == "y" ? 1 : 2),
                f = __spp_box_frame(zet),
                l = [for (k = [0:2]) if (f[k][0] == a) k][0],
                ls = __SPP_BOX_AXES_LETTERS[l]
            )
            [for (n = names)
                if (len(n) == 2 && !__spp_char_in(n[0], ls) && !__spp_char_in(n[1], ls)) n] :
            let(local = [for (k = [0:1:len(tk)-1]) __spp_box_parent_to_local_letter(tk[k], zet)])
            assert(len(tk) > 0 && len([for (c = local) if (is_undef(c)) 1]) == 0,
                str(ctx, ": invalid selector \"", tk, "\", use \"all\", \"x-edges\", \"y-edges\", \"z-edges\" ",
                    "or the letters x X y Y z Z t b"))
            [for (n = names) if (len([for (c = local) if (!__spp_char_in(c, n)) 1]) == 0) n];

// local names selected by the list of tokens, each token must match something
function __spp_box_select(tokens, names, zet, ctx) =
    let(
        per_token = [for (tk = tokens)
            let(m = __spp_box_token_names(tk, names, zet, ctx))
            assert(len(m) > 0, str(ctx, ": selector \"", tk, "\" matches nothing"))
            m]
    )
    [for (n = names) if (len([for (m = per_token) if (__spp_in_list(n, m)) 1]) > 0) n];


// ------------------------------------------------------------------ stages

// modifier record for the 2D profile engine
function __spp_box_mod2d(kind, val, tags) = [__SPP_EDGE_MOD_ID, kind, val, tags];

// splits the modifiers into stages
// returns [A, B, C, D]
// - A: cross-section modifiers (2D engine, tags of vertical edges)
// - B: list of 4 lists (sides x, X, y, Y) of profile modifiers (tags "bo"/"to")
// - C: cut modifiers (2D engine, tags of vertical edges)
// - D: list of [corner names, local extents]
function __spp_box_stages(mods, zet, ctx, idx=0, A=[], B=[[], [], [], []], C=[], D=[], seen_base=false, seen_cut=false) =
    idx >= len(mods) ?
        [A, B, C, D] :
        let(m = mods[idx], tokens = m[__SPP_EDGE_MOD_WHERE_IDX])
        __spp_is_corner_mod(m) ?
            let(
                mctx = str("[", ctx, "] bevel_corners(", m[2], ", where=", tokens, ")"),
                sel = __spp_box_select(tokens, __SPP_BOX_CORNERS, zet, mctx)
            )
            __spp_box_stages(mods, zet, ctx, idx+1, A, B, C,
                concat(D, [[sel, __spp_box_to_local_extents(m[2], zet)]]), seen_base, seen_cut) :
            let(
                kind = m[__SPP_EDGE_MOD_KIND_IDX],
                raw = m[__SPP_EDGE_MOD_VALUE_IDX],
                mctx = str("[", ctx, "] ", kind, "(", raw, ", where=", tokens, ")"),
                sel = __spp_box_select(tokens, __SPP_BOX_EDGES, zet, mctx),
                vert = [for (n = sel) if (__spp_in_list(n, __SPP_BOX_VERTICAL_EDGES)) n],
                base = [for (n = sel) if (__spp_in_list(n, __SPP_BOX_BASE_EDGES)) n],
                v = __spp_box_local_value(raw, zet),
                is_neg = v[0] < 0
            )
            assert(!is_neg || len(vert) == 0,
                str(mctx, ": negative values (flares) are allowed only on base edges (perpendicular to 'zet'), ",
                    "the selection contains edges parallel to 'zet': ",
                    [for (n = vert) __spp_box_parent_name(n, zet)]))
            assert(len(base) == 0 || !seen_cut,
                str(mctx, ": a modifier of base edges cannot follow a cut of edges parallel to 'zet' ",
                    "(a vertical-edge modifier placed after a base-edge modifier); reorder 'mod_list'"))
            let(
                vmod = len(vert) > 0 ?
                        __spp_box_mod2d(kind, [v[0], v[1]], [for (n = vert) __spp_box_parent_name(n, zet)]) :
                        undef,
                _A = !is_undef(vmod) && !seen_base ? concat(A, [vmod]) : A,
                _C = !is_undef(vmod) && seen_base ? concat(C, [vmod]) : C,
                _seen_cut = seen_cut || (!is_undef(vmod) && seen_base),
                _B = [for (i = [0:3])
                    let(
                        s = __SPP_BOX_SIDES[i],
                        tags = [if (__spp_in_list(str("z", s), base)) "bo", if (__spp_in_list(str("Z", s), base)) "to"],
                        side_v = i < 2 ? v[0] : v[1]
                    )
                    len(tags) > 0 ? concat(B[i], [__spp_box_mod2d(kind, [side_v, v[2]], tags)]) : B[i]]
            )
            __spp_box_stages(mods, zet, ctx, idx+1, _A, _B, _C, D, seen_base || len(base) > 0, _seen_cut);


// ------------------------------------------------------------------ 2D geometry helpers

// intersection of lines n1.p = c1 and n2.p = c2, undef if parallel
function __spp_line_isect(n1, c1, n2, c2) =
    let(det = n1[0]*n2[1] - n1[1]*n2[0])
    abs(det) < 1e-12 ?
        undef :
        [(c1*n2[1] - c2*n1[1]) / det, (n1[0]*c2 - n2[0]*c1) / det];

// clips a convex polygon by the half-plane n.p <= c
function __spp_clip_halfplane(poly, n, c, eps=1e-9) =
    let(m = len(poly))
    m == 0 ?
        [] :
        [for (i = [0:1:m-1])
            let(
                P = poly[i],
                Q = poly[(i+1)%m],
                dp = n*P - c,
                dq = n*Q - c
            )
            each (dp <= eps ?
                    (dq <= eps || dp >= -eps ? [P] : [P, P + (Q - P)*(dp/(dp - dq))]) :
                    (dq < -eps ? [P + (Q - P)*(dp/(dp - dq))] : []))];

// clips a convex polygon by the list of half-planes [[n, c], ...]
function __spp_clip_halfplanes(poly, hps, idx=0) =
    idx >= len(hps) ?
        poly :
        __spp_clip_halfplanes(__spp_clip_halfplane(poly, hps[idx][0], hps[idx][1]), hps, idx+1);

// outward normals of the edges of a convex counter-clockwise polygon
function __spp_edge_normals(pts) =
    let(n = len(pts))
    [for (i = [0:1:n-1]) let(d = __spp_unit(pts[(i+1)%n] - pts[i])) [d[1], -d[0]]];

// offsets every edge of a convex counter-clockwise polygon inward by 'shifts[i]'
// (negative is outward, corners are mitered)
function __spp_convex_offset(pts, shifts, bound) =
    let(
        n = len(pts),
        nr = __spp_edge_normals(pts),
        c = [for (i = [0:1:n-1]) nr[i]*pts[i] - shifts[i]],
        v = [for (i = [0:1:n-1]) __spp_line_isect(nr[(i+n-1)%n], c[(i+n-1)%n], nr[i], c[i])],
        // fast path is valid if no edge vanished or flipped
        ok = len([for (p = v) if (is_undef(p)) 1]) == 0 &&
             len([for (i = [0:1:n-1])
                    let(d = [-nr[i][1], nr[i][0]])
                    if ((v[(i+1)%n] - v[i])*d <= 1e-12) 1]) == 0
    )
    ok ?
        v :
        __spp_dedupe(__spp_clip_halfplanes(
            [[-bound, -bound], [bound, -bound], [bound, bound], [-bound, bound]],
            [for (i = [0:1:n-1]) [nr[i], c[i]]]));


// ------------------------------------------------------------------ numbers

function __spp_sort(l) =
    len(l) <= 1 ?
        l :
        let(p = l[floor(len(l)/2)])
        concat(__spp_sort([for (x = l) if (x < p) x]), [for (x = l) if (x == p) x], __spp_sort([for (x = l) if (x > p) x]));

function __spp_unique_sorted(l, eps=1e-9) =
    [for (i = [0:1:len(l)-1]) if (i == 0 || l[i] - l[i-1] > eps) l[i]];


// ------------------------------------------------------------------ box data

// side profiles: for each side the chain [[x, w], ...] (x = distance of the side from the center)
function __spp_box_side_chains(W, h, B, zet, ctx) =
    [for (i = [0:3])
        let(
            sctx = str(ctx, "] [base edges of face ", __spp_box_local_to_parent_letter(__SPP_BOX_SIDES[i], zet),
                       " (bo = bottom, to = top)"),
            p = __spp_profile_apply_mods(__spp_rev_cylinder_profile(W[i], W[i], h), B[i], __SPP_REV_LETTERS, sctx, 0)
        )
        [each __spp_rev_tag_points(p, "bo"), each __spp_rev_tag_points(p, "to")]];

// complete data of a box
// - 'size' local size, 'stages' from __spp_box_stages, 'zet' for messages
// returns [rings, is_convex, cutters, local bbox of the body, local bbox with flares, [ib, it]]
// - rings: [[w, [[u, v], ...]], ...] bottom to top
// - cutters: list of point lists (tetrahedra) to subtract
// - [ib, it]: rings ib..it have no flare (convex part), the rings below ib and above it
//   are in the flare zones
function __spp_box_spec(size, stages, flare_in_size, zet, ctx) =
    let(
        h = size[2],
        W0 = [size[0]/2, size[0]/2, size[1]/2, size[1]/2],
        chains0 = __spp_box_side_chains(W0, h, stages[1], zet, ctx),
        // flare extent of every side
        g = [for (i = [0:3]) max(0, __spp_max_x(chains0[i]) - W0[i])],
        W = flare_in_size ? [for (i = [0:3]) W0[i] - g[i]] : W0
    )
    assert(min(W) > 0, str("[", ctx, "] flare_in_size: the flares are wider than the box"))
    let(
        chains = flare_in_size ? __spp_box_side_chains(W, h, stages[1], zet, ctx) : chains0,
        // cross-section (stage A) on the rectangle [-Wx, WX] x [-Wy, WY]
        rect = [[-W[0], -W[2], __spp_box_parent_name("xy", zet), true],
                [ W[1], -W[2], __spp_box_parent_name("Xy", zet), true],
                [ W[1],  W[3], __spp_box_parent_name("XY", zet), true],
                [-W[0],  W[3], __spp_box_parent_name("xY", zet), true]],
        section = __spp_profile_apply_mods(rect, stages[0], "xXyYzZ", str(ctx, "] [edges parallel to 'zet'")),
        sec_pts = __spp_profile_points(section),
        sec_n = __spp_edge_normals(sec_pts),
        // weights of the side insets for every edge of the cross-section
        weights = [for (n = sec_n) [for (s = __SPP_BOX_SIDE_NORMALS) pow(max(0, n*s), 2)]],
        // straight cuts (stage C): edges inside the modified corners of the cut rectangle
        cut = __spp_profile_apply_mods(rect, stages[2], "xXyYzZ", str(ctx, "] [cut of edges parallel to 'zet'")),
        cut_hps = let(m = len(cut))
            [for (i = [0:1:m-1])
                let(P = cut[i], Q = cut[(i+1)%m])
                if (P[2] == Q[2])
                    let(d = __spp_unit(__spp_xy(Q) - __spp_xy(P)), nr = [d[1], -d[0]])
                    [nr, nr*__spp_xy(P)]],
        // ring levels
        levels = __spp_unique_sorted(__spp_sort([for (c = chains) each [for (p = c) p[1]]])),
        tables = [for (c = chains) [for (p = c) [p[1], p[0]]]],
        bound = 2*(max(W) + max(g) + 1),
        deltas = [for (w = levels) [for (i = [0:3]) W[i] - lookup(w, tables[i])]],
        rings = [for (k = [0:1:len(levels)-1])
            let(
                shifts = [for (wt = weights) wt*deltas[k]],
                ring = __spp_convex_offset(sec_pts, shifts, bound)
            )
            [levels[k], __spp_clip_halfplanes(ring, cut_hps)]],
        // rings without a flare
        no_flare = [for (k = [0:1:len(levels)-1]) if (min(deltas[k]) >= -1e-9) k],
        flare_range = len(no_flare) == 0 ? [len(levels)-1, 0] : [no_flare[0], no_flare[len(no_flare)-1]],
        is_convex = len([for (i = [0:3]) if (__spp_max_x(chains[i]) > W[i] + 1e-9) 1]) == 0,
        // corner cutters (stage D)
        cutters = [for (d = stages[3]) for (cn = d[0])
            let(
                e = d[1],
                s = [cn[1] == "X" ? 1 : -1, cn[2] == "Y" ? 1 : -1, cn[0] == "Z" ? 1 : -1],
                C = [s[0] > 0 ? W[1] : -W[0], s[1] > 0 ? W[3] : -W[2], s[2]*h/2],
                P1 = C - [s[0]*e[0], 0, 0],
                P2 = C - [0, s[1]*e[1], 0],
                P3 = C - [0, 0, s[2]*e[2]],
                G = (P1 + P2 + P3)/3
            )
            [P1, P2, P3, C + 2*(C - G)]],
        gmax = [for (i = [0:3]) max(0, __spp_max_x(chains[i]) - W[i])],
        body_box = [[-W[0], -W[2], -h/2], [W[1], W[3], h/2]],
        full_box = [[-W[0] - gmax[0], -W[2] - gmax[2], -h/2], [W[1] + gmax[1], W[3] + gmax[3], h/2]]
    )
    [rings, is_convex, cutters, body_box, full_box, flare_range];


// ------------------------------------------------------------------ geometry

// convex hull of the given rings [[w, points2D], ...]
module __spp_rings_hull(rings)
{
    _counts = [for (r = rings) len(r[1])];
    _starts = [for (i = [0:1:len(rings)-1]) __spp_sum_first(_counts, i)];
    _points = [for (r = rings) each [for (p = r[1]) [p[0], p[1], r[0]]]];
    _faces = [for (i = [0:1:len(rings)-1])
        if (_counts[i] > 0)
            let(f = [for (k = [0:1:_counts[i]-1]) _starts[i] + k])
            len(f) >= 3 ? f : [f[0], f[len(f)-1], f[0]]];

    hull()
        polyhedron(points=_points, faces=_faces);
}

// sum of the first 'n' elements of a list
function __spp_sum_first(l, n) = n <= 0 ? 0 : l[n-1] + __spp_sum_first(l, n-1);

// convex hull of a point cloud
module __spp_point_hull(points)
{
    hull()
        polyhedron(points=points, faces=[[0, 1, 2], [0, 1, 3], [0, 2, 3], [1, 2, 3]]);
}

// body of a box (without corner cuts) from the spec of __spp_box_spec
// '-> convex: one hull of all rings
// '-> with flares: one hull of the rings without a flare and hulls of adjacent rings
//     in the flare zones (fewer boolean operations)
module __spp_box_body(spec)
{
    _rings = spec[0];
    _n = len(_rings);
    _ib = spec[5][0];
    _it = spec[5][1];

    if (spec[1])
        __spp_rings_hull(_rings);
    else if (_ib >= _it)
        union()
            for (i = [0:1:_n-2])
                __spp_rings_hull([_rings[i], _rings[i+1]]);
    else
        union()
        {
            __spp_rings_hull([for (i = [_ib:1:_it]) _rings[i]]);
            for (i = [0:1:_ib-1])
                __spp_rings_hull([_rings[i], _rings[i+1]]);
            for (i = [_it:1:_n-2])
                __spp_rings_hull([_rings[i], _rings[i+1]]);
        }
}

// box in the local frame from the spec of __spp_box_spec
module __spp_box_geometry(spec)
{
    if (len(spec[2]) == 0)
        __spp_box_body(spec);
    else
        difference()
        {
            __spp_box_body(spec);
            for (c = spec[2])
                __spp_point_hull(c);
        }
}
