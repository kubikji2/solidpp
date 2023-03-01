include<../utils/vector_operations.scad>
include<../modifiers/__round_corners_modifier.scad>

assert(!is_undef(__DEF_CUBEPP__), "[ROUND-CORNERS-CUBE++] cubepp.scad must be included!");
assert(!is_undef(__DEF_SPHEREPP__), "[ROUND-CORNERS-CUBE++] spherepp.scad must be included!");

module round_corners_cubepp(size=undef, r=undef, d=undef, align=undef, zet=undef, center=false,
mod=undef, __mod_queue = undef)
{

    // set module name
    __module_name = "ROUND-CORNERS-CUBE++";

    // check size
    // '-> it is either undef, vector 3D, or scalar
    __solidpp__assert_size_like(size, "size" , __module_name);
    
    // define __size aka parsed size
    // '-> if undef use default size
    // '-> if list, keep it
    // '-> if number, fill array
    _size = __solidpp__get_argument_as_3Dlist(size,[1,1,1]);

    // check r
    // '-> it is either undef, vector 3D, or scalar
    __solidpp__assert_size_like(r, "r" , __module_name);

    // check d
    // '-> it is either undef, vector 3D, or scalar
    __solidpp__assert_size_like(d, "d" , __module_name);

    // construct _r
    __r = is_undef(r) && is_undef(d) ? 0.1 : r;

    // processing data using the modifier constructor back-end
    parsed_data = !is_undef(mod) ?
                    mod :
                    __solidpp__new_round_corners(r=__r,d=d);

    // check parsed data
    assert(!is_undef(parsed_data[0]), str("[", __module_name, "] ", parsed_data[1], "!"));

    // unpack data
    _r = parsed_data[1];

    // construct _size aka inner cube size
    __size = sub_vecs(_size, s_vec(2,_r));

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
            def_align=CUBEPP_DEF_ALIGN);

    // produce final product
    translate(_o)
        minkowski()
        {   
            // sphrepp manages possible elipsoid
            spherepp(r=_r);
            // cubepp manages alignment and center
            cubepp(size=__size, center=true, __mod_queue=__mod_queue);
        }
    
}
