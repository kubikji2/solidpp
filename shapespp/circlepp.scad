include<../utils/solidpp_utils.scad>

CIRCLEPP_DEF_ALIGN = "";

// improved version of the circle module
// - argument 'size' defines the size of the bounding box: a number or [x, y] (an ellipse)
// - argument 'r'|'d' defines the radius/diameter: a number or [x, y] (an ellipse)
//   '-> only one of 'size', 'r', 'd' can be used, default size is [1, 1]
// - argument 'align' aligns the bounding box, see README (default: centered)
// - argument 'center' overrides 'align' if true
// - the circle is made with the largest diameter, so $fn/$fa/$fs act as in circle(),
//   an ellipse is that circle scaled down along the other axis
//   '-> as in OpenSCAD, the vertices lie on the circle
module circlepp(size=undef, r=undef, d=undef, align=undef, center=false)
{
    // module name
    __module_name = "CIRCLE++";
    
    // check r and d
    __d = !is_undef(d) ?
            d :
            !is_undef(r) ?
                2*r :
                undef;

    // check mutex group {size, r, }
    assert( is_undef(__d) || is_undef(size),
            str("[", __module_name, "] it is allowed to use only single argument {r,d,size} simulatanously.")
    );

    // check size
    __solidpp__assert_2D_vector_like(size, "size", __module_name);

    // parse size
    __size = __solidpp__get_argument_as_2Dlist(size, [1,1]);
    
    // create size
    _size = !is_undef(__d) ?
                (is_num(__d) ? [__d, __d] : __d) :
                __size;

    assert(is_list(_size) && len(_size) == 2 && is_num(_size[0]) && is_num(_size[1]) &&
           _size[0] > 0 && _size[1] > 0,
        str("[", __module_name, "] the size must be a positive number or a list of 2 positive numbers, got ", _size));
    
    // process the align and center to produce offset   
    // '-> arguments 'align' and 'center' are checked within the function
    __o = __solidpp__produce_offset_from_align_and_center(
            _size=[each _size,0],
            align=align,
            center=center,
            solidpp_name=__module_name,
            def_align=CIRCLEPP_DEF_ALIGN);

    // throw away z-axis
    _o = [__o[0], __o[1]];
    
    // construct the solid
    // '-> circle of the largest diameter (fragments computed from the real radius),
    //     scaled down along the other axis for an ellipse
    _D = max(_size);

    translate(_o)
        scale([_size[0]/_D, _size[1]/_D])
            circle(d=_D);
}