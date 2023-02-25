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
    modifier[0] == __BEVEL_EDGES__ &&
    is_list(modifier[1]) && len(modifier[1]) == 3 && 
    is_bool(modifier[1][0]) && is_bool(modifier[1][1]) && is_bool(modifier[1][0]) && 
    // '-> TODO make this as a module 
    is_vector_3D(modifier[2]);

// __private__ function to compose mask for the bevel edges
// '-> idx 0 - are edges of sides with normal in 'xy'-plane beveled ?
// '-> idx 1 - are edges of sides with normal in 'xz'-plane beveled ?
// '-> idx 2 - are edges of sides with normal in 'yz'-plane beveled ?
function __spp__bevel_edgges__mask_from_axes(axes_mask, axes_cnt) =
    axes_cnt == 3 ?
        [true, true, true] :
        axes_cnt == 2 ?
            [
                axes_mask.x && axes_mask.y,
                axes_mask.x && axes_mask.z,
                axes_mask.y && axes_mask.z
            ] :
            axes_cnt == 1 ?
                [!axes_mask.z, !axes_mask.y, !axes_mask.x] :
                [false, false, false];

// __private__ function to compose the bevel as vecotr 3D
function __spp__bevel_edgess__expand_bevel(bevel, axes_mask) =
    is_num(bevel) ?
        [bevel, bevel, bevel] :
        is_vector_3D(bevel) ?
            bevel :
            axes_mask.x && axes_mask.y ?
                [bevel[0], bevel[1], undef] :
                axes_mask.x && axes_mask.z ?
                    [bevel[0], undef, bevel[1]] :
                    [undef, bevel[0], bevel[1]];

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
                echo(axes_cnt)
                echo(axes_mask)
                axes_cnt == 0 ?
                    [undef, "argument 'axes' must contain at least one axis"] :
                    is_vector_2D(bevel) && axes_cnt != 2 ?
                        [undef, "argument 'bevel' can be vector 2D only for two axis defined in argument 'axes'"] :
                        axes_cnt == 2 && is_vector_3D(bevel) ?
                            [undef, "argument 'bevel' as vector 3D makes no sense for two axes defined in 'axes'"] :
                            [
                                __BEVEL_EDGES_MOD_ID,
                                __spp__bevel_edgges__mask_from_axes(axes_mask, axes_cnt),
                                __spp__bevel_edgess__expand_bevel(bevel, axes_mask)
                            ];