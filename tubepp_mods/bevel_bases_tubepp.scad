include<../utils/solidpp_utils.scad>
include<../utils/__toroidpp_utils.scad>

assert(!is_undef(__DEF_TUBEPP__), "[BEVEL-BASES-TUBE++] tubepp.scad must be included!");
assert(!is_undef(__DEF_CYLINDERPP__), "[BEVEL-BASES-TUBE++] cylinderpp.scad must be included!");

module bevel_bases_tubepp(  size=undef, t=undef, r=undef, d=undef, R=undef, D=undef, h=undef, center=false,
                align=undef, zet="z", bevel=undef, bevel_top=undef, bevel_bottom=undef,
                mod=undef, __mod_queue=undef, inner_mod_list=undef, outer_mod_list=undef)
{

    // module name
    __module_name = "TUBEPP";

    // set default height if undef
    __h = is_undef(h) ? 1 : h;

    // checking and processing toroidpp parameters
    toroid_pars = __solidpp__toroidpp__check_parameters(
                        module_name=__module_name, t=t, r=r, d=d, R=R, D=D, h=__h);

    _r = toroid_pars[0];
    _R = toroid_pars[1];
    //_t = toroid_pars[2];
    _h = toroid_pars[3];

    // check zet
    // '-> it is string or undef
    assert(is_undef(zet) || is_string(zet),
            str("[", __module_name, "] arguments 'zet' is eithter 'undef' or a string!"));

    _size = __solidpp__construct_cylinderpp_size(d=2*_R,h=_h, zet=zet);

    // bevel base oriented parsing

    // TODO check mod
    
    // TODO check both mod and bevel, axis, bevel_bottom, bevel_top

    // handling default bevel
    _bevel = !is_undef(bevel) || (!is_undef(bevel_top) || !is_undef(bevel_bottom)) ? 
                bevel :
                0.1;

    // processing data using the modifier constructor back-end
    parsed_data = !is_undef(mod) ? 
                    mod :
                    __solidpp__new_bevel_bases(
                        bevel=_bevel,
                        axis="z",
                        bevel_bottom=bevel_bottom,
                        bevel_top=bevel_top);

    // check parsed data
    assert(!is_undef(parsed_data[0]), str("[", __module_name, "] ", parsed_data[1], "!"));

    // expand data
    _bevel_bottom = parsed_data[__BEVEL_BASES_BOTTOM_2D_IDX];
    _bevel_top = parsed_data[__BEVEL_BASES_TOP_2D_IDX];

    // check parsed data
    assert( !is_undef(_bevel_bottom),
            str("[", __module_name, "] using 3D vector for beveling cylinder is not allowed!"));
    assert( !is_undef(_bevel_top),
            str("[", __module_name, "] using 3D vector for beveling cylinder is not allowed!"));

    // expand bevels
    __b_a = _bevel_bottom[0];
    __b_h = _bevel_bottom[1];
    __t_a = _bevel_top[0];
    __t_h = _bevel_top[1];

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

    translate(_o)
    rotate(_rot)
    difference()
    {
        // basic tube
        tubepp( r=_r, R=_R, h=_h, center=true, __mod_queue=__mod_queue,
                inner_mod_list=inner_mod_list, outer_mod_list=outer_mod_list);

        // top bevel
        if (__t_h > 0)
        {   
            _area_size = [2*_R, 2*_R, __t_h];
            _diff_size = scale_vec(1.1, _area_size);

            // transform to the top of the bounding box cube
            transform_to_spp([2*_R, 2*_R, _h],"",pos="Z")
            difference()
            {
                transform_to_spp(_area_size,align="Z",pos="z")                    
                    cylinderpp(_diff_size, align="z");

                // not a cylinderpp, coz difference between base axis are not relateve, but absolute
                difference()
                {
                    cylinderpp(r1=_R, r2=_R-__t_a, h=__t_h, align="Z");

                    // eps affects only preview
                    _eps = $preview ? 0.0001 : 0;
                    translate([0,0,_eps])
                        cylinderpp(r1=_r, r2=_r+__t_a, h=__t_h+_eps, align="Z");

                }
            }            
        }

        // bottom bevel
        if (__b_h > 0)
        {   
            _area_size = [2*_R, 2*_R, __b_h];
            _diff_size = scale_vec(1.1, _area_size);

            // transform to the top of the bounding box cube
            transform_to_spp([2*_R, 2*_R, _h],"",pos="z")
            difference()
            {
                transform_to_spp(_area_size,align="z",pos="Z")                    
                    cylinderpp(_diff_size, align="Z");

                // not a cylinderpp, coz difference between base axis are not relateve, but absolute
                difference()
                {
                    cylinderpp(r2=_R, r1=_R-__t_a, h=__t_h, align="z");

                    // eps affects only preview
                    _eps = $preview ? 0.0001 : 0;
                    translate([0,0,-_eps])
                        cylinderpp(r2=_r, r1=_r+__t_a, h=__t_h+_eps, align="z");

                }
            }            
        }

    }

}
