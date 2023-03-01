include<../utils/solidpp_utils.scad>

SQUAREPP_DEF_ALIGN = "xy";

// TODO documentation
module squarepp(size=undef, align=undef, center=false)
{
    // module name
    __module_name = "SQUARE++";

    // check size
    __solidpp__assert_2D_vector_like(size, "size", __module_name);

    // parse size
    _size = __solidpp__get_argument_as_2Dlist(size, [1,1]);
    
    // process the align and center to produce offset   
    // '-> arguments 'align' and 'center' are checked within the function
    __o = __solidpp__produce_offset_from_align_and_center(
            _size=[each _size,0],
            align=align,
            center=center,
            solidpp_name=__module_name,
            def_align=SQUAREPP_DEF_ALIGN);

    // throw away z-axis
    _o = [__o[0], __o[1]];
    
    // construct the solid
    translate(_o)
        resize(_size)
            square(center=true);
}