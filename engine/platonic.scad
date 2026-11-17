// Platonic solids: data, modifiers and face/vertex frames (see DESIGN.md, section 5.5)
//
// - the solid is generated from its vertex coordinates; faces are the sets of vertices with the
//   largest dot product with the face normals (the vertex directions of the dual solid)
// - local frame: centered on the center of the solid, one face down (outward normal -z), one edge
//   of the bottom face parallel to x; 'zet' turns the local z like for every solidpp solid
// - modifiers are exact for these convex, symmetric solids (all edges/corners are equivalent):
//   - bevel(d):         cut by the planes of the edges (chamfer leg d along both faces)
//   - bevel_corners(d): cut by the planes of the vertices (cut at distance d along the edges)
//   - rounding(r):      Minkowski sum of the solid shrunk by r with a sphere (rounds every edge,
//                       including those of the cuts), must be the last modifier
//   the cut solid is the intersection of up to three convex bodies (planes of the faces, of the
//   edges, of the vertices), each built as a polyhedron

include<box.scad>
include<frame.scad>

__SPP_PLAT_N = [4, 6, 8, 12, 20];


// ------------------------------------------------------------------ helpers

// lexicographic quicksort of a list of lists (compares the elements in order)
function __spp_lex_less(a, b, i=0) =
    i >= len(a) ? false :
    a[i] < b[i] ? true :
    a[i] > b[i] ? false :
    __spp_lex_less(a, b, i+1);

function __spp_lex_sort(l) =
    len(l) <= 1 ? l :
    let(
        p = l[floor(len(l)/2)],
        lo = [for (x = l) if (__spp_lex_less(x, p)) x],
        eq = [for (x = l) if (!__spp_lex_less(x, p) && !__spp_lex_less(p, x)) x],
        hi = [for (x = l) if (__spp_lex_less(p, x)) x]
    )
    concat(__spp_lex_sort(lo), eq, __spp_lex_sort(hi));

function __spp_v3unit(v) = v / norm(v);

function __spp_v3mean(P) = [for (j = [0:2]) [for (p = P) p[j]] * [for (p = P) 1]] / len(P);

// rotation matrix (3x3) applied as M * v
function __spp_mat3_apply(M, v) = [M[0]*v, M[1]*v, M[2]*v];

// indices of 'points' on the supporting plane with the normal 'nrm', counter-clockwise when seen
// from outside (from the side 'nrm' points to)
function __spp_support_face(points, nrm, tol) =
    let(
        dots = [for (p = points) p*nrm],
        mx = max(dots),
        idx = [for (i = [0:1:len(points)-1]) if (dots[i] >= mx - tol) i],
        c = __spp_v3mean([for (i = idx) points[i]]),
        ex = __spp_v3unit(points[idx[0]] - c),
        ey = cross(nrm, ex),
        ang = [for (i = idx) let(q = points[i] - c) [atan2(q*ey, q*ex), i]]
    )
    [for (e = __spp_lex_sort(ang)) e[1]];

// convex polyhedron of the 'points' with the faces of the 'normals' (OpenSCAD order: clockwise
// seen from outside)
module __spp_convex_polyhedron(points, normals, tol)
{
    _faces = [for (nrm = normals) let(f = __spp_support_face(points, nrm, tol)) [for (k = [len(f)-1:-1:0]) f[k]]];
    polyhedron(points=points, faces=_faces);
}


// ------------------------------------------------------------------ data

