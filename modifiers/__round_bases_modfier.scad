include<../utils/vector_operations.scad>

__ROUND_BASES_MOD_ID = "__ROUND_BASES__";

// index to get the axis
__ROUND_BASES_AXIS_IDX = 1;
// index to get the bottom base data for cube
__ROUND_BASES_BOTTOM_CUBE_IDX = 2;
// index to get the bottom base data for cylinder-based
__ROUND_BASES_BOTTOM_CYLINDER_IDX = 3;
// index to get the top base data for cube
__ROUND_BASES_TOP_CUBE_IDX = 4;
// index to get the top base data for cylinder-based
__ROUND_BASES_TOP_CYLINDER_IDX = 5;


// check whether the 'modifier' is a valid 'round_bases' modifier
function __solidpp__is_valid_round_bases_modifier(modifier) = 
    is_list(modifier) &&
    len(modifier) == 6 &&
    modifier[0] == __ROUND_BASES_MOD_ID &&
    is_string(modifier[__ROUND_BASES_AXIS_IDX]) &&
    // bottom base checks
    // - cube data are undef or vector 3D
    (
        is_undef(modifier[__ROUND_BASES_BOTTOM_CUBE_IDX]) ||
        is_vector_3D(modifier[__ROUND_BASES_BOTTOM_CUBE_IDX])
    )
    &&
    // - cylinder data are undef or vector 2D
    (
        is_undef(modifier[__ROUND_BASES_BOTTOM_CYLINDER_IDX]) ||
        is_vector_2D(modifier[__ROUND_BASES_BOTTOM_CYLINDER_IDX])
    )
    &&
    // - at least one cube and cylinder data must be defined
    (
        !is_undef(modifier[__ROUND_BASES_BOTTOM_CUBE_IDX]) ||
        !is_undef(modifier[__ROUND_BASES_BOTTOM_CYLINDER_IDX])
    )
    &&
    // top base checks
    // - cube data are undef or vector 3D
    (
        is_undef(modifier[__ROUND_BASES_TOP_CUBE_IDX]) ||
        is_vector_3D(modifier[__ROUND_BASES_TOP_CUBE_IDX])
    )
    &&
    // - cylinder data are undef or vector 2D
    (
        is_undef(modifier[__ROUND_BASES_TOP_CYLINDER_IDX]) ||
        is_vector_2D(modifier[__ROUND_BASES_TOP_CYLINDER_IDX])
    )
    &&
    // - at least one cube and cylinder data must be defined
    (
        !is_undef(modifier[__ROUND_BASES_TOP_CUBE_IDX]) ||
        !is_undef(modifier[__ROUND_BASES_TOP_CYLINDER_IDX])
    )


// returns new copy of the modifier that compensate for the rounding
// '-> argument 'r' is the vector 3D describin rounding semi-axis
// WARNING: assume that argument 'round_bases_mod' is valid bevel bases mod
// WARNING: rely that argument 'r' is vector 3D
function __solidpp__round_bases__compensate_for_rounding(round_bases_mod, r) =
    [
        __ROUND_BASES_MOD_ID,
        // remains the same
        round_bases_mod[1],
        // TODO compute the precise numbers
        round_bases_mod[2],
        // TODO compute the precise numbers
        round_bases_mod[3],
        // TODO compute the precise numbers
        round_bases_mod[4],
        // TODO compute the precise numbers
        round_bases_mod[5]
    ];


// returns the 'bevel_corners' modifier if possible
// '-> otherwise return the [undef, <message>] standard modifier format
// '-> expected format is:
//     '-> "__BEVEL_BASES__"
//     '-> argument 'axis' as a string
//     '-> argument 'bevel_bottom' as vector3D
//     '-> argument 'bevel_top' as vector3D
function __solidpp__new_bevel_bases(bevel=undef, axis="z", bevel_bottom=undef, bevel_top=undef) = 
    undef;
// round_bases(r|d, axis='z', r_bottom|d_bottom=undef, r_top|d_top=undef)