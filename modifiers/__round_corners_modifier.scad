include<../utils/vector_operations.scad>

__ROUND_CORNERS_MOD_ID = "__ROUND_CORNERS__";

// corner radius idx
__ROUND_CORNERS_RADIUS_ID = 1;

// check whether the 'modifier' is a valid 'round_corner' modifier
function __solidpp__is_valid_round_corners_modifier(modifier) = 
    is_list(modifier) &&
    len(modifier) == 2 &&
    modifier[0] == __ROUND_CORNERS_MOD_ID &&
    is_vector_3D(modifier[1]);


// returns new copy of the modifier that compensate for the rounding
// '-> argument 'r' is the vector 3D describin rounding semi-axis
// WARNING: assume that argument 'round_corners_mod' is valid bevel bases mod
// WARNING: rely that argument 'r' is vector 3D
function __solidpp__round_corners__compensate_for_rounding(round_corners_mod, r) =
    [
        // id remains the same
        round_corners_mod[0],
        // mask remains the same
        round_corners_mod[1]
    ];


// returns the 'round_corners' modifier is possible
// '-> otherwise return the [undef, <message>] standard modifier format
function __solidpp__new_round_corners(r=undef, d=undef) = 
    is_undef(r) && is_undef(d) ?
        [undef, "argument 'r'|'d' must be defined"] :
        !is_undef(r) && !is_undef(d) ?
            [undef, "only one argument 'r'|'d' can be defined at the time"] :
            !is_undef(r) ?
                is_num(r) ? 
                    [ __ROUND_CORNERS_MOD_ID, [r,r,r] ] :
                    is_vector_3D(r) ?
                        [ __ROUND_CORNERS_MOD_ID, r ] :
                        [undef, "argument 'r' must either be a scalar or a 3D vector"] :
                !is_undef(d) ?
                    is_num(d) ?
                        [ __ROUND_CORNERS_MOD_ID, [d/2,d/2,d/2] ] :
                        is_vector_3D(d) ?
                            [__ROUND_CORNERS_MOD_ID, s_vec(0.5, d)] :
                            [undef, "argument 'd' must either be a scalar or a 3D vector"] :
                    [undef, "something went terribly wrong"];
            
