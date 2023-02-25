

module bevel_edges_cubepp(size=undef, bevel=undef, axes=undef, align=undef, zet=undef, center=false)
{

    // set module name
    __module_name = "BEVEL-EDGES-CUBE++";

    // check size
    // '-> it is either undef, vector 3D, or scalar
    __solidpp__assert_size_like(size, "size" , __module_name);
    
    // define _size aka parsed size
    // '-> if undef use default size
    // '-> if list, keep it
    // '-> if number, fill array
    __size = __solidpp__get_argument_as_3Dlist(size,[1,1,1]);

    // check bevel
    // '-> it is either undef, vector 3D, or scalar
    __solidpp__assert_size_like(bevel, "bevel" , __module_name);

    // define _bevel as 3D vector
    // '-> if undef use default bevel
    // '-> if list, keep it
    // '-> if number, fill array
    _bevel = __solidpp__get_argument_as_3Dlist(bevel,[0.1,0.1,0.1]);

    // bevel must be positive
    assert(
            is_vector_positive(_bevel),
            str("[",__module_name,"] argument 'bevel' canot contain negative numvers!")
            );    

    // define axes
    _axes = is_undef(axes) ? "" : axes;


    // processing data using the modifier constructor back-end
    parsed_data = __solidpp__new_bevel_edges(
                        bevel=_bevel,
                        axis=_zet,
                        bevel_bottom=bevel_bottom,
                        bevel_top=bevel_top);

    // check parsed data
    assert(!is_undef(parsed_data[0]), str("[", __module_name, "] ", parsed_data[1], "!"));

}