// raw data [vertices, face normal directions] (any scale)
function __spp_plat_raw(n) =
    let(
        p = (1 + sqrt(5)) / 2,
        q = 1 / p,
        cube = [for (x = [-1, 1]) for (y = [-1, 1]) for (z = [-1, 1]) [x, y, z]],
        octa = [[1, 0, 0], [-1, 0, 0], [0, 1, 0], [0, -1, 0], [0, 0, 1], [0, 0, -1]],
        tetra = [[1, 1, 1], [1, -1, -1], [-1, 1, -1], [-1, -1, 1]],
        dodeca = concat(cube, [for (s = [-1, 1]) for (t = [-1, 1]) each [[0, s*q, t*p], [s*q, t*p, 0], [s*p, 0, t*q]]]),
        // the cyclic order matches the dodecahedron (its face normals are these directions)
        icosa = [for (s = [-1, 1]) for (t = [-1, 1]) each [[0, t*p, s], [t*p, s, 0], [s, 0, t*p]]]
    )
    n == 4  ? [tetra, -tetra] :
    n == 6  ? [cube, octa] :
    n == 8  ? [octa, cube] :
    n == 12 ? [dodeca, icosa] :
              [icosa, dodeca];

// metrics of the solid with the edge 1: [inradius, midradius, circumradius]
function __spp_plat_metrics(n) =
    let(
        raw = __spp_plat_raw(n),
        V = raw[0],
        e0 = min([for (i = [0:1:len(V)-1]) for (j = [i+1:1:len(V)-1]) norm(V[i] - V[j])]),
        nF = __spp_v3unit(raw[1][0]),
        hF = max([for (v = V) v*nF]) / e0,
        rc = norm(V[0]) / e0,
        rm = sqrt(rc*rc - 0.25)
    )
    [hF, rm, rc];

// parses the size arguments, returns the edge length
function __spp_plat_edge(n, a, d, D, ctx) =
    let(
        k = (is_undef(a) ? 0 : 1) + (is_undef(d) ? 0 : 1) + (is_undef(D) ? 0 : 1),
        m = __spp_plat_metrics(n)
    )
    assert(k <= 1, str("[", ctx, "] use only one of 'a' (edge), 'd' (inscribed sphere diameter), ",
        "'D' (circumscribed sphere diameter)"))
    assert(is_undef(a) || (is_num(a) && a > 0), str("[", ctx, "] argument 'a' must be a positive number, got ", a))
    assert(is_undef(d) || (is_num(d) && d > 0), str("[", ctx, "] argument 'd' must be a positive number, got ", d))
    assert(is_undef(D) || (is_num(D) && D > 0), str("[", ctx, "] argument 'D' must be a positive number, got ", D))
    !is_undef(a) ? a :
    !is_undef(d) ? d / (2*m[0]) :
    !is_undef(D) ? D / (2*m[2]) :
    1;

// complete data of the solid in the local frame, returns
// [0] vertices (local), [1] faces (internal vertex indices, CCW from outside),
// [2] face centers, [3] face normals, [4] edges [[i, j], ...], [5] metrics [inradius, midradius,
// circumradius, face apothem, edge] of this size, [6] nominal box [min, max],
// [7] vertex numbering (vertex index of number k), [8] face numbering "opposite",
// [9] face numbering "sequential"
function __spp_plat_spec(n, a, ctx) =
    assert(__spp_in_list(n, __SPP_PLAT_N), str("[", ctx, "] argument 'n' must be one of ", __SPP_PLAT_N, ", got ", n))
    let(
        raw = __spp_plat_raw(n),
        nv = len(raw[0]),
        e0 = min([for (i = [0:1:nv-1]) for (j = [i+1:1:nv-1]) norm(raw[0][i] - raw[0][j])]),
        V0 = [for (v = raw[0]) v * a / e0],
        tol = 1e-6 * a,
        N0 = [for (m = raw[1]) __spp_v3unit(m)],
        F0 = [for (m = N0) __spp_support_face(V0, m, tol)],
        // orientation: face 0 down, its first edge parallel to x
        ex = __spp_v3unit(V0[F0[0][1]] - V0[F0[0][0]]),
        ez = -N0[0],
        ey = cross(ez, ex),
        R = [ex, ey, ez],
        V = [for (v = V0) __spp_mat3_apply(R, v)],
        N = [for (m = N0) __spp_mat3_apply(R, m)],
        C = [for (f = F0) __spp_v3mean([for (i = f) V[i]])],
        E = [for (i = [0:1:nv-1]) for (j = [i+1:1:nv-1]) if (abs(norm(V[i] - V[j]) - a) <= tol) [i, j]],
        m = __spp_plat_metrics(n),
        apothem = norm(C[0] - (V[F0[0][0]] + V[F0[0][1]])/2),
        box = [[for (j = [0:2]) min([for (v = V) v[j]])], [for (j = [0:2]) max([for (v = V) v[j]])]],
        vnum = __spp_plat_geo_order(V, a),
        fgeo = __spp_plat_geo_order(C, a),
        fopp = __spp_plat_opposite_order(fgeo, N),
        adj = [for (f = [0:1:n-1]) [for (g = [0:1:n-1])
            if (g != f && len([for (i = F0[f]) if (__spp_in_list(i, F0[g])) 1]) == 2) g]],
        fseq = __spp_plat_sequence(adj, fgeo)
    )
    [V, F0, C, N, E, [m[0]*a, m[1]*a, m[2]*a, apothem, a], box, vnum, fopp, fseq];

