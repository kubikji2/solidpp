include<solidpp_utils.scad>

module cubepp(size=undef, align=undef, zet=undef, center=false)
{
    // check size
    // '-> it is either list of nums of size 3, or scalar 
    assert(is_undef(size) || (is_list(size) && len(size) == 3) || (is_num(size)), "[CUBEPP] argument 'size' can be either 'undef', list of numbers of size 3, or a single values!" );
    
    // define size
    // '-> if undef use default size
    // '-> if list, keep it
    // '-> if number, fill array
    _size = is_undef(size) ?
                [1,1,1] :
                is_list(size) ?
                    size :
                    [size,size,size];

    // check align,
    // '-> it is string or undef
    assert(is_undef(align) || is_string(align), "[CUBEPP] arguments 'align' is eithter 'undef' or string!");

    // parse alignment
    // '-> if undef, use default
    _align = is_undef(align) ? "xyz" : align;

    // check center
    // '-> it is just a bool
    assert(is_bool(center), "[CUBEPP] argument 'center' must be bool!");
    _o = center ? [0,0,0] : __solidpp_get_offsets(_size, _align) ;

    // construct the solid
    translate(_o)
        cube(_size, center=true);

}

