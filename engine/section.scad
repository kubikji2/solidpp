// Section engine: walls of revolved solids with a non-circular cross-section
//
// A wall with a section other than the plain circle is built along the 'zet' axis:
// - the nominal outline O (circle polygon or teardrop) at the nominal radius R
// - the wall chain [[x, z], ...] from the modified profile (bottom to top): every chain
//   point gives a ring, the outline offset by R - x (exact for circles and teardrops)
// - without serration the rings are hulled (convex parts) like the box rings
// - with serration the straight part of the wall [z_lo, z_hi] is a serrated prism
//   (one polyhedron) and the modified ends are plain rings; the pieces are united
//
// Pieces: ["hull", rings] | ["prism", [z_lo, points], [z_hi, points]]

include<box.scad>
include<../modifiers/section_modifiers.scad>


// ------------------------------------------------------------------ resolution

// resolves the 'section' argument to [teardrop, serration]
// - teardrop: undef or [angle, cap, up direction in the local frame]
// - serration: undef or [n, depth, profile, width]
// - 'def_up' default 'up' of a teardrop (undef: "x" for zet z, "Z" otherwise)
function __spp_resolve_section(section, zet, ctx, name, def_up=undef) =
    is_undef(section) ?
        [undef, undef] :
        let(l = __spp_is_section(section) ? [section] : section)
        assert(is_list(l) && len(l) > 0 && len([for (s = l) if (!__spp_is_section(s)) 1]) == 0,
            str("[", ctx, "] argument '", name, "' must be teardrop(), serration() or a list of them, got ", section))
        let(
            tds = [for (s = l) if (s[1] == "teardrop") s],
            srs = [for (s = l) if (s[1] == "serration") s]
        )
        assert(len(tds) <= 1, str("[", ctx, "] argument '", name, "' can contain only one teardrop()"))
        assert(len(srs) <= 1, str("[", ctx, "] argument '", name, "' can contain only one serration()"))
        assert(len(tds) == 0 || l[0][1] == "teardrop",
            str("[", ctx, "] argument '", name, "': the base shape teardrop() must be the first item"))
        let(
            td = len(tds) == 0 ?
                    undef :
                    let(
                        t = tds[0],
                        up = !is_undef(t[2]) ? t[2] : !is_undef(def_up) ? def_up : (zet == "z" || zet == "Z" ? "x" : "Z"),
                        loc = __spp_box_parent_to_local_letter(up, zet)
                    )
                    assert(!is_undef(loc) && loc != "z" && loc != "Z",
                        str("[", ctx, "] teardrop: 'up' must be a face letter perpendicular to 'zet' (\"",
                            zet, "\"), got ", up))
                    [t[3], t[4], loc == "x" ? [-1, 0] : (loc == "X" ? [1, 0] : (loc == "y" ? [0, -1] : [0, 1]))],
            sr = len(srs) == 0 ? undef : [srs[0][2], srs[0][3], srs[0][4], srs[0][5]]
        )
        [td, sr];

// true iff the resolved section is the plain circle
function __spp_is_plain_section(sec) = is_undef(sec[0]) && is_undef(sec[1]);


// ------------------------------------------------------------------ outlines

function __spp_rotate2d(p, a) = [p[0]*cos(a) - p[1]*sin(a), p[0]*sin(a) + p[1]*cos(a)];

// removes consecutive duplicate points (cyclic)
function __spp_dedupe_points(pts, eps) =
    let(n = len(pts))
    [for (i = [0:1:n-1]) if (norm(pts[i] - pts[(i+n-1)%n]) > eps) pts[i]];

// circle polygon with vertices on the circle, vertex 0 at +x (as circle())
function __spp_circle_outline(r, n) = [for (k = [0:1:n-1]) r*[cos(360*k/n), sin(360*k/n)]];