// order of the points: from the top down (z), then counter-clockwise from +x
function __spp_plat_geo_order(P, a) =
    let(keys = [for (i = [0:1:len(P)-1])
        let(p = P[i], r = norm([p[0], p[1]]), ang = r <= 1e-9*a ? 0 : (atan2(p[1], p[0]) + 360) % 360)
        [-round(p[2] / a * 1e6), round(ang * 1e4), i]])
    [for (k = __spp_lex_sort(keys)) k[2]];

// numbering with face k opposite to face n-1-k (faces taken in the geometric order)
// '-> without opposite faces (tetrahedron) the geometric order
function __spp_plat_opposite_order(geo, N, i=0, out=undef) =
    let(n = len(geo), o = is_undef(out) ? [for (k = [0:1:n-1]) -1] : out)
    len([for (f = geo) if (len([for (g = geo) if (N[f]*N[g] <= -1 + 1e-9) 1]) == 0) 1]) > 0 ?
        geo :
        i >= n ?
            // o[k] holds the face of number k
            o :
            let(f = geo[i])
            __spp_in_list(f, o) ?
                __spp_plat_opposite_order(geo, N, i+1, o) :
                let(
                    k = len([for (x = o) if (x >= 0) 1]) / 2,
                    g = [for (h = geo) if (N[f]*N[h] <= -1 + 1e-9) h][0]
                )
                __spp_plat_opposite_order(geo, N, i+1,
                    [for (j = [0:1:n-1]) j == k ? f : (j == n-1-k ? g : o[j])]);

// numbering along a closed path over adjacent faces (consecutive numbers share an edge, the last
// face is adjacent to the first one), starting with the top face
// '-> depth-first search, neighbours with the fewest free neighbours first (Warnsdorff), then in
//     the geometric order
function __spp_plat_sequence(adj, geo) =
    let(
        rank = [for (f = [0:1:len(geo)-1]) [for (k = [0:1:len(geo)-1]) if (geo[k] == f) k][0]],
        cyc = __spp_plat_path(adj, rank, [geo[0]], true)
    )
    !is_undef(cyc) ? cyc : __spp_plat_path(adj, rank, [geo[0]], false);

function __spp_plat_path(adj, rank, path, cycle) =
    let(n = len(adj), last = path[len(path)-1])
    len(path) == n ?
        (!cycle || __spp_in_list(path[0], adj[last]) ? path : undef) :
        let(
            free = [for (g = adj[last]) if (!__spp_in_list(g, path)) g],
            keys = [for (g = free) [len([for (h = adj[g]) if (!__spp_in_list(h, path)) 1]), rank[g], g]],
            cands = [for (k = __spp_lex_sort(keys)) k[2]]
        )
        __spp_plat_try(adj, rank, path, cycle, cands, 0);

