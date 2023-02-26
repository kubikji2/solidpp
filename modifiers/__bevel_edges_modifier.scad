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
    len(modifier) == 2 &&
    modifier[0] == __BEVEL_EDGES_MOD_ID &&
    is_list(modifier[1]) && len(modifier[1]) == 3 && 
    is_bool(modifier[1][0]) && is_bool(modifier[1][1]) && is_bool(modifier[1][0]) && 
    // '-> TODO make this as a module 
    is_vector_3D(modifier[2]);

// returns the 'bevel_edges' modifier is possible
// '-> otherwise return the [undef, <message>] standard modifier format
function __solidpp__new_bevel_edges(bevel, axes) = 
    !is_num(bevel) && !is_vector_2D(bevel) && !is_vector_3D(bevel) ?
        [undef, "argument 'bevel' must be either number, vector 2D or vector 3D"] :
        (is_num(bevel) && bevel < 0) || !is_vector_positive(bevel) ?
            [undef, "argument 'bevel' cannot contain negative numbers"] :
            !is_string(axes) ?
                [undef, "argument 'axes' must be a string"] :
                let(
                    axes_mask = __solidpp__axes_to_mask(axes), 
                    axes_cnt = vec_sum([for(b=axes_mask) b ? 1 : 0])
                )
                axes_cnt == 0 ?
                    [undef, "argument 'axes' must contain at least one axis"] :
                    is_vector_2D(bevel) && axes_cnt != 2 ?
                        [undef, "argument 'bevel' can be vector 2D only for two axis defined in argument 'axes'"] :
                        axes_cnt == 2 && is_vector_3D(bevel) ?
                            [undef, "argument 'bevel' as vector 3D makes no sense for two axes defined in 'axes'"] :
                            [
                                __BEVEL_EDGES_MOD_ID,
                                __solidpp__plane_mask_from_axes(axes_mask, axes_cnt),
                                __solidpp__expand_edge_modifier(bevel, axes_mask, axes_cnt)
                            ];