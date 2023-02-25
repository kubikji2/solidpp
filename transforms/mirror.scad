include<../utils/vector_operations.scad>

// mirror, but if 'copy' is set to true, keeps the original solid
// '-> argument 'v' is 2D or 3D vector defining the normal of mirror
// '-> copy defines whether the origninal solid is kept (true), or the it is just mirrored (false) 
module mirrorpp(v=undef, copy=false)
{   
    // module name
    __module_name = "MIRROR++";

    // copy must be bool
    assert( is_bool(copy),
            str("[",__module_name, "] argument 'copy' must be boolean!"));

    // argument 'v' is either 3D vector or a 2D vector 
    assert( is_vector_3D(v) || is_vector_2D(v),
            str("[", __module_name, "] argument 'v' must be either vector 2D or vector 3D"));

    // clone if requested
    if (copy) 
    {
        children();
    }
    
    // mirror
    mirror(v)
        children();
}
