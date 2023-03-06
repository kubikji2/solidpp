include<../utils/solidpp_utils.scad>
include<../utils/__toroidpp_utils.scad>
include<../shapespp/circlepp.scad>

TORUSPP_DEF_ALIGN = "";

// TODO documentation
module toruspp(t=undef, r=undef, d=undef, R=undef, D=undef, h=undef, align=undef, zet="z", center=false)
{
    // module name
    __module_name = "TORUSPP";

    // checking and processing toroidpp parameters
    parsed_data = __solidpp__toroidpp__check_parameters(t=t, r=r, d=d, R=R, D=D, h=h);
    _r = parsed_data[0];
    _R = parsed_data[1];
    _t = parsed_data[2];
    _h = parsed_data[3];

    // check zet
    // '-> it is string or undef
    assert(is_undef(zet) || is_string(zet),
            str("[", __module_name, "] arguments 'zet' is eithter 'undef' or a string!"));

    _size = __solidpp__construct_cylinderpp_size(d=2*_R,h=_h, zet=zet);

    // process the align and center to produce offset
    // '-> arguments 'align' and 'center' are checked within the function
    _o = __solidpp__produce_offset_from_align_and_center(
            _size=_size,
            align=align,
            center=center,
            solidpp_name=__module_name,
            def_align=TORUSPP_DEF_ALIGN);
      
    // construct rotation
    _rot = __solidpp__get_rotation_from_zet(zet,[0,0,0]);

    // construct the solid
    translate(_o)
        rotate(_rot)
            rotate_extrude(convexity=4)
                translate([_R-_t,0,0])
                    circlepp([_t, _h],align="x");
}