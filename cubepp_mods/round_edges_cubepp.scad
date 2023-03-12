include<../modifiers/__round_edges_modifier.scad>
include<../utils/vector_operations.scad>
include<../transforms/mirrorpp.scad>
include<../transforms/transform_if.scad>

assert(!is_undef(__DEF_CUBEPP__), "[ROUND-EDGES-CUBE++] cubepp.scad must be included!");
assert(!is_undef(__DEF_SPHEREPP__), "[ROUND-EDGES-CUBE++] spherepp.scad must be included!");
assert(!is_undef(__DEF_CYLINDERPP__), "[ROUND-EDGES-CUBE++] cylinderpp.scad must be included!");


// TODO add readme
module round_edges_cubepp(size=undef, r=undef, d=undef, axes=undef, align=undef, zet=undef, center=false,
mod=undef, __mod_queue = undef)
{
    // set module name
    __module_name = "ROUND-EDGES-CUBE++";

    // check size
    // '-> it is either undef, vector 3D, or scalar
    __solidpp__assert_size_like(size, "size" , __module_name);
    
    // define _size aka parsed size
    // '-> if undef use default size
    // '-> if list, keep it
    // '-> if number, fill array
    _size = __solidpp__get_argument_as_3Dlist(size,[1,1,1]);

    __r = (is_undef(r) && is_undef(d)) ?
            0.1 :
            r;

    // define axes
    _axes = is_undef(axes) ? "xy" : axes;

    // TODO check mod
    
    // TODO check both mod and r or d or axes

    // processing data using the modifier constructor back-end
    parsed_data =!is_undef(mod) ?
                    mod :
                    __solidpp__new_round_edges(
                        r=__r,
                        d=d,
                        axes=_axes);

    // check parsed data
    assert(!is_undef(parsed_data[0]), str("[", __module_name, "] ", parsed_data[1], "!"));
        
    // extracting data
    _mask = parsed_data[__ROUND_EDGES_MASKS_IDX];
    _r = parsed_data[__ROUND_EDGES_RADIUS_IDX];

    // extracting bevel
    _rx = _r.x;
    _ry = _r.y;
    _rz = _r.z;

    // extracting outer size
    _x = _size.x;
    _y = _size.y;
    _z = _size.z;

    // construct _size aka inner cube size
    __size = sub_vecs(_size, s_vec(2,_r));

    // check _size for negative elements
    assert(
            is_vector_non_negative(__size),
            str("[",__module_name,"] argument 'size' must be at least equal to the 'r'|'d' in each axis.")
            );

    // extracting inner size
    __x = __size.x;
    __y = __size.y;
    __z = __size.z;

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
    {
        // transformation to the cube corner
        _tf = [-_x/2, -_y/2, -_z/2];

        // count number of mask entries
        mask_cnt = vec_sum([for(b=_mask) b ? 1 : 0]);

        if (mask_cnt == 3 || mask_cnt == 2)
        {   

            difference()
            {
                // master cubepp that is used to propagate the modifiers
                cubepp(_size, center=true, __mod_queue=__mod_queue);

                // creating the cut
                difference()
                {   
                    // cube a bit larger then the main create form
                    cubepp(scale_vec(_size,1.1), center=true);

                    // original shape of the cube
                    // '-> there is no way how to propagate mod queue
                    
                    // make convex hull if mask_cnt is two (e.g. single axix in 'axes') 
                    hull_if(mask_cnt==2)
                    {
                        
                        minkowski()
                        {
                            cubepp(__size, center=true);
                            spherepp(size=[2*_rx, 2*_ry, 2*_rz]);
                        }

                        // if mask_cnt is two (e.g. single axix in 'axes')
                        // add the cube
                        if (mask_cnt==2)
                        {
                            // placing cube in xy-plane
                            if(!_mask.x)
                            {
                                cubepp([_x,_y,__z], center=true);
                            }

                            // placing cube in xz-plane
                            if (!_mask.y)
                            {
                                cubepp([_x,__y,_z], center=true);
                            }

                            // placing cube in yz-plane
                            if (!_mask.z)
                            {
                                cubepp([__x,_y,_z], center=true);
                            }
                        }
                    }
                }
            }
            
        }
        else
        {
            // if mask_cnt is one, therefore 'cylindrocube is created

            // left right
            cubepp([_x, __y, __z],center=true);
        
            // front back
            cubepp([__x, _y, __z],center=true);

            // top bottom
            cubepp([__x, __y, _z],center=true);

            // xy-plane cut
            if (_mask.x)
            {
                // mirror-clonining prism
                mirrorpp([1,0,0],true)
                    mirrorpp([0,1,0],true)
                        translate([-_x/2,-_y/2,0])
                            cylinderpp(size=[2*_rx,2*_ry,__z],align="xy");
            }                

            // xz-place cut
            if (_mask.y)
            {
                // mirror-clonining prism
                mirrorpp([1,0,0],true)
                    mirrorpp([0,0,1],true)
                        translate([-_x/2,0,-_z/2])
                            cylinderpp(size=[2*_rx,__y,2*_rz],align="xz",zet="y");
            }

            // yz-plane cut
            if (_mask.z)
            {
                // mirror-clonining prism
                mirrorpp([0,1,0],true)
                    mirrorpp([0,0,1],true)
                        translate([0,-_y/2,-_z/2])
                            cylinderpp(size=[__x,2*_ry,2*_rz],align="yz",zet="x");
            }          
        }
    }
}