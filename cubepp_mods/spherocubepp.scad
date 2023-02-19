
include<../utils/vector_operations.scad>
include<../cubepp.scad>
include<../spherepp.scad>

module spherocubepp(size=undef, r=undef, d=undef, align=undef, zet=undef, center=false)
{

    // set module name
    __module_name = "SPHEROCUBE++";

    // check size
    // '-> it is either undef, vector 3D, or scalar
    __solidpp__assert_size_like(size, "size" , __module_name);
    
    // define __size aka parsed size
    // '-> if undef use default size
    // '-> if list, keep it
    // '-> if number, fill array
    __size = __solidpp__get_argument_as_3Dlist(size,[1,1,1]);

    // check r
    // '-> it is either undef, vector 3D, or scalar
    __solidpp__assert_size_like(r, "r" , __module_name);

    // check d
    // '-> it is either undef, vector 3D, or scalar
    __solidpp__assert_size_like(d, "d" , __module_name);

    // construct _r
    _r = !is_undef(d) ?
            s_vec(0.5,__solidpp__get_argument_as_3Dlist(d)) :
            __solidpp__get_argument_as_3Dlist(r,[0.1,0.1,0.1]);
    
    // construct _size aka inner cube size
    _size = sub_vecs(__size, s_vec(2,_r));

    echo(size);
    echo(_size);

    // check _size for negative elements
    assert(
            is_vector_non_negative(_size),
            str("[",__module_name,"] argument 'size' must be at least equal to the 'r|d' in each axis.")
            );

    // process the align and center to produce offset
    // '-> arguments 'align' and 'center' are checked within the function
    _o = __solidpp__produce_offset_from_align_and_center(
            _size=__size,
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
            cubepp(size=_size, center=true);
        }
    
}
