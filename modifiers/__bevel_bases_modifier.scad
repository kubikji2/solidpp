include<../utils/vector_operations.scad>
include<../utils/solidpp_utils.scad>

__BEVEL_BASES_MOD_ID = "__BEVEL_BASES__";

// index to get the axis
__BEVEL_AXIS_IDX = 1;
// index to get the base bottom data in form of 3D vector
__BEVEL_BASES_BOTTOM_3D_IDX = 2;
// index to get the base bottom data in form of 2D vector
__BEVEL_BASES_BOTTOM_2D_IDX = 3;
// index to get the top data in form of 3D vector
__BEVEL_BASES_TOP_3D_IDX = 4;
// index to get the top data in form of 2D vector
__BEVEL_BASES_TOP_2D_IDX = 5;

// check whether the 'modifier' is a valid 'bevel_bases' modifier
function __solidpp__is_valid_bevel_bases_modifier(modifier) = 
    is_list(modifier) &&
    len(modifier) == 6 &&
    modifier[0] == __BEVEL_BASES_MOD_ID &&
    is_string(modifier[1]) &&
    // bottom base checks
    // - cube data are undef or vector 3D
    (
        is_undef(modifier[__BEVEL_BASES_BOTTOM_3D_IDX]) ||
        is_vector_3D(modifier[__BEVEL_BASES_BOTTOM_3D_IDX])
    )
    &&
    // - cylinder data are undef or vector 2D
    (
        is_undef(modifier[__BEVEL_BASES_BOTTOM_2D_IDX]) ||
        is_vector_2D(modifier[__BEVEL_BASES_BOTTOM_2D_IDX])
    )
    &&
    // - at least one cube and cylinder data must be defined
    (
        !is_undef(modifier[__BEVEL_BASES_BOTTOM_3D_IDX]) ||
        !is_undef(modifier[__BEVEL_BASES_BOTTOM_2D_IDX])
    )
    &&
    // top base checks
    // - cube data are undef or vector 3D
    (
        is_undef(modifier[__BEVEL_BASES_TOP_3D_IDX]) ||
        is_vector_3D(modifier[__BEVEL_BASES_TOP_3D_IDX])
    )
    &&
    // - cylinder data are undef or vector 2D
    (
        is_undef(modifier[__BEVEL_BASES_TOP_2D_IDX]) ||
        is_vector_2D(modifier[__BEVEL_BASES_TOP_2D_IDX])
    )
    &&
    // - at least one cube and cylinder data must be defined
    (
        !is_undef(modifier[__BEVEL_BASES_TOP_3D_IDX]) ||
        !is_undef(modifier[__BEVEL_BASES_TOP_2D_IDX])
    );


// returns new copy of the modifier that compensate for the rounding
// '-> argument 'r' is the vector 3D describin rounding semi-axis
// WARNING: assume that argument 'bevel_bases_mod' is valid bevel bases mod
// WARNING: rely that argument 'r' is vector 3D
function __solidpp__bevel_bases__compensate_for_rounding(bevel_bases_mod, r) =
    [
        __BEVEL_BASES_MOD_ID,
        // remains the same
        bevel_bases_mod[1],
        // TODO compute the precise numbers
        bevel_bases_mod[2],
        // TODO compute the precise numbers
        bevel_bases_mod[3],
        // TODO compute the precise numbers
        bevel_bases_mod[4],
        // TODO compute the precise numbers
        bevel_bases_mod[5]
    ];


function __spp__get_bevel_for_axis(b,h,axis) =
    axis == "x" || axis == "X" ? 
        [h,b,b] :
        axis == "y" || axis == "Y" ?
            [b,h,b] :
            [b,b,h];