// teardrop outline (counter-clockwise)
// - 'angle' of the tip faces from the horizontal, 'cap' "point" | "bridge"
// - 'up' unit direction of the tip in the local frame
function __spp_teardrop_outline(r, n, angle, cap, up) =
    let(
        // polar angle of the right tangent point (tip pointing to +y)
        al = 90 - angle,
        a = r / sin(al),
        TL = r*[cos(180 - al), sin(180 - al)],
        TR = r*[cos(al), sin(al)],
        // circle vertices below the tangent points, counter-clockwise from TL to TR
        arc = concat(
            [for (k = [0:1:n-1]) let(t = 360*k/n) if (t > 180 - al + 1e-6) r*[cos(t), sin(t)]],
            [for (k = [0:1:n-1]) let(t = 360*k/n) if (t < al - 1e-6) r*[cos(t), sin(t)]]),
        tip = cap == "point" ?
                [[0, a]] :
                let(xb = (a - r)*tan(al)) [[xb, r], [-xb, r]],
        pts = concat([TL], arc, [TR], tip),
        rot = atan2(up[1], up[0]) - 90
    )
    __spp_dedupe_points([for (p = pts) __spp_rotate2d(p, rot)], r*1e-6);

// nominal outline of a section with radius 'R' and 'n' circle fragments
function __spp_section_outline(R, n, td, polygon_mode, ctx) =
    is_undef(td) ?
        let(k = __spp_polygon_scale(polygon_mode, n, ctx))
        [for (p = __spp_circle_outline(R, n)) k*p] :
        assert(polygon_mode == "corners",
            str("[", ctx, "] teardrop() works only with the polygon mode \"corners\", got ", polygon_mode))
        __spp_teardrop_outline(R, n, td[0], td[1], td[2]);

// ring of the outline 'O' (nominal radius 'R') for the wall at radius 'x'
function __spp_section_ring(O, R, x, bound) =
    x <= 1e-9 ?
        [[0, 0]] :
        __spp_convex_offset(O, [for (p = O) R - x], bound);


// ------------------------------------------------------------------ serration

// cumulative lengths of the edges of a closed polygon [0, l0, l0+l1, ..., L]
function __spp_cumulative_lengths(P) =
    let(
        m = len(P),
        lens = [for (i = [0:1:m-1]) norm(P[(i+1)%m] - P[i])]
    )
    [for (i = [0:1:m]) __spp_sum_first(lens, i)];

// [edge index, fraction] of the arc-length position 's' (taken modulo the perimeter)
function __spp_locate(cum, s) =
    let(
        L = cum[len(cum)-1],
        ss = s - L*floor(s/L),
        e = max([for (i = [0:1:len(cum)-2]) if (cum[i] <= ss + 1e-12) i]),
        le = cum[e+1] - cum[e]
    )
    [e, le > 0 ? min(1, (ss - cum[e]) / le) : 0];

function __spp_sort_by_first(l) =
    len(l) <= 1 ?
        l :
        let(p = l[floor(len(l)/2)][0])
        concat(__spp_sort_by_first([for (x = l) if (x[0] < p) x]),
               [for (x = l) if (x[0] == p) x],
               __spp_sort_by_first([for (x = l) if (x[0] > p) x]));

