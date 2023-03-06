include<../utils/solidpp_utils.scad>
include<../utils/cylinderpp_utils.scad>
include<../modifiers/__round_bases_modifier.scad>
include<../transforms/transform_to_spp.scad>

assert(!is_undef(__DEF_CYLINDERPP__), "[ROUND-BASES-CYLINDER++] cylinderpp.scad must be included!");
assert(!is_undef(__DEF_SPHEREPP__), "[ROUND-BASES-CYLINDER++] spherepp.scad must be included!");

module round_bases_cylinderpp(  size=undef, r=undef, d=undef, h=undef, 
                                align=undef, zet=undef, center=false,
                                r1=undef, r2=undef, d1=undef, d2=undef,
                                r_both=undef, d_both=undef, r_top=undef,
                                d_top=undef, r_bottom=undef, d_bottom=undef,
                                mod=undef)
{

    // module name
    __module_name = "ROUND-BASES-CYLINDERPP";

    // check size
    __solidpp__assert_size_like(size, "size", __module_name);

    // handlign default zet
    _zet = is_undef(zet) ? "z" : zet;

    // parse and checked data
    cyl_data = __solidpp__cylinderpp__check_params(
                    module_name=__module_name, size=size, r=r, d=d, h=h,
                    r1=r1, r2=r2, d1=d1, d2=d2, zet=_zet);
    
    __h = cyl_data[__CYLINDERPP_UTILS__h_idx];
    _size = cyl_data[__CYLINDERPP_UTILS__size_idx];
    _d1 = cyl_data[__CYLINDERPP_UTILS__d1_idx];
    _d2 = cyl_data[__CYLINDERPP_UTILS__d2_idx];
    _d_max = cyl_data[__CYLINDERPP_UTILS__d_max_idx];
    __d1 = cyl_data[__CYLINDERPP_UTILS___d1_idx];
    __d2 = cyl_data[__CYLINDERPP_UTILS___d2_idx];
    
    _h = !is_undef(__h) ? __h :  __solidpp__get_a_b_h_from_size_and_zet(_size, _zet)[2];

    // handling default bevel
    _round_r =  !is_undef(r_both) || !is_undef(d_both) || !is_undef(r_top) ||
                !is_undef(d_top) || !is_undef(r_bottom) || !is_undef(d_bottom)? 
                    r_both :
                    0.1;

    // bevel base oriented parsing

    // TODO check mod
    
    // TODO check both mod and r_both|d_both, r_bottom|d_bottom, r_top|d_top

    // processing data using the modifier constructor back-end
    parsed_data = !is_undef(mod) ? 
                    mod :
                    __solidpp__new_round_bases(
                        r=_round_r, d=d_both, axis="z",
                        r_bottom=r_bottom, d_bottom=d_bottom,
                        r_top=r_top, d_top=d_top);

    // check parsed data
    assert(!is_undef(parsed_data[0]), str("[", __module_name, "] ", parsed_data[1], "!"));

    // expand data  
    _r_bottom = parsed_data[__ROUND_BASES_BOTTOM_2D_IDX];
    _r_top = parsed_data[__ROUND_BASES_TOP_2D_IDX];

    // check parsed data
    assert( !is_undef(_r_bottom),
            str("[", __module_name, "] using 3D vector for rounding cylinder is not allowed!"));
    assert( !is_undef(_r_top),
            str("[", __module_name, "] using 3D vector for rounding cylinder is not allowed!"));

    // expand bevels
    __b_r = _r_bottom[0];
    __b_h = _r_bottom[1];
    __t_r = _r_top[0];
    __t_h = _r_top[1];

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

                _semi_axis_a = _a - 2*__t_r;
                _semi_axis_b = _b - 2*__t_r;
                
                _area_size = [_a, _b, __t_h];
                _diff_size = scale_vec(1.1,_area_size);

                // transform to the bottom of the bounding box cube
                transform_to_spp([_a, _b, _h],"",pos="Z")
                difference()
                {
                    transform_to_spp(_area_size,align="Z",pos="z")                    
                        cylinderpp(_diff_size, align="z");
                    
                    minkowski()
                    {
                        translate([0,0,-__t_h])    
                            cylinderpp([_semi_axis_a,_semi_axis_b,__t_h], align="Z");
                        spherepp(scale_vec(2,[__t_r,__t_r,__t_h]));
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
                
                _semi_axis_a = _a - 2*__b_r;
                _semi_axis_b = _b - 2*__b_r;
                
                _area_size = [_a, _b, __b_h];
                _diff_size = scale_vec(1.1,_area_size);

                // transform to the top of the bounding box cube
                transform_to_spp([_a, _b, _h],"",pos="z")
                difference()
                {
                    // cylinderpp aligned to the the top of the beveled cylinder
                    transform_to_spp(_area_size,align="z",pos="Z")             
                        cylinderpp(_diff_size, align="Z");
                    
                    minkowski()
                    {
                        translate([0,0,__b_h])    
                            cylinderpp([_semi_axis_a,_semi_axis_b,__b_h], align="z");
                        spherepp(scale_vec(2,[__b_r,__b_r,__b_h]));
                    }
                }
            }

        }


}