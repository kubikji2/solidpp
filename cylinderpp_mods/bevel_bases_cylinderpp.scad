include<../utils/solidpp_utils.scad>
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

    // {h, r|d} and size is illegal
    assert( is_undef(size) || (is_undef(r) && is_undef(d) && is_undef(h)) ,
            str("[",__module_name,"] defining both 'size' and ('r'|'d'),'h' is not permited!"));

    // check h
    assert( is_undef(h) || is_num(h),
            str("[",__module_name,"] argument 'h' is not a number!"));
    // process heigh
    _h = !is_undef(h) ? h : 1;

    // check r and d
    assert( is_undef(r) || is_num(r) || is_vector_2D(r),
            str("[",__module_name,"] argument 'r' is neither a number nor vector 2D!"));
    assert( is_undef(d) || is_num(d) || is_vector_2d(d), 
            str("[",__module_name,"] argument 'd' is neither a number nor vector 2D!"));
    assert( is_undef(r) || is_undef(d),
            str("[",__module_name,"] defining both 'd' and 'r' is not permitted!"));
    // process r and d
    _d = !is_undef(d) ?
            d :  
            !is_undef(r) ?
                is_num(d) ?  // this is not necessary in recent openscad releases
                    2*r :
                    scale_vector(2,r) :
                1;

    // d1,d2 and r1,r2 must be defined in pairs
    assert( is_undef(d1)==is_undef(d2),
            str("[",__module_name,"] either none or both arguments 'd1','d2' must be defined!"));
    assert( is_undef(r1)==is_undef(r2),
            str("[",__module_name,"] either none or both arguments 'r1','r2' must be defined!"));

    // d1, d2, r1, r2 are either undefined or numbers
    assert( is_undef(r1) || is_num(r1),
            str("[",__module_name,"] argument 'r1' is not a number!"));
    assert( is_undef(d1) || is_num(d1), 
            str("[",__module_name,"] argument 'd1' is not a number!"));
    assert( is_undef(r2) || is_num(r2),
            str("[",__module_name,"] argument 'r2' is not a number!"));
    assert( is_undef(d2) || is_num(d2),
            str("[",__module_name,"] argument 'd2' is not a number!"));

    // both r1,r2 and d1,d2 pairs cannod be defined at the same time
    assert( is_undef(r1) || is_undef(d1),
            str("[",__module_name,"] you cannot define both 'r1' and 'd1' at the same time!"));
    assert( is_undef(r2) || is_undef(d2),
            str("[",__module_name,"] you cannot define both 'r2' and 'd2' at the same time!"));
    
    // process r1,r2 or d1,d2 or _d to absolute diameters __d1,__d2
    __d1 = !is_undef(d1) ?
            d1 :
            !is_undef(r1) ?
                2*r1 :
                is_vector_2D(_d) ?
                    _d[0] :
                    _d;
    
    __d2 = !is_undef(d2) ?
            d2 :
            !is_undef(r2) ?
                2*r2 :
                is_vector_2D(_d) ?
                    _d[1] :
                    _d;
    
    // get maximum of the the diameters __d1,__d2
    _d_max = !is_undef(__d1) && ! is_undef(__d2) ?
                max(__d1,__d2) :
                undef;

    // d1 and d2 are either 1, or relative to each other
    _d1 = !is_undef(__d1) && !is_undef(_d_max) ?
            __d1/_d_max :
            1;
    
    _d2 = !is_undef(__d2) && !is_undef(_d_max) ?
            __d2/_d_max :
            1;

    // check size
    __solidpp__assert_size_like(size, "size", __module_name);
    
    // create bounding box from size
    __size = __solidpp__get_argument_as_3Dlist(size, undef);
    
    // create bounding box, possibly using cylinder-specific arguments
    _size = !is_undef(__size) ?
                __size :
                !is_undef(_d_max) && !is_undef(_h) ?
                    __solidpp__construct_cylinderpp_size(_d_max, _h, zet) :
                    [1,1,1];
    
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