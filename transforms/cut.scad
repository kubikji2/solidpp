include<../cubepp.scad>


// just a really big number
__solidpp_big_m = 10;

// apply intersection to all children iff needed
module __solidpp__cut_composer(apply_intersection)
{
    if(apply_intersection)
    {
        intersection_for(i=[0:$children-1])
        {
            children(i);
        }
    }
    else
    {
        children();
    }
}


// this module 
module cut(sector, align=undef, zet=undef, size=undef, center=true)
{
    // set module name
    __module_name = "CUT";

    // check sector argument
    assert(
            is_list(sector) && len(sector) == 2,
            str("[", __module_name, "] argument 'sector' must be a vector of size 2!")
    );

    // check the sector values validity
    assert(
            sector[0] < sector[1],
            str("[",__module_name, "] argument minimum sector angle (sector[0]) must be smaller then maximum sector angle (sector[1])!")

    );

    // define size
    // '-> if undef use default size
    // '-> if list, keep it
    // '-> if number, fill array
    _size = __solidpp__get_argument_as_3Dlist(size, [__solidpp_big_m,__solidpp_big_m,__solidpp_big_m]);
    echo(_size);

    // process the align and center to produce offset
    // '-> arguments 'align' and 'center' are checked within the function
    _o = __solidpp__produce_offset_from_align_and_center(
            _size=_size,
            align=align,
            center=center,
            solidpp_name=__module_name,
            def_align="");
    
    // check zet
    // '-> it is string or undef
    assert( is_undef(zet) || is_string(zet),
            str("[", __module_name, "] arguments 'zet' is eithter 'undef' or a string!")
    );

    // construct rotation
    _rot = __solidpp__get_rotation_from_zet(zet,[0,0,0]);
    // construct offsets to compensate for strange behaviour
    // of __solidpp__get_rotation_from_zet, LOL
    _offset_z = _rot==__solidpp__get_rotation_from_zet("x") ? 90 : 0;
    _offset_x = _rot==__solidpp__get_rotation_from_zet("y") ? 180 : 0;

    // parse the sector argument
    _min_s = sector[0];
    _max_s = sector[1];

    // get the maximal sector
    _m = 2*max(_size);

    // constructing geometry
    difference()
    {
        // add children
        children();

        // cut is using constructed sector
        rotate(_rot)                            // rotate it according to the z-axis
            rotate([_offset_x,0,0])             // compensate for strange z-axis
                rotate([0,0,_min_s+_offset_z])  // rotate it to min_angle
                    translate([0,0,-_m/2])      // center it in z-axis
                        rotate_extrude(angle=abs(_max_s-_min_s)) // create cut as cylinder sector
                            polygon([[0,0],[_m,0],[_m,_m], [0,_m]]);
    }
}