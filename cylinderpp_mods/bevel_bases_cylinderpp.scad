include<../utils/solidpp_utils.scad>
include<../utils/cylinderpp_utils.scad>
include<../modifiers/__bevel_bases_modifier.scad>
include<../transforms/transform_to_spp.scad>

assert(!is_undef(__DEF_CYLINDERPP__), "[BEVEL-BASES-CYLINDER++] cylinderpp.scad must be included!");


module bevel_bases_cylinderpp(  size=undef, r=undef, d=undef, h=undef, 
                                align=undef, zet=undef, center=false,
                                r1=undef, r2=undef, d1=undef, d2=undef,
                                bevel=undef, bevel_top=undef, bevel_bottom=undef,
                                mod=undef)
{

    // module name
    __module_name = "BEVEL-BASES-CYLINDERPP";

    // check size
    __solidpp__assert_size_like(size, "size", __module_name);

    // parse and checked data
    cyl_data = __solidpp__cylinderpp__check_params(
                    module_name=__module_name, size=size, r=r, d=d, h=h,
                    r1=r1, r2=r2, d1=d1, d2=d2, zet=zet);
    
    _h = cyl_data[__CYLINDERPP_UTILS__h_idx];
    _size = cyl_data[__CYLINDERPP_UTILS__size_idx];
    _d1 = cyl_data[__CYLINDERPP_UTILS__d1_idx];
    _d2 = cyl_data[__CYLINDERPP_UTILS__d2_idx];
    _d_max = cyl_data[__CYLINDERPP_UTILS__d_max_idx];
    __d1 = cyl_data[__CYLINDERPP_UTILS___d1_idx];
    __d2 = cyl_data[__CYLINDERPP_UTILS___d2_idx];
    
    // bevel base oriented parsing

    // TODO check mod
    
    // TODO check both mod and bevel, axis, bevel_bottom, bevel_top

    // handling default bevel
    _bevel = !is_undef(bevel) || (!is_undef(bevel_top) || !is_undef(bevel_bottom)) ? 
                bevel :
                0.1;

    // handlign default zet
    _zet = is_undef(zet) ? "z" : zet;

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

    _t_h = __t_h/_h;
    _b_h = __b_h/_h;

    // process the align and center to produce offset
    // '-> arguments 'align' and 'center' are checked within the function
    _o = __solidpp__produce_offset_from_align_and_center(
            _size=_size,
            align=align,
            center=center,
            solidpp_name=__module_name,
            def_align=CYLINDERPP_DEF_ALIGN);

    // check zet
    // '-> it is string or undef
    assert(is_undef(_zet) || is_string(_zet), str("[",__module_name,"] arguments 'zet' is not a string!"));
    
    // construct rotation
    _rot = __solidpp__get_rotation_from_zet(zet,[0,0,0]);

    // construct the solid
    translate(_o)
        difference()
        {   
            // basic geometry
            resize(_size)
                rotate(_rot)
                    cylinderpp(d1=_d1, d2=_d2, h=1, center=true);

            // parse size based on the orientation difined by zet
            base_dims = __solidpp__get_a_b_h_from_size_and_zet(_size, _zet);
            __a = base_dims[0];
            __b = base_dims[1];
            
            // top cut
            rotate(_rot)
            if (_t_h > 0)
            {   
                _k = _d1 < _d2 ? 0 : _t_h;

                _a = __solidpp__lerp(__a*_d2, __a*_d1, _k);
                _b = __solidpp__lerp(__b*_d2, __b*_d1, _k);

                _semi_axis_a = __solidpp__lerp(__a*_d2, __a*_d1, _k) - 2*__t_a;
                _semi_axis_b = __solidpp__lerp(__b*_d2, __b*_d1, _k) - 2*__t_a;
                
                _area_size = [_a, _b, __t_h];
                _diff_size = scale_vec(1.1,_area_size);

                // transform to the top of the bounding box cube
                transform_to_spp([_a, _b, _h],"",pos="Z")
                difference()
                {
                    transform_to_spp(_area_size,align="Z",pos="z")                    
                        cylinderpp(_diff_size, align="z");

                    // not a cylinderpp, coz differnce between base axis are not relateve, but absolute
                    // TODO fix it in the future
                    hull()
                    {
                        cylinderpp([_semi_axis_a, _semi_axis_b, 0.0001]);
                        translate([0,0,-__t_h])
                            cylinderpp([_a, _b, 0.0001]);
                    }
                }
            }

            // bottom cut
            rotate(_rot)
            if (_b_h > 0)
            {   
                _k = _d1 > _d2 ? 0 : _b_h;
                _a = __solidpp__lerp(__a*_d1, __a*_d2, _k);
                _b = __solidpp__lerp(__b*_d1, __b*_d2, _k);
                _semi_axis_a = __solidpp__lerp(__a*_d1, __a*_d2, _k) - 2*__b_a;
                _semi_axis_b = __solidpp__lerp(__b*_d1, __b*_d2, _k) - 2*__b_a;
                _area_size = [_a, _b, __b_h];
                _diff_size = scale_vec(1.1,_area_size);

                // transform to the bottom of the bounding box cube
                transform_to_spp([_a, _b, _h],"",pos="z")
                difference()
                {
                    // cylinderpp aligned to the the top of the beveled cylinder
                    transform_to_spp(_area_size,align="z",pos="Z")             
                        cylinderpp(_diff_size, align="Z");
                    // not a cylinderpp, coz differnce between base axis are not relateve, but absolute
                    // TODO fix it in the future
                    hull()
                    {
                        cylinderpp([_semi_axis_a, _semi_axis_b, 0.0001]);
                        translate([0,0,__b_h])
                            cylinderpp([_a, _b, 0.0001]);
                            
                    }
                }
            }                

        }
}   