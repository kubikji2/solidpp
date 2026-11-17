include<../utils/solidpp_utils.scad>
include<../engine/revolved.scad>
//include<../utils/vector_operations.scad>


module __spp__replicate_at__check_axis(axis, name)
{
    assert( is_undef(axis) || is_num(axis) || __solidpp__is_list_of_numbers(axis),
            str("[REPLICATE-AT] arguemnt '",name,"' must be either number or a list of numbers!"));
}

function __spp__replicate_at__expand_axis(axis) =
    is_undef(axis) ?
        [0] :
        is_num(axis) ?
            [axis] :
            axis;

// places copies of the children at the given positions/rotations
// - argument 'pos' list of positions [[x, y, z], ...]
// - argument 'rot' list of rotations [[ax, ay, az], ...] (applied before the translation)
//   '-> with both, they pair up by index (same length)
// - arguments 'x', 'y', 'z' a number or a list of numbers: a grid of all combinations
//   (instead of 'pos'; a missing axis is 0), ordered x, then y, then z
// - special variables in the children:
//   '-> $idx  index of the copy (0, 1, ...)
//   '-> $pos  its position, $rot its rotation
// e.g. replicate_at(x=[-20, 20], y=[-10, 10]) cylinderpp(d=3, h=10);
module replicate_at(pos=undef, rot=undef, x=undef, y=undef, z=undef)
{

    __module_name = "REPLICATE-AT";

    // check whether any of x/y/z argument is defined
    _any_xyzs = !is_undef(x) || !is_undef(y) || !is_undef(z);

    // check whether enough argument is defined
    assert(!is_undef(pos) || !is_undef(rot) || _any_xyzs ,
            str("[", __module_name ,"] at least one argument 'pos' or 'rot' must be defined or 'x','y','z' must be used!"));
    
    // check 'pos' and 'x','y','z' argument exclusivity
    assert(is_undef(pos) || !_any_xyzs,
            str("[", __module_name, "] 'pos' and 'x','y','z' cannot be combined!"));

    // check 'pos' dimensions
    assert(is_undef(pos) || __solidpp__check_list_of_vectors(pos, 3),
            str("[", __module_name, "] argument 'pos' must be a list of vector 3D!" )); 

    // check 'rot' dimensions
    assert(is_undef(rot) || __solidpp__check_list_of_vectors(rot, 3),
            str("[", __module_name, "] argument 'rot' must be a list of vector 3D!" ));

    // check 'x', 'y' and 'z' arguments
    __spp__replicate_at__check_axis(x,"x");
    __spp__replicate_at__check_axis(y,"y");
    __spp__replicate_at__check_axis(z,"z");
    
    // expand 'x', 'y', 'z' arguments if present
    _x = _any_xyzs ? __spp__replicate_at__expand_axis(x) : undef;
    _y = _any_xyzs ? __spp__replicate_at__expand_axis(y) : undef;
    _z = _any_xyzs ? __spp__replicate_at__expand_axis(z) : undef;   

    // define positions
    _pos = !is_undef(pos) ?
            pos :
            _any_xyzs ?
                [ for(xx=_x) for(yy=_y) for(zz=_z) [xx,yy,zz]] :
                [ for(i=[0:len(rot)-1]) [0,0,0]];

    // define rotations
    _rot = is_undef(rot) ? [ for(i=[0:len(_pos)-1]) [0,0,0] ] : rot;    
    
    // assert lengths
    assert(len(_pos) == len(_rot),
            str("[", __module_name, "] length of 'rot' and 'pos'/'x','y','z' are not same!" ));

    // replicate
    for (i=[0:len(_pos)-1])
    {
        $idx = i;
        $pos = _pos[i];
        $rot = _rot[i];
        translate(_pos[i])
            rotate(_rot[i])
                children();
    }


}


// polar array: copies of the children around the axis 'zet'
// - argument 'n' number of copies
// - argument 'r' radius (distance from the axis, default 0)
// - argument 'angle' angle covered (default 360: the copies spread evenly around; otherwise the
//   first copy at 'start' and the last one at 'start' + 'angle')
// - argument 'start' angle of the first copy (default 0)
//   '-> angles as for 'sector': counter-clockwise around 'zet' (right-hand rule), 0 is +x for zet "z",
//       +y for zet "x", +z for zet "y"
// - argument 'zet' the axis: "x", "y" or "z" (default)
// - argument 'orient' if true (default), every copy is turned by its angle (spokes), otherwise only
//   moved
// - argument 'point' a point of the axis (default: the origin)
// - special variables in the children: $idx (index of the copy), $angle (its angle)
// e.g. replicate_around(6, r=20) cylinderpp(d=3.2, h=10);  // bolt circle
module replicate_around(n, r=0, angle=360, start=0, zet=undef, orient=true, point=undef)
{
    __module_name = "REPLICATE-AROUND";

    assert(is_num(n) && n >= 1 && n == round(n),
        str("[", __module_name, "] argument 'n' must be a positive integer, got ", n));
    assert(is_num(r) && r >= 0, str("[", __module_name, "] argument 'r' must be a non-negative number, got ", r));
    assert(is_num(angle) && angle > 0 && angle <= 360,
        str("[", __module_name, "] argument 'angle' must be in (0, 360], got ", angle));
    assert(is_num(start), str("[", __module_name, "] argument 'start' must be a number, got ", start));
    assert(is_bool(orient), str("[", __module_name, "] argument 'orient' must be a boolean, got ", orient));
    assert(is_undef(point) || __solidpp__is_list_of_numbers(point) && len(point) == 3,
        str("[", __module_name, "] argument 'point' must be a point [x, y, z], got ", point));

    _zet = __spp_check_zet(zet, __module_name);
    _axis = __solidpp__get_normal_from_zet(_zet);
    _p = is_undef(point) ? [0, 0, 0] : point;
    _step = angle == 360 ? 360 / n : (n == 1 ? 0 : angle / (n - 1));

    for (i = [0:1:n-1])
    {
        $idx = i;
        $angle = start + i*_step;
        translate(_p + r * __spp_around_dir(_zet, $angle))
            if (orient)
                rotate(a=$angle, v=_axis)
                    children();
            else
                children();
    }
}

// direction of the angle 'a' around the axis 'zet' (0: +x for z, +y for x, +z for y)
function __spp_around_dir(zet, a) =
    zet == "x" || zet == "X" ? [0, cos(a), sin(a)] :
    zet == "y" || zet == "Y" ? [sin(a), 0, cos(a)] :
                               [cos(a), sin(a), 0];
