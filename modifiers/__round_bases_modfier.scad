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


// round_bases(r|d, axis='z', r_bottom|d_bottom=undef, r_top|d_top=undef)