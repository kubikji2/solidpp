use<__round_bases_modifier.scad>
use<__round_corners_modifier.scad>
use<__round_edges_modifier.scad>

use<__bevel_bases_modifier.scad>
use<__bevel_corners_modifier.scad>
use<__bevel_edges_modifier.scad>


function round_bases(r=undef, d=undef, axis="z",
                        r_bottom=undef, d_bottom=undef,
                        r_top=undef, d_top=undef) = 
    let(ret = __solidpp__new_round_bases(
                r=r,d=d, r_top=r_top, d_top=d_top,
                r_bottom=r_bottom, d_bottom=d_bottom)
        )
        assert(!is_undef(ret[0]), str("[MODIFIER-round bases] ", ret[1], "!"))
        ret;



function round_corners(r=undef, d=undef) = 
    let(ret = __solidpp__new_round_corners(r=r,d=d))
        assert(!is_undef(ret[0]), str("[MODIFIER-round corners] ", ret[1], "!"))
        ret;


function round_edges(r=undef, d=undef, axes="xy") = 
    let(ret = __solidpp__new_round_edges(r=r, d=d, axes=axes))
        assert(!is_undef(ret[0]), str("[MODIFIER-round edges] ", ret[1], "!"))
        ret;


function bevel_corners(bevel) =
    let(ret = __solidpp__new_bevel_corners(bevel=bevel))
        assert(!is_undef(ret[0]), str("[MODIFIER-bevel corners] ", ret[1], "!"))
        ret;


function bevel_bases(bevel=undef, axis="z", bevel_bottom=undef, bevel_top=undef) = 
    let(ret = __solidpp__new_bevel_bases(bevel=bevel, axis=axis, bevel_bottom=bevel_bottom, bevel_top=bevel_top))
        assert(!is_undef(ret[0]), str("[MODIFIER-bevel bases] ", ret[1], "!"))
        ret;


function bevel_edges(bevel, axes="xyz") = 
    let(ret = __solidpp__new_bevel_edges(bevel=bevel, axes=axes))
        assert(!is_undef(ret[0]), str("[MODIFIER-bevel edges] ", ret[1], "!"))
        ret;


// returns true iff 'mod' is a valid modifier
function __solidpp__is_valid_modifier(mod) = 
    let (ret = 
                __solidpp__is_valid_bevel_bases_modifier(mod) ||
                __solidpp__is_valid_bevel_corners_modifier(mod) ||
                __solidpp__is_valid_bevel_edges_modifier(mod) ||
                __solidpp__is_valid_round_corners_modifier(mod) ||
                __solidpp__is_valid_round_edges_modifier(mod)
        )
        assert(ret, str("[MODIFIER] object '", str(mod), "' is not valid modifier"))
        ret;


// __private__ recursive implementation of the is_valid_modifier_list
function __spp__is_valid_modifier_list_rec(l, idx, res) = 
    idx == len(l) ? 
        res :
        __spp__is_valid_modifier_list_rec(l, idx+1, res && __solidpp__is_valid_modifier(l[idx]));

// returns true iff 'mods' is a list of valid modifiers
function __solidpp__is_valid_modifier_list(mods) =
    is_list(mods) &&
    __spp__is_valid_modifier_list_rec(mods, 0, true);


// compensate for rounding
function __solidpp__compensate_for_rounding(mod, r) = 
    __solidpp__is_valid_bevel_bases_modifier(mod) ?
        __solidpp__bevel_bases__compensate_for_rounding(mod, r) :
        __solidpp__is_valid_bevel_corners_modifier(mod) ?
            __solidpp__bevel_corners__compensate_for_rounding(mod, r) :
            __solidpp__is_valid_bevel_edges_modifier(mod) ?
                __solidpp__bevel_edges__compensate_for_rounding(mod,r) :
                __solidpp__is_valid_round_corners_modifier(mod) ?
                    __solidpp__round_corners__compensate_for_rounding(mod,r) :
                    __solidpp__is_valid_round_edges_modifier(mod) ? 
                        __solidpp__round_edges__compensate_for_rounding(mod,r):
                        assert(false, "[MODIFIERS] unkown modifier!")
                        undef;