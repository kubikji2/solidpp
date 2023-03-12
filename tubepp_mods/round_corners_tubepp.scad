include<../utils/solidpp_utils.scad>
include<../utils/vector_operations.scad>
include<../utils/__toroidpp_utils.scad>
include<../modifiers/__modifiers_queue.scad>

// TODO might not needed
assert(!is_undef(__DEF_TUBEPP__), "[ROUND-CORNERS-TUBE++] tubepp.scad must be included!");
assert(!is_undef(__DEF_CYLINDERPP__), "[ROUND-CORNERS-TUBE++] cylinderpp.scad must be included!");

TUBEPP_DEF_ALIGN="z";

module round_corners_tubepp(    size=undef, t=undef, r=undef, d=undef, R=undef, D=undef, h=undef,
                                center=false, align=undef, zet="z", __mod_queue = undef,
                                rounding_r=undef, rounding_d=undef,
                                mod=undef, inner_mod_list=undef, outer_mod_list=undef)
{
    // module name
    __module_name = "ROUND-CORNERS-TUBE++";

    // set default height if undef
    __h = is_undef(h) ? 1 : h;

    // checking and processing toroidpp parameters
    toroid_pars = __solidpp__toroidpp__check_parameters(
                        module_name=__module_name, t=t, r=r, d=d, R=R, D=D, h=__h);

    _r = toroid_pars[0];
    _R = toroid_pars[1];
    _t = toroid_pars[2];
    _h = toroid_pars[3];

    // check zet
    // '-> it is string or undef
    assert(is_undef(zet) || is_string(zet),
            str("[", __module_name, "] arguments 'zet' is either 'undef' or a string!"));

    _size = __solidpp__construct_cylinderpp_size(d=2*_R,h=_h, zet=zet);

    // handling default rounding
    ___round_r = is_undef(rounding_r) && is_undef(rounding_d) ? 0.1 : rounding_r;

    // bevel base oriented parsing

    // TODO check mod
    
    // TODO check both mod and bevel, axis, bevel_bottom, bevel_top

    // processing data using the modifier constructor back-end
    parsed_data = !is_undef(mod) ?
                    mod :
                    __solidpp__new_round_corners(r=___round_r,d=rounding_d);
    
    // check parsed data
    assert(!is_undef(parsed_data[0]), str("[", __module_name, "] ", parsed_data[1], "!"));

    __round_r = parsed_data[1];
    _round_r = __round_r[0];

    assert(
            __round_r[0] == __round_r[1] && __round_r[0] == __round_r[2],
            str("[", __module_name, "] using non-uniform ounding is not supported!")
    );

    // construct _size aka inner cube size
    __size = sub_vecs(_size, s_vec(2,__round_r));

    // check _size for negative elements
    assert(
            is_vector_non_negative(__size),
            str("[",__module_name,"] argument 'size' must be at least equal to the 'r'|'d' in each axis.")
            );

    // process the align and center to produce offset
    // '-> arguments 'align' and 'center' are checked within the function
    _o = __solidpp__produce_offset_from_align_and_center(
            _size=_size,
            align=align,
            center=center,
            solidpp_name=__module_name,
            def_align=CYLINDERPP_DEF_ALIGN);

    // composing rotation
    _rot = __solidpp__get_rotation_from_zet(zet,[0,0,0]);

    translate(_o)
    rotate(_rot)
    tubepp( r=_r, R=_R, h=_h, center=true, __mod_queue=__mod_queue,
        inner_mod_list=inner_mod_list, outer_mod_list=outer_mod_list)
        {
            offset(_round_r)
                offset(-_round_r)
                    if($children==0)
                    {
                        __solidpp__toroidpp__get_def_plane(r=_r,t=_t,h=_h);
                    }
                    else 
                    {
                        children();
                    }
        }
    /*
    minkowski()
    {
        __r = _r + _round_r;
        __R = _R - _round_r;
        __h = _h - 2*_round_r;
        
        tubepp( r=__r, R=__R, h=__h, center=true,
            __mod_queue=__mod_queue, inner_mod_list=inner_mod_list, outer_mod_list=outer_mod_list);

        spherepp(scale_vec(2,__round_r));
    }
    */

}