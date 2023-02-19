include<utils/solidpp_utils.scad>

// cubepp default alignment
CUBEPP_DEF_ALIGN = "xyz";

// improved version of cube module
// - argument 'size' defines the cube size
//   '-> it can either be:
//       - list of size 3 containing a numbers only,
//       - a single number denoting all cube side sizes
//       - 'undef' (default value) to use default size
// - argument 'align' defines the cube alignment
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
// - argument 'center' is a bool and provides backward compatibility with the "cube(center=true)"
//   '-> note that 'center=true' overrides any 'align'
module cubepp(size=undef, align=undef, zet=undef, center=false)
{
    // set module name
    __module_name = "CUBEPP";

    // check size
    // '-> it is either list of nums of size 3, or scalar
    __solidpp__assert_size_like(size, "size" , __module_name);
    
    // define size
    // '-> if undef use default size
    // '-> if list, keep it
    // '-> if number, fill array
    _size = __solidpp__get_argument_as_3Dlist(size,[1,1,1]);

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
        cube(_size, center=true);

}

