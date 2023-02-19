
use<__round_corners_modifier.scad>
use<__bevel_corners_modifier.scad>

function round_corners(r=undef, d=undef) = 
    let(ret = __solidpp__new_round_corners(r=r,d=d))
        assert(!is_undef(ret[0]), str("[MODIFIER-round corners] ", ret[1], "!"))
        ret;

function bevel_corners(cut) =
    let(ret = __solidpp__new_bevel_corners(cut=cut))
        assert(!is_undef(ret[0]), str("[MODIFIER-bevel corners] ", ret[1], "!"))
        ret;
