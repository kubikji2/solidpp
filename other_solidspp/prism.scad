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


// TODO decumentation

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
                    [ for (_p=_points) [_p[0], _p[1], 0 ] ] :
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
            str("[", __module_name, "] when defining points as list of 3D points, argument 'n' must be deifned"));
    assert( is_undef(n) || is_vector_3D(n),
            str("[", __module_name, "] argument 'n' must be a vector 3D!") );
    
    // create normal
    _normal = !is_undef(h) ?
                [0,0,h] :
                !is_undef(n) ?
                    n :
                    [0,0,1];


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