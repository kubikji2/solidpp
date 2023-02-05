include<solidpp_utils.scad>

module spherepp(size=undef, r=undef, d=undef, align=undef, zet=undef, center=false)
{
    __module_name = "SPHEREPP";
    // check r
    // '-> undef, scalar, or list of size 3
    __solidpp_assert_size_like(r, "r" , __module_name);
    _r = __solidpp_get_agument_as_3Dlist(r,undef);
    
    // check d
    // '-> undef, scalar, or list of size 3
    __solidpp_assert_size_like(d, "d" , __module_name);
    _d = __solidpp_get_agument_as_3Dlist(d,undef);
    
    // check size
    // '-> undef, scalar, or list of size 3
    __solidpp_assert_size_like(size, "size" , __module_name);
    __size = __solidpp_get_agument_as_3Dlist(size, undef);

    // construct size
    _size = !is_undef(__size) ?
                __size :
                !is_undef(_r) ?
                    [ for (ri=_r) 2*ri] :
                    !is_undef(_d) ?
                        _d :
                        [1,1,1];
    
    // check align
    // '-> it is string or undef
    assert(is_undef(align) || is_string(align), "[SPHEREPP] arguments 'align' is eithter 'undef' or a string!");

    // parse alignment
    // '-> if undef, use default
    _align = is_undef(align) ? "c" : align;

    // check center
    // '-> it is just a bool
    assert(is_bool(center), "[SPHEREPP] argument 'center' must be bool!");
    
    // create offset
    _o = center ? [0,0,0] : __solidpp_get_offsets(_size, _align);

    // construct the solid
    translate(_o)
        resize(_size)
            sphere(d=100);
}