// returns the 'bevel_bases' modifier if possible
// '-> otherwise return the [undef, <message>] standard modifier format
// '-> expected format is:
//     '-> "__BEVEL_BASES__"
//     '-> argument 'axis' as a string
//     '-> argument 'bevel_bottom' as vector3D
//     '-> argument 'bevel_top' as vector3D
function __solidpp__new_bevel_bases(bevel=undef, axis="z", bevel_bottom=undef, bevel_top=undef) = 
    is_undef(bevel) && is_undef(bevel_bottom) && is_undef(bevel_top) ?
        [undef, "argument 'bevel' or 'bevel_bottom' or 'bevel_top' or 'bevel_bottom' and 'bevel_top' must be defined"] :
        !is_undef(bevel) && (!is_undef(bevel_bottom) || !is_undef(bevel_top)) ?
            [undef, "argument 'r|d' cannot be used at the same time with 'r_bottom|d_bottom' or 'r_top|d_to"] :
            !is_undef(bevel) && (!is_undef(bevel_bottom) && !is_undef(bevel_top)) ?
                [undef, "argument 'bevel' canot be used with 'bevel_top' or 'bevel_bottom'"] :
                !is_string(axis) && len(axis) == 1 ?
                    [undef, "argument 'axis' must be string of size 1"] :
                    !is_undef(bevel) ?
                        is_num(bevel) ?
                            bevel <= 0 ?
                                //[undef, "argument 'bevel' must be positive"] :
                                [__BEVEL_BASES_MOD_ID, axis, undef, [bevel, -bevel], undef, [bevel, -bevel] ] :
                                [__BEVEL_BASES_MOD_ID, axis, [bevel,bevel,bevel], [bevel, bevel], [bevel,bevel,bevel], [bevel, bevel] ] :
                            is_vector_3D(bevel) ?
                                [__BEVEL_BASES_MOD_ID, axis, bevel, undef, bevel, undef ] :
                                is_vector_2D(bevel) ?
                                    [   __BEVEL_BASES_MOD_ID, axis,
                                        __solidpp__expand_a_and_h_based_on_axis(bevel[0], bevel[1], axis),
                                        bevel,
                                        __solidpp__expand_a_and_h_based_on_axis(bevel[0], bevel[1], axis),
                                        bevel
                                    ] : 
                                    [undef, "argument 'bevel' must either be a vector 3D, vector 2D or a number"] :
                        let(
                            _bevel_bottom = is_undef(bevel_bottom) ? 0 : bevel_bottom,
                            _bevel_top = is_undef(bevel_top) ? 0 : bevel_top
                        )
                        (is_num(_bevel_bottom) || is_vector_2D(_bevel_bottom) || is_vector_3D(_bevel_bottom)) &&
                        (is_num(_bevel_top) || is_vector_2D(_bevel_top) || is_vector_3D(_bevel_top)) ?
                            [   __BEVEL_BASES_MOD_ID,
                                axis,
                                // bevel_bottom as vector 3D
                                is_num(_bevel_bottom) ?
                                    [_bevel_bottom, _bevel_bottom, _bevel_bottom] :
                                    is_vector_2D(_bevel_bottom) ?
                                        __solidpp__expand_a_and_h_based_on_axis(_bevel_bottom[0], _bevel_bottom[1], axis) :
                                        _bevel_bottom,
                                // bevel_bottom as vector 2D
                                is_vector_2D(_bevel_bottom) ?
                                    _bevel_bottom :
                                    is_num(_bevel_bottom) ?
                                        [_bevel_bottom, _bevel_bottom] :
                                        undef,
                                // bevel_top as vector 3D
                                is_num(_bevel_top) ?
                                    [_bevel_top, _bevel_top, _bevel_top] :
                                    is_vector_2D(_bevel_top) ?
                                        __solidpp__expand_a_and_h_based_on_axis(_bevel_top[0], _bevel_top[1], axis) :
                                        _bevel_top,
                                // bevel_top as vector 2D
                                is_vector_2D(_bevel_top) ?
                                    _bevel_top :
                                    is_num(_bevel_top) ?
                                        [_bevel_top, _bevel_top] :
                                        undef
                            ] :
                            [undef, "arguments 'bevel_bottom' and 'bevel_top' must either be a vector 3D, vector 2D or a number"];