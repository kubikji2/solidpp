include<../utils/solidpp_utils.scad>

// TODO documentation
module trapezoid(base=undef, top=undef, h=undef, align=undef, zet=undef, center=false)
{

    // module name
    __module_name = "TRAPEZOID";

    // check base
    __solidpp__assert_2D_vector_like(base, "base" , __module_name);
 
    // extract base
    _base = __solidpp__get_argument_as_2Dlist(base,[1,1]);

    // check top
    __solidpp__assert_2D_vector_like(top, "top" , __module_name);

    // extract top
    _top = __solidpp__get_argument_as_2Dlist(top,[0.5,0.5]);

    // check h
    assert(is_undef(h) || is_num(h), str("[", __module_name, "] argument 'h' must be either 'undef' or a number.") );

    // extract h
    _h = is_undef(h) ? 1 : h;

    // create bounding box
    _size = [ max(_base.x, _top.x), max(_base.y, _top.y), _h ];

    // compute top and down offsets
    _tx2 = _top.x/2;
    _ty2 = _top.y/2;

    _bx2 = _base.x/2;
    _by2 = _base.y/2;

    _h2 = _h/2;

    // creating geometry
    // inspired by: https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Primitive_Solids#polyhedron
    _points = [
                [ -_bx2, -_by2, -_h2],
                [ +_bx2, -_by2, -_h2],
                [ +_bx2, +_by2, -_h2],
                [ -_bx2, +_by2, -_h2],
                [ -_tx2, -_ty2, +_h2],
                [ +_tx2, -_ty2, +_h2],
                [ +_tx2, +_ty2, +_h2],
                [ -_tx2, +_ty2, +_h2]
              ];
    _facets = [
                [0,1,2,3],  // bottom
                [4,5,1,0],  // front
                [7,6,5,4],  // top
                [5,6,2,1],  // right
                [6,7,3,2],  // back
                [7,4,0,3]   // left
              ];

    // process the align and center to produce offset
    // '-> arguments 'align' and 'center' are checked within the function
    _o = __solidpp__produce_offset_from_align_and_center(
            _size=_size,
            align=align,
            center=center,
            solidpp_name=__module_name,
            def_align=CUBEPP_DEF_ALIGN);

    // get rotation
    _r = __solidpp__get_rotation_from_zet(zet,[0,0,0]);

    // create polyhedron
    translate(_o)
        rotate(_r)
            polyhedron(_points,_facets);
    
}