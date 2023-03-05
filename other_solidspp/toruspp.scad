include<../utils/solidpp_utils.scad>
include<../shapespp/circlepp.scad>

TORUSPP_DEF_ALIGN = "";


// TODO documentation
module toruspp(t=undef, r=undef, d=undef, R=undef, D=undef, align=undef, h=undef, zet="z", center=false)
{
    // module name
    __module_name = "TORUSPP";

    // raw argument mutex group
    _raw_mutex = [  t, 
                        is_undef(r) ? d : r,
                        is_undef(R) ? D : R
                    ];
    _raw_undef = __solidpp__count_undef_in_list(_raw_mutex);

    // first parameter processing
    __t = t;
    __r = _raw_undef == 3 ?
            0.5 :
            !is_undef(d) ?
                d/2 :
                r;
    __R = _raw_undef == 3 ?
            1 :
            !is_undef(D) ?
                D/2 :
                R;

    // computing user-defined parameters
    _mutex_group = [__t, __r, __R];
    _n_undef = __solidpp__count_undef_in_list(_mutex_group);

    // check the new mutex group
    assert(_n_undef == 1,
            str("[", __module_name, "] exactly two arguments {'r|d', 'R|D', 't'} must be defined!"));
    assert(is_undef(r) || is_undef(d),
            str("[", __module_name, "] cannot define both 'r' and 'd'!"));
    assert(is_undef(R) || is_undef(D),
            str("[", __module_name, "] cannot define both 'R' and 'D'!"));
    

    _r = !is_undef(__t) && !is_undef(__R) ? __R-__t : __r;
    _R = !is_undef(__t) && !is_undef(__r) ? __r+__t : __R;
    _t = !is_undef(__R) && !is_undef(__r) ? __R-__r : __t;

    _h = is_undef(h) ?
            _t :
            h;

    // check zet
    // '-> it is string or undef
    assert(is_undef(zet) || is_string(zet),
            str("[", __module_name, "] arguments 'zet' is eithter 'undef' or a string!"));

    _size = __solidpp__construct_cylinderpp_size(d=2*_R,h=_h, zet=zet);

    // process the align and center to produce offset
    // '-> arguments 'align' and 'center' are checked within the function
    _o = __solidpp__produce_offset_from_align_and_center(
            _size=_size,
            align=align,
            center=center,
            solidpp_name=__module_name,
            def_align=TORUSPP_DEF_ALIGN);
      
    // construct rotation
    _rot = __solidpp__get_rotation_from_zet(zet,[0,0,0]);

    // construct the solid
    translate(_o)
        rotate(_rot)
            rotate_extrude(convexity=4)
                translate([_R-_t,0,0])
                    circlepp([_t, _h],align="x");
}