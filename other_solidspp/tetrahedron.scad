
// tetrahedron
// '-> requires four 3D points to be constructed
//     '-> points[0:2] creates the base according the right-hand rule
//     '-> fourth point is above the base
module tetrahedron(points=undef)
{

    // module name
    __module_name = "TETRAHEDRON++";

    // check we have four points
    assert(
            is_list(points) && len(points) == 4,
            str("[", __module_name, "] tetrahedron requires four points, but ", len(points), " were provided!"));   
    
    // check all points are 3D
    for (_point=points)
    {
        assert( 
                is_list(_point) && len(_point) == 3,
                str("[", __module_name, "] some of the points ", _point," are not 3D!")
                );
    }

    // TODO handle self-intersection

    // compose points
    _points = points;
    // compose facets
    _facets = [
                [0,1,2],
                [3,1,0],
                [3,2,1],
                [3,0,2],
              ];

    // geometry
    polyhedron(_points, _facets);



}