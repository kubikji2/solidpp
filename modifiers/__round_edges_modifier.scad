include<../utils/vector_operations.scad>
include<../utils/solidpp_utils.scad>

__ROUND_EDGES_MOD_ID = "__ROUND_EDGES__";

// index to get the mask data
__ROUND_EDGES_MASKS_IDX = 1;

// index to get the bevel size data
__ROUND_EDGES_RADIUS_IDX = 2;

// check whether the 'modifier' is a valid 'round_edges' modifier
// '-> idx 0 - identifier
// '-> idx 1 - mask of bools 'xy', 'xz', 'yz'
// '-> idx 2 - rounding data [rx, ry, rz]
function __solidpp__is_valid_round_edges_modifier(modifier) = 
    is_list(modifier) &&
    len(modifier) == 3 &&
    modifier[0] == __ROUND_EDGES_MOD_ID &&
    is_list(modifier[1]) && len(modifier[1]) == 3 && 
    is_bool(modifier[1][0]) && is_bool(modifier[1][1]) && is_bool(modifier[1][0]) && 
    // '-> TODO make this as a module 
    is_vector_3D(modifier[2]);


// returns new copy of the modifier that compensate for the rounding
// '-> argument 'r' is the vector 3D describin rounding semi-axis
// WARNING: assume that argument 'round_edges_mod' is valid bevel bases mod
// WARNING: rely that argument 'r' is vector 3D
function __solidpp__round_edges__compensate_for_rounding(round_edges_mod, r) =
    [
        // id remains the same
        round_edges_mod[0],
        // mask remains the same
        round_edges_mod[1],
        // TODO compensate for this
        // '-> well, it might not be possible
        round_edges_mod[2]
    ];



// returns the 'round_edges' modifier is possible
// '-> otherwise return the [undef, <message>] standard modifier format
function __solidpp__new_round_edges(r=undef, d=undef, axes=undef) = 
    is_undef(r) && is_undef(d) ?
        [undef, "argument 'r'|'d' must be defined"] :
        !is_undef(r) && !is_undef(d) ?
            [undef, "only one argument 'r'|'d' can be defined at the time"] :
                !is_string(axes) ?
                    [undef, "argument 'axes' must be a string"] :
                    let(
                        axes_mask = __solidpp__axes_to_mask(axes), 
                        axes_cnt = vec_sum([for(b=axes_mask) b ? 1 : 0])
                    )
                    axes_cnt == 0 ?
                        [undef, "argument 'axes' must contain at least one axis"] :
                        (is_vector_2D(r) || is_vector_2D(d)) && axes_cnt != 2 ?
                            [undef, "argument 'r'|'d' can be vector 2D only for two axis defined in argument 'axes'"] :
                            axes_cnt == 2 && (is_vector_3D(r) || is_vector_3D(d)) ?
                                [undef, "argument 'r'|'d' as vector 3D makes no sense for two axes defined in 'axes'"] :
                                [
                                    __ROUND_EDGES_MOD_ID,
                                    __solidpp__plane_mask_from_axes(axes_mask, axes_cnt),
                                    // ,- this is basically vector scaling, but vector might contain undef,
                                    // v  so it is done separately 
                                    [
                                        for( el = __solidpp__expand_edge_modifier(
                                                        is_undef(r) ? d : r, axes_mask, axes_cnt))
                                            is_undef(el) ?
                                                undef :
                                                el*(is_undef(r) ? 0.5 : 1)
                                    ]
                                ];