include<../utils/vector_operations.scad>
include<../utils/solidpp_utils.scad>

__BEVEL_EDGES_MOD_ID = "__BEVEL_EDGES__";

// index to get the mask data
__BEVEL_EDGES_MASKS_IDX = 1;

// index to get the bevel size data
__BEVEL_EDGES_BEVEL_IDX = 2;

// check whether the 'modifier' is a valid 'bevel_edges' modifier
// '-> idx 0 - identifier
// '-> idx 1 - mask of bools 'xy', 'xz', 'yz'
// '-> idx 2 - bevel data [x, y, z]
function __solidpp__is_valid_bevel_edges_modifier(modifier) = 
    is_list(modifier) &&
    len(modifier) == 3 &&
    modifier[0] == __BEVEL_EDGES_MOD_ID &&
    is_list(modifier[1]) && len(modifier[1]) == 3 && 
    is_bool(modifier[1][0]) && is_bool(modifier[1][1]) && is_bool(modifier[1][0]) && 
    // '-> TODO make this as a module 
    is_vector_3D(modifier[2]);

// returns new copy of the modifier that compensate for the rounding
// '-> argument 'r' is the vector 3D describin rounding semi-axis
// WARNING: assume that argument 'bevel_edges_mod' is valid bevel bases mod
// WARNING: rely that argument 'r' is vector 3D
function __solidpp__bevel_edges__compensate_for_rounding(bevel_edges_mod, r) =
    [
        // id remains the same
        bevel_edges_mod[0],
        // mask remains the same
        bevel_edges_mod[1],
        // TODO compute the precise numbers
        bevel_edges_mod[2],
    ];

// returns the 'bevel_edges' modifier is possible
// '-> otherwise return the [undef, <message>] standard modifier format
function __solidpp__new_bevel_edges(bevel, axes) = 
    !is_num(bevel) && !is_vector_2D(bevel) && !is_vector_3D(bevel) ?
        [undef, "argument 'bevel' must be either number, vector 2D or vector 3D"] :
        (is_num(bevel) && bevel < 0) || (!is_num(bevel) && !is_vector_positive(bevel)) ?
            [undef, "argument 'bevel' cannot contain negative numbers"] :
            !is_string(axes) ?
                [undef, "argument 'axes' must be a string"] :
                let(
                    axes_mask = __solidpp__axes_to_mask(axes), 
                    mask_cnt = vec_sum([for(b=axes_mask) b ? 1 : 0])
                )
                mask_cnt == 0 ?
                    [undef, "argument 'axes' must contain at least one axis"] :
                    is_vector_2D(bevel) && mask_cnt == 3 ?
                        [undef, "argument 'bevel' can be vector 2D only for two axis defined in argument 'axes'"] :
                        mask_cnt == 2 && is_vector_3D(bevel) ?
                            [undef, "argument 'bevel' as vector 3D makes no sense for two axes defined in 'axes'"] :
                            [
                                __BEVEL_EDGES_MOD_ID,
                                __solidpp__plane_mask_from_axes(axes_mask, mask_cnt),
                                __solidpp__expand_edge_modifier(bevel, axes_mask, mask_cnt)
                            ];