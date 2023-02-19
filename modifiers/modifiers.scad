
use<__round_corners_modifier.scad>

function round_corner(r=undef, d=undef) = 
    let(ret = __solidpp__new_round_corner(r=r,d=d))
        assert(!is_undef(ret[0]), str("[MODIFIER-round corner] ", ret[1], "!"))
        ret;