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

function __spp__round_bases__construct_r_from(r,d) = 
    !is_undef(r) ?
        r :
        is_num(d) ?
            r/2 :
            is_vector_2D(d) || is_vector_3D(d) ?
                scale_vec(0.5, d) :
                undef;


// returns the 'round_bases' modifier if possible
// '-> otherwise return the [undef, <message>] standard modifier format
// '-> expected format is:
//     '-> "__ROUND_BASES__"
//     '-> argument 'axis' as a string
//     '-> argument 'r_bottom' as vector3D
//     '-> argument 'r_bottom' as vector2D or undef
//     '-> argument 'r_top' as vector3D
//     '-> argument 'r_top' as vector2D or undef
function __solidpp__new_round_bases(r=undef, d=undef, axis="z",
                                    r_bottom=undef, d_bottom=undef,
                                    r_top=undef, d_top=undef) = 
    let(
        is_tb_def =!is_undef(r) || !is_undef(d),
        is_b_def = !is_undef(r_bottom) || !is_undef(d_bottom),
        is_t_def = !is_undef(r_top) || !is_undef(d_top) 
        )
    (!is_tb_def) && (!is_b_def) && (!is_t_def) ?
        [undef, "argument 'r|d' or 'r_bottom|d_bottom' or 'r_top|d_top' or 'r_bottom|d_bottom' and 'r_top|d_top' must be defined"] :
        is_tb_def && (is_b_def || is_t_def) ?
            [undef, "argument 'r|d' cannot be used at the same time with 'r_bottom|d_bottom' or 'r_top|d_top'"] :
            !is_string(axis) && len(axis) == 1 ?
                [undef, "argument 'axis' must be string of size 1"] :
                !is_tb_def ?
                    let(
                        _r = __spp__round_bases__construct_r_from(r,d);
                    )
                    is_num(_r) ?
                        _r <= 0 ?
                            [undef, "argument 'r|d' must be positive"] :
                            [   __ROUND_BASES_MOD_ID, axis, 
                                [_r,_r,_r], [_r,_r],
                                [_r,_r,_r], [_r,_r] ] :
                        is_vector_3D(_r) ?
                            [__ROUND_BASES_MOD_ID, axis, _r, undef, _r, undef ] :
                            is_vector_2D(_r) ?
                                [   __ROUND_BASES_MOD_ID, axis,
                                    __solidpp__expand_a_and_h_based_on_axis(_r[0], _r[1], axis),
                                    _r,
                                    __solidpp__expand_a_and_h_based_on_axis(_r[0], _r[1], axis),
                                    _r
                                ] : 
                                [undef, "argument 'r|d' must either be a vector 3D, vector 2D or a number"] :
                let(
                    _rb = !is_b_def ?
                            0 :
                            __spp__round_bases__construct_r_from(r_bottom, d_bottom)
                    _rt = !is_t_def ?
                            0 :
                            __spp__round_bases__construct_r_from(r_top, d_top)
                )
                (is_num(_rb) || is_vector_2D(_rb) || is_vector_3D(_rb)) &&
                (is_num(_rt) || is_vector_2D(_rt) || is_vector_3D(_rt)) ?
                    [   __ROUND_BASES_MOD_ID,
                        axis,
                        // argument 'r_bottom' as vector3D
                        is_num(_rb) ?
                            [_rb, _rb, _rb] :
                            is_vector_2D(_rb) ?
                                __solidpp__expand_a_and_h_based_on_axis(_rb[0], _rb[1], axis) :
                                _rb,
                        // argument 'r_bottom' as vector2D or undef
                        is_num(_rb) ?
                            [_rb, _rb] :
                            is_vector_2D(_rb) ?
                                _rb :
                                undef,
                        // argument 'r_top' as vector3D
                        is_num(_rt) ?
                            [_rt, _rt, _rt] :
                            is_vector_2D(_rt) ?
                                __solidpp__expand_a_and_h_based_on_axis(_rt[0], _rt[1], axis) :
                                _rt,
                        // argument 'r_top' as vector2D or undef
                        is_num(_rt) ?
                            [_rt, _rt] :
                            is_vector_2D(_rt) ?
                                _rt :
                                undef
                    ] :
                    [undef, "arguments 'r_top|d_top' and 'r_bottom|d_bottom' must either be a vector 3D, vector 2D or a number"];