// plan of the serrated outline, computed on the nominal outline 'O' (radius 'R') and applicable
// to every ring with the same vertices (offsets of 'O'); items:
// - ["on", e, f]        point on the outline
// - ["in", e, f]        point moved inward by the depth (root of a triangle)
// - ["v", i]            vertex of the outline
// - ["arc", e_s, f_s, e_e, f_e, m]   interior points of a round groove between two points
// '-> circle: the grooves are spread over the whole perimeter, starting at vertex 0
// '-> teardrop: the grooves are spread over the circular part only (from the left tangent point,
//     vertex 0, around the bottom to the right tangent point); the tip faces and the cap stay
//     plain, they do not touch the rod and grooves there would spoil the printable overhang
function __spp_serration_plan(O, sr, td, R, ctx) =
    let(
        n = sr[0],
        depth = sr[1],
        cum = __spp_cumulative_lengths(O),
        L = cum[len(cum)-1],
        closed = is_undef(td),
        // last vertex on the circle (right tangent point of a teardrop)
        i_end = closed ? len(O) : max([for (i = [0:1:len(O)-1]) if (abs(norm(O[i]) - R) <= 1e-6*R) i]),
        span = closed ? L : cum[i_end],
        P = span / n,
        // vertices of the outline after the circular part (tip faces and cap of a teardrop)
        tail = closed ? [] : [for (i = [i_end+1:1:len(O)-1]) ["v", i]]
    )
    sr[2] == "triangle" ?
        concat(
            [for (k = [0:1:n-1]) each [
                concat(["on"], __spp_locate(cum, k*P)),
                concat(["in"], __spp_locate(cum, (k + 0.5)*P))]],
            closed ? [] : [concat(["on"], __spp_locate(cum, span))],
            tail) :
        let(
            w = is_undef(sr[3]) ? 2*depth : sr[3],
            rho = (w*w/4 + depth*depth) / (2*depth),
            phi = acos((rho - depth) / rho),
            m = max(2, ceil(__spp_fragments(rho) * 2*phi / 360)),
            u = [for (i = [0:1:len(O)-1]) cum[i]]
        )
        assert(w < P - 1e-9,
            str("[", ctx, "] serration: ", n, " round grooves of width ", w,
                " do not fit on the ", closed ? "perimeter " : "circular part of the teardrop ", span,
                " (at most ", P, " each)"))
        concat(
            [for (k = [0:1:n-1])
                let(
                    lo = (k - 0.5)*P + w/2,
                    hi = (k + 0.5)*P - w/2,
                    // vertices between the previous groove and this one
                    between = closed ?
                        __spp_sort_by_first([for (i = [0:1:len(O)-1])
                            let(v = u[i] > lo + 1e-9 && u[i] < hi - 1e-9 ? u[i] : u[i] - L)
                            if (v > lo + 1e-9 && v < hi - 1e-9) [v, i]]) :
                        [for (i = [0:1:i_end]) if ((k == 0 ? u[i] >= -1e-9 : u[i] > lo + 1e-9) && u[i] < hi - 1e-9) [u[i], i]],
                    st = __spp_locate(cum, hi),
                    en = __spp_locate(cum, hi + w)
                )
                each concat(
                    [for (b = between) ["v", b[1]]],
                    [concat(["on"], st), concat(["arc"], st, en, [m]), concat(["on"], en)])],
            // rest of the circular part after the last groove
            closed ? [] : [for (i = [0:1:i_end]) if (u[i] > (n - 0.5)*P + w/2 + 1e-9) ["v", i]],
            tail);

// point at [e, f] of a ring and the inward normal of the edge e
function __spp_ring_point(R, e, f) = R[e] + (R[(e+1)%len(R)] - R[e])*f;
function __spp_ring_inward(R, e) = let(d = __spp_unit(R[(e+1)%len(R)] - R[e])) [-d[1], d[0]];

// serrated outline of a ring from the plan
function __spp_serrate(R, plan, sr) =
    let(depth = sr[1])
    [for (it = plan)
        each (
            it[0] == "on" ?
                [__spp_ring_point(R, it[1], it[2])] :
            it[0] == "in" ?
                [__spp_ring_point(R, it[1], it[2]) + __spp_ring_inward(R, it[1])*depth] :
            it[0] == "v" ?
                [R[it[1]]] :
                // round groove: arc through S and E with the given depth
                let(
                    S = __spp_ring_point(R, it[1], it[2]),
                    E = __spp_ring_point(R, it[3], it[4]),
                    m = it[5],
                    ch = E - S,
                    wl = norm(ch),
                    nrm = [-ch[1], ch[0]] / wl,
                    rho = (wl*wl/4 + depth*depth) / (2*depth),
                    C = (S + E)/2 + nrm*(depth - rho),
                    ar = atan2(nrm[1], nrm[0]),
                    phi = acos(max(-1, min(1, (rho - depth) / rho))),
                    a_s = atan2(S[1] - C[1], S[0] - C[0]),
                    das = a_s - ar - 360*round((a_s - ar)/360),
                    sg = das >= 0 ? 1 : -1
                )
                [for (t = [1:1:m-1]) let(a = ar + sg*phi*(1 - 2*t/m)) C + rho*[cos(a), sin(a)]]
        )];


