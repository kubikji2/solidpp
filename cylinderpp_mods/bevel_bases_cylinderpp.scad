include<../utils/solidpp_utils.scad>
include<../utils/__cylinderpp_utils.scad>
include<../modifiers/__bevel_bases_modifier.scad>
include<../transforms/transform_to_spp.scad>
include<../transforms/transform_if.scad>

include<../shapespp/circlepp.scad>
include<../shapespp/squarepp.scad>

assert(!is_undef(__DEF_CYLINDERPP__), "[BEVEL-BASES-CYLINDER++] cylinderpp.scad must be included!");

// TODO add documentation
module bevel_bases_cylinderpp(  size=undef, r=undef, d=undef, h=undef, 
                                align=undef, zet=undef, center=false,
                                r1=undef, r2=undef, d1=undef, d2=undef, fn=$fn,
                                bevel=undef, bevel_top=undef, bevel_bottom=undef,
                                mod=undef, __mod_queue=undef,__rotate_extrude=true)
{

    // module name
    __module_name = "BEVEL-BASES-CYLINDERPP";

    // check size
    __solidpp__assert_size_like(size, "size", __module_name);

    // handlign default zet
    _zet = is_undef(zet) ? "z" : zet;

    // parse and checked data
    cyl_data = __solidpp__cylinderpp__check_params(
                    module_name=__module_name, size=size, r=r, d=d, h=h,
                    r1=r1, r2=r2, d1=d1, d2=d2, zet=zet, fn=fn);
    
    __h = cyl_data[__CYLINDERPP_UTILS__h_idx];
    _size = cyl_data[__CYLINDERPP_UTILS__size_idx];
    _d1 = cyl_data[__CYLINDERPP_UTILS__d1_idx];
    _d2 = cyl_data[__CYLINDERPP_UTILS__d2_idx];
    _d_max = cyl_data[__CYLINDERPP_UTILS__d_max_idx];
    
    // for uniform size
    _is_non_uniform = cyl_data[__CYLINDERPP_UTILS__is_non_uniform_idx];
    __d1 = cyl_data[__CYLINDERPP_UTILS___d1_idx];
    __d2 = cyl_data[__CYLINDERPP_UTILS___d2_idx];

    // extracting height
    _h = !is_undef(__h) ? __h :  __solidpp__get_a_b_h_from_size_and_zet(_size, _zet)[2];

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
    if (_is_non_uniform)
    {
        translate(_o)
            difference()
            {   
                // basic geometry
                resize(_size)
                    rotate(_rot)
                        cylinderpp(d1=_d1, d2=_d2, h=1, center=true, __mod_queue=__mod_queue, fn=fn);

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
                        transform_to_spp(_area_size, align="Z", pos="z")                    
                            cylinderpp(_diff_size, align="z", fn=fn);

                        // not a cylinderpp, coz difference between base axis are not relateve, but absolute
                        // TODO fix it in the future by a single geometry
                        hull()
                        {
                            cylinderpp([_semi_axis_a, _semi_axis_b, 0.0001], fn=fn);
                            translate([0,0,-__t_h])
                                cylinderpp([_a, _b, 0.0001], fn=fn);
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
                        transform_to_spp(_area_size, align="z", pos="Z")             
                            cylinderpp(_diff_size, align="Z", fn=fn);
                        // not a cylinderpp, coz difference between base axis are not relateve, but absolute
                        // TODO fix it in the future by a single geometry
                        hull()
                        {
                            cylinderpp([_semi_axis_a, _semi_axis_b, 0.0001], fn=fn);
                            translate([0,0,__b_h])
                                cylinderpp([_a, _b, 0.0001], fn=fn);
                                
                        }
                    }
                }
            }
    }
    else
    {
        // uniform cylinder
        translate(_o)   
            rotate(_rot)
                cylinderpp(d1=__d1, d2=__d2, h=_h, center=true, fn=fn,
                            __mod_queue=__mod_queue,__rotate_extrude=__rotate_extrude)
                difference_if(__b_h > 0, __b_a < 0)
                {
                    difference_if(__t_h > 0, __t_a < 0)
                    {
                        // get proper base
                        if($children == 0)
                        {
                            // if no child, create default cut
                            __solidpp__cylinderpp__get_def_plane(d1=__d1, d2=__d2, h=_h);
                        }
                        else 
                        {
                            // else use children
                            children(0);
                        }

                        // top cuts
                        if (__t_h > 0)
                        {
                            _k = __t_h/_h;
                            _a = __solidpp__lerp(__d2-__d2, __d1-__d2, _k)/2;
                            _pts_i =    [   [   0,     0],
                                            [  _a, -__t_h],
                                            [  -__t_a,     0]];
                            translate([__d2/2,_h/2])
                                polygon(_pts_i);
                        }
                    }
                    // bottom cut
                    if (__b_h > 0)
                    {
                        _k = __b_h/_h;
                        _a = __solidpp__lerp(__d1-__d1, __d2-__d1, _k)/2;
                        _pts_i =    [   [   0,     0],
                                        [  _a, __b_h],
                                        [  -__b_a,     0]];
                        translate([__d1/2,-_h/2])
                            polygon(_pts_i);
                    }

                }
                
    }
}   