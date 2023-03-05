include<../modifiers/__bevel_bases_modifier.scad>
include<../utils/solidpp_utils.scad>
include<../utils/vector_operations.scad>
include<../other_solidspp/trapezoidpp.scad>
include<../transforms/transform_to_spp.scad>
include<../debug/coordinate_frame.scad>

assert(!is_undef(__DEF_CUBEPP__), "[BEVEL-BASES-CUBE++] cubepp.scad must be included!");

function __spp__bevel_base_get_trapezioid_alignment(zet, lower) =
    zet == "X" || zet == "x" ?
        (lower ? "x" : "X") :
            zet == "Y" || zet == "y" ?
                (lower ? "y" : "Y") :
                (lower ? "z" : "Z");

// get parameters from the data stored in the 'struct' based on the 'zet'
// '-> returns 'default_value' upon error
// '-> otherwise return a, b, and h 
function __spp__get_params_from_data_and_zet(data, zet, default_value) =
    is_undef(zet) ?
        default_value :
        zet == "x" || zet == "X" ?
            [data[2], data[1], data[0]] :
            zet == "y" || zet == "Y" ?
                [data[0], data[2], data[1]] :
                zet == "z" || zet == "Z" ?
                    data :
                    default_value;


// TODO documentation
module bevel_bases_cubepp(size=undef, bevel=undef, align=undef, zet=undef, center=false,
    bevel_top=undef, bevel_bottom=undef, mod=undef, __mod_queue = undef)
{

    // set module name
    __module_name = "BEVEL-BASE-CUBE++";

    // check size
    // '-> it is either undef, vector 3D, or scalar
    __solidpp__assert_size_like(size, "size" , __module_name);
    
    // define _size aka parsed size
    // '-> if undef use default size
    // '-> if list, keep it
    // '-> if number, fill array
    __size = __solidpp__get_argument_as_3Dlist(size,[1,1,1]);

    // handling default bevel
    _bevel = !is_undef(bevel) || (!is_undef(bevel_top) || !is_undef(bevel_bottom)) ? 
                bevel :
                0.1;

    // handlign default zet
    __zet = is_undef(zet) ? "z" : zet;

    // TODO check mod
    
    // TODO check both mod and bevel, axis, bevel_bottom, bevel_top

    // processing data using the modifier constructor back-end
    parsed_data = !is_undef(mod) ? 
                    mod :
                    __solidpp__new_bevel_bases(
                        bevel=_bevel,
                        axis=__zet,
                        bevel_bottom=bevel_bottom,
                        bevel_top=bevel_top);

    // check parsed data
    assert(!is_undef(parsed_data[0]), str("[", __module_name, "] ", parsed_data[1], "!"));

    // expand data
    _zet = parsed_data[__BEVEL_AXIS_IDX];
    _bevel_bottom = parsed_data[__BEVEL_BASES_BOTTOM_3D_IDX];
    _bevel_top = parsed_data[__BEVEL_BASES_TOP_3D_IDX];

    _mask = __solidpp__get_normal_from_zet(_zet);
    _size_offset = add_vecs(pwm_vecs(_mask, _bevel_top), pwm_vecs(_mask, _bevel_bottom));
    _size = sub_vecs(__size,_size_offset);

    // process the align and center to produce offset
    // '-> arguments 'align' and 'center' are checked within the function
    _o = __solidpp__produce_offset_from_align_and_center(
            _size=__size,
            align=align,
            center=center,
            solidpp_name=__module_name,
            def_align=CUBEPP_DEF_ALIGN);    
    
    // bases shared params
    _shared_params = __spp__get_params_from_data_and_zet(_size, _zet, _size);
    _shared_size = [_shared_params[0], _shared_params[1]];
    // '-> extracing the shared size dimensions

    // bottom base
    _parsed_bottom_params = __spp__get_params_from_data_and_zet(_bevel_bottom, _zet, _bevel_bottom);
    _b_a = _shared_params[0] - 2*_parsed_bottom_params[0];
    _b_b = _shared_params[1] - 2*_parsed_bottom_params[1];
    _b_h = _parsed_bottom_params[2];
    // '-> extracting the parameters

    // top base
    _parsed_top_params = __spp__get_params_from_data_and_zet(_bevel_top, _zet, _bevel_top);
    _t_a = _shared_params[0] - 2*_parsed_top_params[0];
    _t_b = _shared_params[1] - 2*_parsed_top_params[1];
    _t_h = _parsed_top_params[2];
    // '-> extracting the parameters


    translate(_o)
    difference()
    {
        // base cube
        cubepp(__size, center=true, __mod_queue=__mod_queue);

        //_diff_cube = add_vecs([each _shared_size, _t_h],[0.0001,0.0001,0.0001]);

        _r = __solidpp__get_rotation_from_zet(_zet,[0,0,0]);

        rotate(_r)
        {
            // bottom base
            if (_b_h > 0)
            {   
                // trnsform to the bottom of the bounding box cube
                transform_to_spp(__size,"",pos="z")
                difference()
                {
                    _area_size = [__size.x, __size.y, _b_h];
                    _diff_size = scale_vec(1.1,_area_size);
                    // cubepp aligned to the the top of the trapezoid
                    transform_to_spp(_area_size,align="z",pos="Z")                    
                        cubepp(_diff_size, align="Z");
                    trapezoid(base=[_b_a,_b_b], top=_shared_size, h=_b_h, align="z");
                }
            }           
            // top base
            if (_t_h > 0)
            {
                transform_to_spp(__size,"",pos="Z")
                difference()
                {
                    _area_size = [__size.x, __size.y, _t_h];
                    _diff_size = scale_vec(1.1,_area_size);

                    transform_to_spp(_area_size,align="Z",pos="z")                    
                        cubepp(_diff_size, align="z");
                    trapezoid(base=_shared_size, top=[_t_a,_t_b], h=_t_h, align="Z");
                }
            }
            
        }
    }

}