// ------------------------------------------------------------------ pieces

// hull pieces of rings: the rings without a flare (delta >= 0) form one convex hull,
// the others are hulled by pairs
function __spp_hull_pieces(rings, deltas) =
    let(
        n = len(rings),
        ok = [for (k = [0:1:n-1]) if (deltas[k] >= -1e-9) k],
        ib = len(ok) == 0 ? n : ok[0],
        it = len(ok) == 0 ? -1 : ok[len(ok)-1]
    )
    n < 2 ?
        [] :
        ib >= it ?
            [for (i = [0:1:n-2]) ["hull", [rings[i], rings[i+1]]]] :
            concat(
                [for (i = [0:1:ib-1]) ["hull", [rings[i], rings[i+1]]]],
                [["hull", [for (i = [ib:1:it]) rings[i]]]],
                [for (i = [it:1:n-2]) ["hull", [rings[i], rings[i+1]]]]);

// pieces of a wall
// - 'chain' [[x, z], ...] bottom to top, 'region' [z_lo, z_hi] straight part of the wall
// - 'line' [[x1, z1], [x2, z2]] original wall line: chain points outside of it are flares
// - 'R' nominal radius, 'sec' resolved section, 'fn' sides, 'polygon_mode' circle mode
function __spp_section_pieces(chain, region, line, R, sec, fn, polygon_mode, ctx) =
    let(
        _fn = __spp_wall_sides(fn, polygon_mode, R, ctx),
        n = is_undef(_fn) ? __spp_fragments(R) : _fn,
        O = __spp_section_outline(R, n, sec[0], polygon_mode, ctx),
        bound = 4*(R + max([for (p = chain) abs(p[0])]) + 1),
        sr = sec[1],
        ring = function(x) __spp_section_ring(O, R, x, bound),
        // distance of a chain point inside the wall line (negative: flare, the outline grows)
        inside = function(p) line[0][0] + (line[1][0] - line[0][0])*(p[1] - line[0][1])/(line[1][1] - line[0][1]) - p[0]
    )
    is_undef(sr) ?
        __spp_hull_pieces([for (p = chain) [p[1], ring(p[0])]], [for (p = chain) inside(p)]) :
        let(
            zlo = is_undef(region) ? 0 : region[0],
            zhi = is_undef(region) ? 0 : region[1],
            table = [for (p = chain) [p[1], p[0]]],
            bottom = [for (p = chain) if (p[1] <= zlo + 1e-9) p],
            top = [for (p = chain) if (p[1] >= zhi - 1e-9) p],
            rlo = ring(lookup(zlo, table)),
            rhi = ring(lookup(zhi, table))
        )
        assert(!is_undef(region),
            str("[", ctx, "] serration needs a straight part of the wall, the modifiers of the bases leave none"))
        assert(len(rlo) == len(O) && len(rhi) == len(O),
            str("[", ctx, "] serration needs a non-zero radius along the straight part of the wall"))
        let(
            plan = __spp_serration_plan(O, sr, sec[0], R, ctx),
            slo = __spp_serrate(rlo, plan, sr),
            shi = __spp_serrate(rhi, plan, sr)
        )
        assert(sr[1] < 0.5*min([for (p = rlo) norm(p)]),
            str("[", ctx, "] serration: the depth ", sr[1], " is too large for the radius of the wall"))
        concat(
            __spp_hull_pieces([for (p = bottom) [p[1], ring(p[0])]], [for (p = bottom) inside(p)]),
            [["prism", [zlo, slo], [zhi, shi]]],
            __spp_hull_pieces([for (p = top) [p[1], ring(p[0])]], [for (p = top) inside(p)]));


// ------------------------------------------------------------------ walls of revolved solids

