include<../utils/vector_operations.scad>

__BEVEL_CORNERS_MOD_ID = "__BEVEL_CORNERS__";

__BEVEL_CORNERS_DATA_IDX = 1;

// check whether the 'modifier' is a valid 'bevel_corners' modifier
function __solidpp__is_valid_bevel_corners_modifier(modifier) = 
    is_list(modifier) &&
    len(modifier) == 2 &&
    modifier[0] == __BEVEL_CORNERS_MOD_ID &&
    is_vector_3D(modifier[1]);


// returns new copy of the modifier that compensate for the rounding
// '-> argument 'r' is the vector 3D describin rounding semi-axis
// WARNING: assume that argument 'bevel_corners_mod' is valid bevel bases mod
// WARNING: rely that argument 'r' is vector 3D
function __solidpp__bevel_corners__compensate_for_rounding(bevel_corners_mod, r) =
    [
        // id remains the same
        bevel_corners_mod[0],
        // TODO compute the precise numbers
        bevel_corners_mod[1]
    ];

// returns the 'bevel_corners' modifier is possible
// '-> otherwise return the [undef, <message>] standard modifier format
function __solidpp__new_bevel_corners(bevel) = 
    is_num(bevel) ?
        bevel > 0 ?
            [__BEVEL_CORNERS_MOD_ID, [bevel,bevel,bevel]] :
            [undef, "argument 'bevel' cannot be smaller then zero"] :
        is_vector_3D(bevel) ?
            is_vector_positive(bevel) ?
                [__BEVEL_CORNERS_MOD_ID, bevel] :
                [undef, "argument 'bevel' cannot contain non-positive elements"]:
            [undef, "argument 'bevel' must be either number or a vector 3D" ];
