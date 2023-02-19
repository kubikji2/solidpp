include<../utils/vector_operations.scad>
include<../other_solidspp/tetrahedron.scad>
include<../cubepp.scad>

// module used to cut corners
module __spp__compose_corner_cut(points, offs, h)
{
    for(i=[0:3])
    {
        // select point oposite to the leftout corner
        _peak_idx = (i+2)%4;
        // move peak point to by "h" in z-axis
        _peak_point = add_vecs(points[_peak_idx],[0,0,h]);
        // different order is used to handle normals
        _points = h > 0 ? 
                    [for(j=[0:3]) if (j != i) points[j], _peak_point] :
                    [_peak_point, for(j=[0:3]) if (j != i) points[j]];

        // geometry
        translate(offs[i])
            tetrahedron(points=_points);
    }
}

// TODO add readme
module bevel_corners_cubepp(size=undef, cut=undef, align=undef, zet=undef, center=false)
{

    // set module name
    __module_name = "BEVELED-CORNERS-CUBE++";

    // check size
    // '-> it is either undef, vector 3D, or scalar
    __solidpp__assert_size_like(size, "size" , __module_name);
    
    // define _size aka parsed size
    // '-> if undef use default size
    // '-> if list, keep it
    // '-> if number, fill array
    _size = __solidpp__get_argument_as_3Dlist(size,[1,1,1]);

    // check cut
    // '-> it is either undef, vector 3D, or scalar
    __solidpp__assert_size_like(cut, "cut" , __module_name);

    // define _cut as 3D vector
    // '-> if undef use default cut
    // '-> if list, keep it
    // '-> if number, fill array
    _cut = __solidpp__get_argument_as_3Dlist(cut,[0.1,0.1,0.1]);

    // cut must be positive
    assert(
            is_vector_positive(_cut),
            str("[",__module_name,"] argument 'cut' canot contain negative numvers!")
            );

    // expand size
    _x = _size.x;
    _y = _size.y;
    _z = _size.z;

    // expand cut
    _cx = _cut.x;
    _cy = _cut.y;
    _cz = _cut.z;

    // compose cuts coordinates and its offsets
    eps = 0.0001;
    __xy_cuts = [
                [   -eps,    -eps, -eps],
                [_cx+eps,    -eps, -eps],
                [_cx+eps, _cy+eps, -eps],
                [   -eps, _cy+eps, -eps]        
               ];
    _xy_cuts = [for(_point=__xy_cuts) add_vecs(_point, [-_x/2,-_y/2,-_z/2])];

    _xy_offs = [
                [_x-_cx, _y-_cy, 0],
                [     0, _y-_cy, 0],
                [     0,      0, 0],
                [_x-_cx,      0, 0],
               ];

    echo(_xy_offs);
    // translate the coordinates and offsets for the top face
    _xy_offs_tops = [for(_point=_xy_offs) add_vecs(_point,[0, 0, 0])];
    _xy_cuts_tops = [for(_point=_xy_cuts) add_vecs(_point,[0, 0, _z+2*eps])];

    // process the align and center to produce offset
    // '-> arguments 'align' and 'center' are checked within the function
    _o = __solidpp__produce_offset_from_align_and_center(
            _size=__size,
            align=align,
            center=center,
            solidpp_name=__module_name,
            def_align=CUBEPP_DEF_ALIGN);

    // construct the goemetry
    translate(_o)
    difference()
    {
        // basic shape
        cubepp([_x,_y,_z], center=true);
        // lower cuts
        #__spp__compose_corner_cut(points=_xy_cuts,offs=_xy_offs,h=_cz+eps);
        // upper cuts
        #__spp__compose_corner_cut(points=_xy_cuts_tops,offs=_xy_offs_tops,h=-_cz-eps);
    }
    
}