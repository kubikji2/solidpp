include<../utils/solidpp_utils.scad>
include<../utils/__toroidpp_utils.scad>
include<../shapespp/circlepp.scad>
include<../shapespp/squarepp.scad>

assert(!is_undef(__DEF_TUBEPP__), "[ROUND-BASES-TUBE++] tubepp.scad must be included!");
assert(!is_undef(__DEF_CYLINDERPP__), "[ROUND-BASES-TUBE++] cylinderpp.scad must be included!");

module round_bases_tubepp(  size=undef, t=undef, r=undef, d=undef, R=undef, D=undef, h=undef,
                center=false, align=undef, zet="z",
                r_both=undef, d_both=undef, r_top=undef,
                d_top=undef, r_bottom=undef, d_bottom=undef,
                mod=undef, __mod_queue=undef, inner_mod_list=undef, outer_mod_list=undef)
{
    // module name
    __module_name = "ROUND-BASES-TUBE++";

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
            str("[", __module_name, "] arguments 'zet' is eithter 'undef' or a string!"));

    _size = __solidpp__construct_cylinderpp_size(d=2*_R,h=_h, zet=zet);

    // bevel base oriented parsing

    // TODO check mod
    
    // TODO check both mod and bevel, axis, bevel_bottom, bevel_top

    // handling default bevel
    _round_r =  !is_undef(r_both) || !is_undef(d_both) || !is_undef(r_top) ||
                !is_undef(d_top) || !is_undef(r_bottom) || !is_undef(d_bottom)? 
                    r_both :
                    0.1;

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
    _b_r = _r_bottom[0];
    _b_h = _r_bottom[1];
    _t_r = _r_top[0];
    _t_h = _r_top[1];

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

        // top rounding
        if (_t_h > 0)
        {

            _area_size = [2*_R, 2*_R, _t_h];
            _diff_size = scale_vec(1.1, _area_size);

            // transform to the top of the bounding box cube
            transform_to_spp([2*_R, 2*_R, _h],"",pos="Z")
            difference()
            {
                transform_to_spp(_area_size, align="Z",pos="z")                    
                    cylinderpp(_diff_size, align="z");
                
                // get the inner ring to be rounded
                _rr_t = _t - 2* _t_r;
                _rr_r = _r + _t_r;

                if (_rr_t >= 0)
                {
                    // torus and minkowski
                    rotate_extrude()
                    {
                        translate([_rr_r,0])
                            circlepp([2*_t_r,2*_t_h],align="Y");
                        if (_rr_t > 0)
                        {
                            translate([_rr_r,0])
                                squarepp([_rr_t,2*_t_h], align="xY");
                            translate([_rr_r+_rr_t,0])
                                circlepp([2*_t_r,2*_t_h], align="Y");
                        }
                    }
                }
            }            
        }

        // bottom rounding
        if (_b_h > 0)
        {
            _area_size = [2*_R, 2*_R, _b_h];
            _diff_size = scale_vec(1.1, _area_size);

            // transform to the top of the bounding box cube
            transform_to_spp([2*_R, 2*_R, _h],"",pos="z")
            difference()
            {
                transform_to_spp(_area_size, align="z",pos="Z")                    
                    cylinderpp(_diff_size, align="Z");
                
                // get the inner ring to be rounded
                _rr_t = _t - 2* _b_r;
                _rr_r = _r + _b_r;

                if (_rr_t >= 0)
                {
                    // torus and minkowski
                    rotate_extrude()
                    {
                        translate([_rr_r,0])
                            circlepp([2*_b_r,2*_b_h],align="y");
                        if (_rr_t > 0)
                        {
                            translate([_rr_r,0])
                                squarepp([_rr_t,2*_b_h], align="xy");
                            translate([_rr_r+_rr_t,0])
                                circlepp([2*_b_r,2*_b_h], align="y");
                        }
                    }
                }
            }    
        }

    }
}