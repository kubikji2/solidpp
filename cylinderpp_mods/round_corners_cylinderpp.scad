include<../utils/solidpp_utils.scad>
include<../utils/__cylinderpp_utils.scad>
include<../modifiers/__round_corners_modifier.scad>
include<../transforms/transform_to_spp.scad>
include<../transforms/mirrorpp.scad>

assert(!is_undef(__DEF_CYLINDERPP__), "[ROUND-CORNERS-CYLINDER++] cylinderpp.scad must be included!");
assert(!is_undef(__DEF_SPHEREPP__), "[ROUND-CORNERS-CYLINDER++] spherepp.scad must be included!");

// TODO add documentation
module round_corners_cylinderpp(    size=undef, r=undef, d=undef, h=undef, 
                                    align=undef, zet=undef, center=false,
                                    r1=undef, r2=undef, d1=undef, d2=undef,
                                    rounding_r=undef, rounding_d=undef,
                                    mod=undef, __mod_queue=undef,__rotate_extrude=true)
{

    // module name
    __module_name = "ROUND-CORNERS-CYLINDERPP";

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
    
    // for uniform size
    __is_non_uniform = cyl_data[__CYLINDERPP_UTILS__is_non_uniform_idx];
    __d1 = cyl_data[__CYLINDERPP_UTILS___d1_idx];
    __d2 = cyl_data[__CYLINDERPP_UTILS___d2_idx];
    
    // extracting height
    _h = !is_undef(__h) ? __h :  __solidpp__get_a_b_h_from_size_and_zet(_size, _zet)[2];

    // handling default bevel
    __round_r = is_undef(rounding_r) && is_undef(rounding_d) ? 0.1 : rounding_r;
    
    // bevel base oriented parsing

    // TODO check mod
    
    // TODO check both mod and r_both|d_both, r_bottom|d_bottom, r_top|d_top

    // processing data using the modifier constructor back-end
    parsed_data = !is_undef(mod) ?
                    mod :
                    __solidpp__new_round_corners(r=__round_r,d=rounding_d);
    
    // check parsed data
    assert(!is_undef(parsed_data[0]), str("[", __module_name, "] ", parsed_data[1], "!"));

    _round_r = parsed_data[1];

    // check whether both size and rounding radius are 
    _is_non_uniform = __is_non_uniform || (_round_r[0] != _round_r[1]) || (_round_r[1] != _round_r[2]);

    // construct _size aka inner cube size
    __size = sub_vecs(_size, s_vec(2,_round_r));

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

    // produce final product
    if (_is_non_uniform)
    {
        translate(_o)
            rotate(_rot)
                minkowski()
                {   
                    // sphrepp manages possible elipsoid
                    spherepp(r=_round_r);
                    
                    // cylinderpp manages other modifications
                    cylinderpp(size=__size, center=true, __mod_queue=__mod_queue);
                }
    }
    else
    {
        // uniform cylinder
        translate(_o)
        rotate(_rot)
        cylinderpp(d1=__d1, d2=__d2, h=_h, center=true,
                    __mod_queue=__mod_queue, __rotate_extrude=__rotate_extrude)
        {   
            difference()
            {
                offset(_round_r[0])
                    offset(-_round_r[0])
                        // expland to the left side
                        mirrorpp([1,0,0], true)
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
                        }
                // cut off left half-plane
                squarepp([__d1+__d2, 2*_h], align="X");
            }
        }
    }

}
