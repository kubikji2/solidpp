include<../utils/vector_operations.scad>

__ROUND_CORNERS_MOD_ID = "__ROUND_CORNERS__";

// check whether the 'modifier' is a valid 'round_corner' modifier
function __solidpp__is_valid_round_corners_modifier(modifier) = 
    is_list(modifier) &&
    len(modifier) == 2 &&
    modifier[0] == __ROUND_CORNERS_MOD_ID &&
    is_vector_3D(modifier[1]);


// returns the 'round_corners' modifier is possible
// '-> otherwise return the [undef, <message>] standard modifier format
function __solidpp__new_round_corners(r=undef, d=undef) = 
    is_undef(r) && is_undef(d) ?
        [undef, "either 'r' or 'd' must be defined"] :
        !is_undef(r) && !is_undef(d) ?
            [undef, "arguments 'r' and 'd' can be defined at the same time"] :
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
            
