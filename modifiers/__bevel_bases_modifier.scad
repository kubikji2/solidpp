include<../utils/vector_operations.scad>

__BEVEL_BASES_MOD_ID = "__BEVEL_BASES__";

// check whether the 'modifier' is a valid 'bevel_bases' modifier
function __solidpp__is_valid_bevel_bases_modifier(modifier) = 
    is_list(modifier) &&
    len(modifier) == 4 &&
    modifier[0] == __BEVEL_CORNERS_MOD_ID &&
    is_string(modifier[1]) &&
    is_vector_3D(modifier[2]) &&
    is_vector_3D(modifier[3]);


// returns the 'bevel_corners' modifier if possible
// '-> otherwise return the [undef, <message>] standard modifier format
// '-> expected format is:
//     '-> "__BEVEL_BASES__"
//     '-> argument 'axis' as a string
//     '-> argument 'bevel_bottom' as vector3D
//     '-> argument 'bevel_top' as vector3D
function __solidpp__new_bevel_bases(bevel=undef, axis="z", bevel_bottom=undef, bevel_top=undef) = 
    is_undef(bevel) && (is_undef(bevel_bottom) || is_undef(bevel_top)) ?
        [undef, "argument 'bevel' or both 'bevel_bottom' and 'bevel_top' must be defined"] :
        !is_string(axis) ?
            [undef, "argument 'axis' must be string"] :
            !is_undef(bevel) ?
                is_num(bevel) ?
                    bevel <= 0 ?
                        [undef, "argument 'bevel' must be positive"] :
                        [__BEVEL_BASES_MOD_ID, axis, [bevel,bevel,bevel], [bevel,bevel,bevel] ] :
                    is_vector_3D(bevel) ?
                        [__BEVEL_BASES_MOD_ID, axis, bevel, bevel ] :
                        is_vector_2D(bevel) ?
                            [   __BEVEL_BASES_MOD_ID, axis,
                                [bevel[0],bevel[0],bevel[1]],
                                [bevel[0],bevel[0],bevel[1]]
                            ] : 
                            [undef, "argument 'bevel' must either be a vector 3D, vector 2D or a number"] :
                is_undef(bevel_bottom) || is_undef(bevel_top) ?
                    [undef, "both arguments 'bevel_bottom' and 'bevel_top' must be defined"] :
                    (is_num(bevel_bottom) || is_vector_2D(bevel_bottom) || is_vector_3D(bevel_bottom)) &&
                    (is_num(bevel_top) || is_vector_2D(bevel_top) || is_vector_3D(bevel_top)) ?
                        [   __BEVEL_BASES_MOD_ID,
                            axis,
                            is_num(bevel_bottom) ?
                                [bevel_bottom, bevel_bottom, bevel_bottom] :
                                is_vector_2D(bevel_bottom) ?
                                    [bevel_bottom[0],bevel_bottom[0],bevel_bottom[1]] :
                                    bevel_bottom,
                            is_num(bevel_top) ?
                                [bevel_top, bevel_top, bevel_top] :
                                is_vector_2D(bevel_top) ?
                                    [bevel_top[0], bevel_top[0], bevel_top[1]] :
                                    bevel_top
                        ] :
                        [undef, "both arguments 'bevel_bottom' and 'bevel_top' must either be a vector 3D, vector 2D or a number"];