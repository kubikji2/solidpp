include<../utils/solidpp_utils.scad>
include<../utils/__toroidpp_utils.scad>

include<../tubepp_mods/bevel_bases_tubepp.scad>
include<../tubepp_mods/round_bases_tubepp.scad>
include<../tubepp_mods/round_corners_tubepp.scad>

// TODO might not needed
assert(!is_undef(__DEF_CYLINDERPP__), "[TUBE++] cylinderpp.scad must be included!");

TUBEPP_DEF_ALIGN="z";

module tubepp(  size=undef, t=undef, r=undef, d=undef, R=undef, D=undef, h=undef, center=false,
                align=undef, zet="z", __mod_queue = undef,
                mod_list=undef, inner_mod_list=undef, outer_mod_list=undef)
{

    // module name
    __module_name = "TUBEPP";

    __h = is_undef(h) ? 1 : h;

    // checking and processing toroidpp parameters
    parsed_data = __solidpp__toroidpp__check_parameters(
                        module_name=__module_name, t=t, r=r, d=d, R=R, D=D, h=__h);
    _r = parsed_data[0];
    _R = parsed_data[1];
    _t = parsed_data[2];
    _h = parsed_data[3];

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
            def_align=TUBEPP_DEF_ALIGN);
      
    // construct rotation
    _rot = __solidpp__get_rotation_from_zet(zet,[0,0,0]);

    // construct the solid
    if(is_undef(mod_list) && is_undef(__mod_queue))
    {
        translate(_o)
        rotate(_rot)
        /*
        difference()
        {
            cylinderpp(r=_R, h=_h, center=true, mod_list=outer_mod_list);

            // TODO inverse inner mods
            __iner_mod_list = inner_mod_list;

            // eps affects only preview
            _eps = $preview ? 0.001 : 0;
            cylinderpp(r=_r, h=_h+_eps, center=true, mod_list=inner_mod_list);

        }
        */
        rotate_extrude()
            if($children==0)
            {
                __solidpp__toroidpp__get_def_plane(r=_r,t=_t,h=_h);
            }
            else 
            {
                children();
            }   
    }
    else
    {
        _tmp_queue = is_undef(__mod_queue) ? __solidpp__new_queue(mod_list) : __mod_queue;
        _ret = __solidpp__pop(_tmp_queue);
        _mod = _ret[0];
        _mod_queue = __solidpp__queue_size(_ret[1]) > 0 ? _ret[1] : undef;

        translate(_o)
        rotate(_rot)
        if (__solidpp__is_valid_bevel_bases_modifier(_mod))
        {
            // bevel bases
            bevel_bases_tubepp(_size, center=true, mod=_mod, __mod_queue=_mod_queue)
                if($children==0)
                {
                    __solidpp__toroidpp__get_def_plane(r=_r,t=_t,h=_h);
                }
                else 
                {
                    children();
                }
        }
        else if (__solidpp__is_valid_round_bases_modifier(_mod))
        {
            // round bases 
            round_bases_tubepp(_size, center=true, mod=_mod, __mod_queue=_mod_queue)
                if($children==0)
                {
                    __solidpp__toroidpp__get_def_plane(r=_r,t=_t,h=_h);
                }
                else 
                {
                    children();
                }
        }
        else if (__solidpp__is_valid_round_corners_modifier(_mod))
        {
            // round corners
            round_corners_tubepp(_size, center=true, mod=_mod, __mod_queue=_mod_queue)
                if($children==0)
                {
                    __solidpp__toroidpp__get_def_plane(r=_r,t=_t,h=_h);
                }
                else 
                {
                    children();
                }
        }
        else if (__solidpp__is_valid_modifier(_mod))
        {
            // bevel edges
            assert(false,
            str("[", __module_name, "] unsupported modifier!"));
        }
        else
        {
            assert(false,
            str("[", __module_name, "] something went wrong regarding modifiers!"));
        }
    }

}

// defining the cylinderpp 
__DEF_TUBEPP__ = true;