function __spp_plat_try(adj, rank, path, cycle, cands, i) =
    i >= len(cands) ?
        undef :
        let(r = __spp_plat_path(adj, rank, concat(path, [cands[i]]), cycle))
        is_undef(r) ? __spp_plat_try(adj, rank, path, cycle, cands, i+1) : r;


// ------------------------------------------------------------------ modifiers

// checks the modifiers, returns [bevel d or 0, corner d or 0, rounding r or 0]
function __spp_plat_mods(mod_list, spec, ctx) =
    let(
        _legacy = assert(is_undef(mod_list) || !is_list(mod_list) ||
                         len([for (m = mod_list) if (__spp_is_legacy_mod(m)) 1]) == 0,
                      str("[", ctx, "] old modifiers are not supported, use bevel(), rounding(), bevel_corners()"))
                  0,
        mods = __spp_resolve_mod_list(mod_list, "box", ctx),
        checked = [for (k = [0:1:len(mods)-1])
            let(
                md = mods[k],
                kind = md[1],
                v = md[2],
                shown = len([for (x = v) if (x != v[0]) 1]) == 0 ? v[0] : v,
                mctx = str("[", ctx, "] ", kind, "(", shown, md[3] == ["all"] ? "" : str(", where=", md[3]), ")")
            )
            assert(md[3] == ["all"],
                str(mctx, ": all edges and corners of a Platonic solid are equivalent, use where=\"all\""))
            assert(len([for (x = v) if (x != v[0]) 1]) == 0,
                str(mctx, ": the value must be a single number (the solid is symmetric)"))
            assert(v[0] >= 0, str(mctx, ": negative values (flares) are not supported by Platonic solids"))
            [kind, v[0], mctx]],
        active = [for (c = checked) if (c[1] > 0) c],
        kinds = [for (c = active) c[0]],
        nr = len([for (c = kinds) if (c == "rounding") 1]),
        nb = len([for (c = kinds) if (c == "bevel") 1]),
        nc = len([for (c = kinds) if (c == "bevel_corners") 1])
    )
    assert(nr <= 1 && nb <= 1 && nc <= 1,
        str("[", ctx, "] use each of bevel(), bevel_corners(), rounding() at most once"))
    assert(nr == 0 || kinds[len(kinds)-1] == "rounding",
        str("[", ctx, "] rounding() must be the last modifier (a rounded edge cannot be cut)"))
    let(
        b = nb == 0 ? 0 : [for (c = active) if (c[0] == "bevel") c[1]][0],
        cd = nc == 0 ? 0 : [for (c = active) if (c[0] == "bevel_corners") c[1]][0],
        r = nr == 0 ? 0 : [for (c = active) if (c[0] == "rounding") c[1]][0],
        apothem = spec[5][3],
        a = spec[5][4]
    )
    assert(b < apothem, str("[", ctx, "] bevel(", b, ") must be smaller than ", apothem,
        " (distance from the center of a face to its edge), otherwise the faces vanish"))
    assert(cd <= a/2, str("[", ctx, "] bevel_corners(", cd, ") must be at most ", a/2,
        " (half of the edge), otherwise the edges vanish"))
    let(h = __spp_plat_heights(spec, b, cd), hmin = min([for (x = h) if (!is_undef(x)) x]))
    assert(r < hmin, str("[", ctx, "] rounding(", r, ") must be smaller than ", hmin,
        " (radius of the sphere inscribed in the solid", b > 0 || cd > 0 ? " after the cuts" : "", ")"))
    [b, cd, r];

// distances of the planes of the faces, edges and vertices from the center:
// [face, edge (undef without bevel), vertex (undef without bevel_corners)]
function __spp_plat_heights(spec, b, cd) =
    let(
        V = spec[0], F = spec[1], C = spec[2], E = spec[4], met = spec[5],
        e = E[0],
        mid = (V[e[0]] + V[e[1]]) / 2,
        // a face containing the edge e
        f = [for (k = [0:1:len(F)-1]) if (__spp_in_list(e[0], F[k]) && __spp_in_list(e[1], F[k])) k][0],
        u = __spp_v3unit(C[f] - mid),
        hE = met[1] + b * (u * __spp_v3unit(mid)),
        w = V[e[1]] - V[e[0]],
        hV = met[2] + cd * (__spp_v3unit(w) * __spp_v3unit(V[e[0]]))
    )
    [met[0], b > 0 ? hE : undef, cd > 0 ? hV : undef];

