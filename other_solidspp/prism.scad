include<../utils/solidpp_utils.scad>
include<../utils/vector_operations.scad>


// generate prism shell idx based on the total number of sides
function __spp__prism_shell_idx(n_sides) =
    [
        for (i=[0:n_sides-1])
        [
            n_sides + i,
            n_sides + (i+1) % n_sides,
            (i+1) % n_sides,
            i
        ]
    ];


// DEPRECATED: use prismpp(points, h) (a right prism over a convex base, with modifiers),
// linear_extrude for concave bases, multmatrix + linear_extrude for oblique prisms
// - argument 'points' is the base: 2D points (with 'h') or 3D points (with the normal 'n')
// - argument 'h' is the height of a right prism over 2D points
// - argument 'n' is the translation of the top base for 3D points (oblique prism)
// '-> still builds the old polyhedron, the echo shows the replacement call
module prism(points=undef, h=undef, n=undef)
{

    // module name
    __module_name = "PRISM";

    // process points
    _are_2D = __solidpp__check_list_of_vectors(points,2);
    _are_3D = __solidpp__check_list_of_vectors(points,3);

    _points = _are_3D ? 
                points :
                _are_2D ?
                    [ for (_p=points) [_p[0], _p[1], 0 ] ] :
                    is_undef(points) ?
                        [[0,0,0], [1,0,0], [0,1,0]] :
                        undef;
    // check points
    assert( !is_undef(_points),
            str("[",__module_name, "] argument 'points' must be list of 2D or 3D points, or reamins 'undef'!"));

    // check height
    assert( _are_2D == !is_undef(h),
            str("[", __module_name, "] when defining points as list of 2D points, argument 'h' must be defined"));
    assert( is_undef(h) || is_num(h),
            str("[", __module_name, "] argument 'h' must be a number!"));

    // check normal
    assert( _are_3D == !is_undef(n),
            str("[", __module_name, "] when defining points as list of 3D points, argument 'n' must be defined"));
    assert( is_undef(n) || is_vector_3D(n),
            str("[", __module_name, "] argument 'n' must be a vector 3D!") );
    
    // create normal
    _normal = !is_undef(h) ?
                [0,0,h] :
                !is_undef(n) ?
                    n :
                    [0,0,1];


    echo(str("[", __module_name, "] DEPRECATED: ",
             __spp_legacy_call("prism", ["points", points, "h", h, "n", n]),
             " -> use ", __spp_prism_replacement(_points, _normal)));

    // create vertices (points) for polyhedron
    _base_points = _points;
    _top_points = [ for (_point=_points) add_vecs(_point,_normal) ];
    _final_points = [for (_point=_base_points) _point, for (_point=_top_points) _point];

    // create facets for polyhedron
    _n_sides = len(_points);
    _shell_idxs = __spp__prism_shell_idx(_n_sides);
    // '-> create shell
    // ,-> join base, shell and top into the facet 
    _faces = [
                // base
                [for(i=[0:_n_sides-1]) i],
                // expanded shell
                each _shell_idxs,
                // top, but in inversed order
                [for(i=[0:_n_sides-1]) 2*_n_sides-i-1]
             ];

    // create geometry
    polyhedron(_final_points, _faces);

}

// __private__ text of the call replacing prism(points, h|n)
// - 'points' 3D points of the base, 'nv' translation of the top base
// '-> right prism, convex base: prismpp; right prism, concave base: linear_extrude;
//     oblique prism with a horizontal base: multmatrix (shear) + linear_extrude
function __spp_prism_replacement(points, nv) =
    let(
        z0 = points[0][2],
        flat = len([for (p = points) if (abs(p[2] - z0) > 1e-9) 1]) == 0,
        p2 = [for (p = points) [p[0], p[1]]],
        m = len(p2),
        orient = [for (k = [0:1:m-1]) __spp_orient(p2[(k+m-1)%m], p2[k], p2[(k+1)%m])],
        convex = len([for (o = orient) if (o > 0) 1]) == m || len([for (o = orient) if (o < 0) 1]) == m,
        right = abs(nv[0]) <= 1e-9 && abs(nv[1]) <= 1e-9,
        lift = abs(z0) <= 1e-9 ? "" : str("translate([0, 0, ", z0, "]) ")
    )
    !flat || nv[2] <= 0 ?
        "hull() of the base and its translated copy (no direct replacement for a non-horizontal base)" :
        right ?
            (convex ?
                str(lift, "prismpp(", p2, ", h=", nv[2], ")") :
                str(lift, "linear_extrude(height=", nv[2], ") polygon(", p2, ")")) :
            str(lift, "multmatrix([[1, 0, ", nv[0]/nv[2], ", 0], [0, 1, ", nv[1]/nv[2], ", 0], [0, 0, 1, 0]]) ",
                "linear_extrude(height=", nv[2], ") polygon(", p2, ")");
