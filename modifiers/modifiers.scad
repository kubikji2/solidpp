
use<__round_corners_modifier.scad>
use<__bevel_corners_modifier.scad>
use<__bevel_bases_modifier.scad>


function round_corners(r=undef, d=undef) = 
    let(ret = __solidpp__new_round_corners(r=r,d=d))
        assert(!is_undef(ret[0]), str("[MODIFIER-round corners] ", ret[1], "!"))
        ret;


function bevel_corners(cut) =
    let(ret = __solidpp__new_bevel_corners(cut=cut))
        assert(!is_undef(ret[0]), str("[MODIFIER-bevel corners] ", ret[1], "!"))
        ret;


function bevel_bases(bevel=undef, axis="z", bevel_bottom=undef, bevel_top=undef) = 
    let(ret = __solidpp__new_bevel_bases(bevel=bevel, axis=axis, bevel_bottom=bevel_bottom, bevel_top=bevel_top))
        assert(!is_undef(ret[0]), str("[MODIFIER-bevel bases] ", ret[1], "!"))
        ret;