// convex body bounded by planes with the 'normals' at the distance 'h', whose vertices lie on the
// 'dirs' (unit directions) at the distances 'ts'
module __spp_plat_body(dirs, ts, normals, tol)
{
    __spp_convex_polyhedron([for (k = [0:1:len(dirs)-1]) dirs[k]*ts[k]], normals, tol);
}

// the solid with its modifiers in the local frame
// - 'm' result of __spp_plat_mods
module __spp_plat_geometry(spec, m)
{
    V = spec[0]; F = spec[1]; C = spec[2]; N = spec[3]; E = spec[4]; met = spec[5];
    tol = 1e-6 * met[4];
    h = __spp_plat_heights(spec, m[0], m[1]);
    r = m[2];
    nV = [for (v = V) __spp_v3unit(v)];
    nE = [for (e = E) __spp_v3unit(V[e[0]] + V[e[1]])];
    // cosines: vertex-face (incident), edge-vertex (incident), edge-face (incident)
    cVF = met[0] / met[2];
    cEV = nE[0] * nV[E[0][0]];
    cEF = let(f = [for (k = [0:1:len(F)-1]) if (__spp_in_list(E[0][0], F[k]) && __spp_in_list(E[0][1], F[k])) k][0])
          nE[0] * N[f];

    if (is_undef(h[1]) && is_undef(h[2]))
    {
        if (r == 0)
            polyhedron(points=V, faces=[for (f = F) [for (k = [len(f)-1:-1:0]) f[k]]]);
        else
            hull()
                for (v = V)
                    translate(v * (h[0] - r) / h[0])
                        sphere(r);
    }
    else if (r == 0)
        __spp_plat_cut(V, N, nV, nE, h, cVF, cEV, cEF, tol);
    else
        minkowski()
        {
            __spp_plat_cut(V, N, nV, nE, [for (x = h) is_undef(x) ? undef : x - r], cVF, cEV, cEF, tol);
            sphere(r);
        }
}

// intersection of the bodies of the faces, edges (h[1]) and vertices (h[2])
module __spp_plat_cut(V, N, nV, nE, h, cVF, cEV, cEF, tol)
{
    intersection()
    {
        // faces: the solid scaled to the inradius h[0]
        __spp_plat_body(nV, [for (v = nV) h[0] / cVF], N, tol);
        // edges: vertices along the vertex and face directions
        if (!is_undef(h[1]))
            __spp_plat_body(concat(nV, N),
                            concat([for (v = nV) h[1] / cEV], [for (f = N) h[1] / cEF]), nE, tol);
        // vertices: the dual solid
        if (!is_undef(h[2]))
            __spp_plat_body(N, [for (f = N) h[2] / cVF], nV, tol);
    }
}


// ------------------------------------------------------------------ frames

// frame of a face/vertex, see __spp_frame (engine/frame.scad)
function __spp_plat_frame(o, nz) = __spp_frame(o, nz);

// checks 'idx' (undef, a number or a list of numbers in [0, n-1]), returns the list of numbers
function __spp_plat_idx(idx, n, what, ctx) =
    let(l = is_undef(idx) ? [for (k = [0:1:n-1]) k] : (is_num(idx) ? [idx] : idx))
    assert(is_list(l) && len([for (k = l) if (!is_num(k) || k != round(k) || k < 0 || k > n-1) 1]) == 0,
        str("[", ctx, "] argument 'idx' must be a ", what, " number or a list of them in [0, ", n-1, "], got ", idx))
    l;
