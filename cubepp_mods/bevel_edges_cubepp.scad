include<../modifiers/__bevel_edges_modifier.scad>
include<../transforms/replicate.scad>
include<../other_solidspp/prism.scad>
include<../transforms/mirrorpp.scad>
include<../utils/vector_operations.scad>

assert(!is_undef(__DEF_CUBEPP__), "[BEVEL-EDGES-CUBE++] cubepp.scad must be included!");

module bevel_edges_cubepp(size=undef, bevel=undef, axes=undef, align=undef, zet=undef, center=false,
    mod=undef, __mod_queue = undef)
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
    _size = __solidpp__get_argument_as_3Dlist(size,[1,1,1]);

    // define _bevel as 3D vector
    // '-> if undef use default bevel
    // '-> if list, keep it
    // '-> if number, fill array
    _bevel = is_undef(bevel) ? 0.1 : bevel;

    // define axes
    _axes = is_undef(axes) ? "xyz" : axes;

    // TODO check mod
    
    // TODO check both mod and bevel

    // processing data using the modifier constructor back-end
    parsed_data = !is_undef(mod) ?
                    mod :
                    __solidpp__new_bevel_edges(
                        bevel=_bevel,
                        axes=_axes);

    // check parsed data
    assert(!is_undef(parsed_data[0]), str("[", __module_name, "] ", parsed_data[1], "!"));
    
    // extracting data
    _mask = parsed_data[__BEVEL_EDGES_MASKS_IDX];
    _bevel_sizes = parsed_data[__BEVEL_EDGES_BEVEL_IDX]; 

    _rem_size = sub_vecs(_size, scale_vec(2,_bevel_sizes));
    
    assert(is_vector_non_negative(_rem_size),
            str("[", __module_name, "] 'bevel' cannot exceed half of the 'size'!"));
    
    // extracting bevel
    _bx = _bevel_sizes.x;
    _by = _bevel_sizes.y;
    _bz = _bevel_sizes.z;

    // extracting size
    _x = _size.x;
    _y = _size.y;
    _z = _size.z;

    // process the align and center to produce offset
    // '-> arguments 'align' and 'center' are checked within the function
    _o = __solidpp__produce_offset_from_align_and_center(
            _size=_size,
            align=align,
            center=center,
            solidpp_name=__module_name,
            def_align=CUBEPP_DEF_ALIGN);
    
    // construct the solid
    translate(_o)
    difference()
    {
        // basic shape
        cubepp([_x,_y,_z], center=true, __mod_queue=__mod_queue);

        // prism transform
        eps = 0.0001;
        _tf = [-_x/2-eps, -_y/2-eps, -_z/2-eps];

        // xy-plane cut
        render(4)
        if (_mask.x)
        {
            // prism base points
            _pts =  [
                        [   0,   0,   0],
                        [ _bx,   0,   0],
                        [   0, _by,   0]
                    ];
            // prism normal
            _n = [0,0,_z+2*eps];

            // mirror-clonining prism
            mirrorpp([1,0,0],true)
                mirrorpp([0,1,0],true)
                    translate(_tf)
                        prism(points=_pts,n=_n);
            
        };

        // xz-place cut
        render(4)
        if (_mask.y)
        {
            // prism base points
            _pts =  [
                        [   0,  0,   0],
                        [ _bx,  0,   0],
                        [   0,  0, _bz]
                    ];
            // prism normal
            _n = [0,_y+2*eps,0];

            // mirror-clonining prism
            mirrorpp([1,0,0],true)
                mirrorpp([0,0,1],true)
                    translate(_tf)
                        prism(points=_pts,n=_n);
        }

        // yz-plane cut
        render(4)
        if (_mask.z)
        {
            // prism base points
            _pts =  [
                        [   0,   0,   0],
                        [   0,   0, _bz],
                        [   0, _by,   0]
                    ];
            // prism normal
            _n = [_x+2*eps,0,0];

            // mirror-clonining prism
            mirrorpp([0,1,0],true)
                mirrorpp([0,0,1],true)
                    translate(_tf)
                        prism(points=_pts,n=_n);
        }

    }

}