// [z_lo, z_hi] of the straight part of a wall between the points 'P' and 'Q' of the chain,
// undef if there is none: both points must lie on the original wall line A-B
function __spp_straight_region(P, Q, A, B) =
    let(
        d = B - A,
        on_line = function(X) abs(cross(d, X - A)) <= 1e-6*(1 + norm(d))*(1 + norm(X - A))
    )
    Q[1] - P[1] > 1e-9 && on_line(P) && on_line(Q) ? [P[1], Q[1]] : undef;

// outer wall chain of a cylinder or a tube: [chain, [z_lo, z_hi] or undef, wall line]
// - 'R1', 'R2' are the radii of the body (the original wall line)
// '-> a zero radius base (cone apex) is the point on the axis
function __spp_rev_outer_chain(profile, h, R1, R2) =
    let(
        bo = __spp_rev_tag_points(profile, "bo"),
        to = __spp_rev_tag_points(profile, "to"),
        b = len(bo) == 0 ? [[0, -h/2]] : bo,
        t = len(to) == 0 ? [[0, h/2]] : to
    )
    [concat(b, t), __spp_straight_region(b[len(b)-1], t[0], [R1, -h/2], [R2, h/2]), [[R1, -h/2], [R2, h/2]]];

// protrusion of the hole cut-out beyond the faces of a tube: small, and short enough that the
// continued wall line of a conical hole keeps at least half of its radius
function __spp_rev_inner_protrusion(r1, r2, h) =
    let(s = abs(r2 - r1) / h)
    s > 0 ? min(1, 0.5*min(r1, r2)/s) : 1;

// hole chain of a tube (bottom to top) protruding by 'e': [chain, [z_lo, z_hi] or undef, wall line]
// - 'r1', 'r2' are the radii of the hole (the original wall line)
// '-> beyond an unmodified end the protrusion continues the wall line, so the straight part
//     runs through it; beyond a modified end the protrusion is parallel to the axis
function __spp_rev_inner_chain(profile, h, e, r1, r2) =
    let(
        ti = __spp_rev_tag_points(profile, "ti"),
        bi = __spp_rev_tag_points(profile, "bi"),
        up = __spp_reverse(concat(ti, bi)),
        f = up[0],
        l = up[len(up)-1],
        slope = (r2 - r1) / h,
        fb = len(bi) == 1 ? [f[0] - slope*e, f[1] - e] : [f[0], f[1] - e],
        lt = len(ti) == 1 ? [l[0] + slope*e, l[1] + e] : [l[0], l[1] + e],
        P = len(bi) == 1 ? fb : bi[0],
        Q = len(ti) == 1 ? lt : ti[len(ti)-1]
    )
    assert(fb[0] > 0 && lt[0] > 0, "[TUBEPP] the hole is too conical for its protrusion")
    [concat([fb], up, [lt]), __spp_straight_region(P, Q, [r1, -h/2], [r2, h/2]), [[r1, -h/2], [r2, h/2]]];


// ------------------------------------------------------------------ geometry

module __spp_prism(lo, hi)
{
    _k = len(lo[1]);
    _points = concat([for (q = lo[1]) [q[0], q[1], lo[0]]], [for (q = hi[1]) [q[0], q[1], hi[0]]]);
    _faces = concat(
        [[for (i = [0:1:_k-1]) i]],
        [[for (i = [_k-1:-1:0]) _k + i]],
        [for (i = [0:1:_k-1]) let(j = (i+1)%_k) each [[i, _k + i, _k + j], [i, _k + j, j]]]);

    polyhedron(points=_points, faces=_faces, convexity=10);
}

module __spp_section_piece(piece)
{
    if (piece[0] == "hull")
        __spp_rings_hull(piece[1]);
    else
        __spp_prism(piece[1], piece[2]);
}

// wall from its pieces
module __spp_section_geometry(pieces)
{
    if (len(pieces) == 1)
        __spp_section_piece(pieces[0]);
    else
        union()
            for (p = pieces)
                __spp_section_piece(p);
}
