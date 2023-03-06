include<../utils/solidpp_utils.scad>
include<../utils/__toroidpp_utils.scad>

// TODO might not needed
assert(!is_undef(__DEF_CYLINDERPP__), "[TUBE++] cylinder.scad must be included!");

TUBEPP_DEF_ALIGN="z";

module tubepp(  size=undef, t=undef, r=undef, d=undef, R=undef, D=undef, h=undef, center=false,
                align=undef, zet="z", mod_list=undef, inner_mod_list=undef, outer_mod_list=undef)
{

    // module name
    __module_name = "TUBEPP";

    __h = is_undef(h) ? 1 : h;

    // checking and processing toroidpp parameters
    parsed_data = __solidpp__toroidpp__check_parameters(
                        module_name=__module_name, t=t, r=r, d=d, R=R, D=D, h=__h);
    _r = parsed_data[0];
    _R = parsed_data[1];
    //_t = parsed_data[2];
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
            def_align=TUBEPP_DEF_ALIGN);
      
    // construct rotation
    _rot = __solidpp__get_rotation_from_zet(zet,[0,0,0]);

    translate(_o)
    rotate(_rot)
    difference()
    {
        cylinderpp(r=_R, h=_h, center=true);

        // eps affects only preview
        _eps = $preview ? 0.0001 : 0;
        cylinderpp(r=_r, h=_h+_eps, center=true);

    }

}