include<utils/solidpp_utils.scad>

// spherepp default alignment
SPHEREPP_DEF_ALIGN = "c";

// improved version of sphere module
// - argument 'size' defines the size of bounding box
//   '-> it can either be:
//       - list of size 3 containing a numbers only,
//       - a single number denoting all bounding box side sizes
//       - 'undef' (default value) to use default size
//   '-> note that in the first case, the 'size' defines the principal axis lengths
// - argument 'r' defines the sphere radius, or half of the principal axis lengths
//   '-> it can either be:
//       - list of size 3 containing a numbers only,
//       - a single number denoting half of the bounding box side sizes
//       - 'undef' (default value) to use default radius
//   '-> note that using single value results in sphere,
//       using the list of numbers may result in ellipsoid
// - argument 'd' defines the sphere diameter, or the principal axis lengths
//   '-> it can either be:
//       - list of size 3 containing a numbers only,
//       - a single number denoting all bounding box side sizes
//       - 'undef' (default value) to use default diameter
//   '-> note that using single value results in sphere,
//       using the list of numbers may result in ellipsoid
//   '-> note that 'd' and 'size' are functionally same
// - argument 'align' defines the sphere alignment
//   '-> the 'undef' (default value) results in ordinary alignment
//   '-> if 'align' is a string, then following rules are applied:
//       1. If 'align' contains a small letter 'x'/'y'/'z'
//          the solid is aligned such that the bounding box is 
//          touching the origin from the 'right'/'back'/'top' respectively.
//       2. If 'align' contains a capital letter 'X'/'Y'/'Z'
//          the solid is aligned such that its bounding box is
//          touching the origin from the 'left'/'front'/'bottom' respectively.
//       3. If 'align' contains neither ('x' nor 'X')/('y' nor 'Y')/('z' nor 'Z'),
//          then the bounding box is centered in the 'x'/'y'/'z'-axis respectively.
//       4. The rules 1.-3. can be combined.
//       Note that other cases (an empty string or string containing only other letters)
//            restult in the centering along all axis and are equivalent to the `center=true`.
//       Note that the rules are applied for each axis sequentially.
//            Therefore, for example strings containing both 'x' and 'X' will result in alignment
//            according the first rule.
// - argument 'zet' is ignored for this module
// - argument 'center' is a bool and has no significance other then overriding any alignment
//   '-> note that 'center=true' overrides any 'align'
module spherepp(size=undef, r=undef, d=undef, align=undef, zet=undef, center=false)
{
    __module_name = "SPHEREPP";

    // check r and d
    assert(!is_undef(r) || !is_num(d), "[SPHEREPP] defining both 'd' and 'r' is not permitted!");

    // check r
    // '-> undef, scalar, or list of size 3
    __solidpp__assert_size_like(r, "r" , __module_name);
    _r = __solidpp__get_argument_as_3Dlist(r,undef);
    
    // check d
    // '-> undef, scalar, or list of size 3
    __solidpp__assert_size_like(d, "d" , __module_name);
    _d = __solidpp__get_argument_as_3Dlist(d,undef);
    
    // check size
    // '-> undef, scalar, or list of size 3
    __solidpp__assert_size_like(size, "size" , __module_name);
    __size = __solidpp__get_argument_as_3Dlist(size, undef);

    // construct size
    _size = !is_undef(__size) ?
                __size :
                !is_undef(_r) ?
                    [ for (ri=_r) 2*ri] :
                    !is_undef(_d) ?
                        _d :
                        [1,1,1];
    
    // process the align and center to produce offset   
    // '-> arguments 'align' and 'center' are checked within the function
    _o = __solidpp__produce_offset_from_align_and_center(
            _size=_size,
            align=align,
            center=center,
            solidpp_name=__module_name,
            def_align=SPHEREPP_DEF_ALIGN);

    // construct the solid
    translate(_o)
        resize(_size)
            sphere(d=1);
}

// defining the sphere
__DEF_SPHEREPP__ = true;
