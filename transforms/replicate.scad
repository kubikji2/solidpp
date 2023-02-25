include<../utils/solidpp_utils.scad>
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

// TODO documentation
// TODO add x_rot, y_rot, z_rot
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
        translate(_pos[i])
            rotate(_rot[i])
                children();
    }


}