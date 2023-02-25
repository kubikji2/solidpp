include<../utils/vector_operations.scad>

__BEVEL_CORNERS_MOD_ID = "__BEVEL_CORNERS__";

// check whether the 'modifier' is a valid 'bevel_corners' modifier
function __solidpp__is_valid_bevel_corners_modifier(modifier) = 
    is_list(modifier) &&
    len(modifier) == 2 &&
    modifier[0] == __BEVEL_CORNERS_MOD_ID &&
    is_vector_3D(modifier[1]);


// returns the 'bevel_corners' modifier is possible
// '-> otherwise return the [undef, <message>] standard modifier format
function __solidpp__new_bevel_corners(bevel) = 
    is_num(bevel) ?
        [__BEVEL_CORNERS_MOD_ID, [bevel,bevel,bevel]] :
        is_vector_3D(bevel) ?
            [__BEVEL_CORNERS_MOD_ID, bevel] :
            [undef, "argument 'bevel' must be either number or a vector 3D" ];
