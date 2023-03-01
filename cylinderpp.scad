include<utils/solidpp_utils.scad>

// cylinderpp default alignment
CYLINDERPP_DEF_ALIGN = "z";

// single-use function to construct bounding box from the diameter, height and zet
function __solidpp__construct_cylinderpp_size(d,h,zet) =
    is_undef(zet) ?
        [d,d,h] :
        (zet == "x") || (zet == "X") ?
            [h,d,d] :
            (zet == "y") || (zet == "Y") ?
                [d,h,d] :
                [d,d,h];


// improved version of cylinder module
// - argument 'size' defines the size of bounding box
//   '-> it can either be:
//       - list of size 3 containing a numbers only,
//       - a single number denoting all bounding box side sizes
//       - 'undef' (default value) to use default size
//   '-> note that 'size' is mutually exclussive with 'h' and 'r'|'d' arguments, but not 'r1','r2'|'d1','d2'
// - argument 'r' defines the cylinder radius
//   '-> it can either be:
//       - a single number,
//       - 'undef' (default value) to use default radius
//   '-> note that you cannot define both 'r' and 'd'
// - argument 'd' defines the cylinder diameter
//   '-> it can either be:
//       - a single number,
//       - 'undef' (default value) to use default radius
//   '-> note that you cannot define both 'r' and 'd'
// - argument 'align' defines the cylinder alignment
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
// - argument 'zet' defines the orientation of the cylinder
//   '-> the 'undef' (default value) results in ordinary orientation (z-axis)
//   '-> if 'zet' is a string, then following rules are applied:
//       1. if 'zet' is 'x' or 'X', the orientation is along the x-axis
//       2. if 'zet' is 'y' or 'Y', the orientation is along the y-axis
//       in both cases, the base of the cylinder has lower 'x'/'y' value, i.e.
//       - for 'x'/'X' the base is on the 'left'
//       - for 'y'/'Y' the base is on the 'front'
// - argument 'center' is a bool and has no significance other then overriding any alignment
//   '-> note that 'center=true' overrides any 'align'
// - arguments 'r1','r2' and 'd1','d2' defines cylinder base and top radii and diameters respectively
//   '-> all of them are expected to be either 'undef' or a scalar values
//   '-> additional rules
//       - it is forbidden to combine 'r1'/'r2' and 'd2'/'d1'
//       - if 'r1'/'d1' is defined, 'r2'/'d2' must be defined too
//       - is is forbidden to combine 'r' or 'd' with 'ri' or 'di' 
//   '-> note that it is possible to combine 'size' and the 'r1','r2' or 'd1','d2'
//       in this case, the greater facet of the cylinder is resized to fit the bounding box facet
//       and both cylinder facets are squezed according to the bounding box dimensions.
module cylinderpp(size=undef, r=undef, d=undef, h=undef, align=undef, zet=undef, center=false, r1=undef, r2=undef, d1=undef, d2=undef)
{

    __module_name = "CYLINDERPP";

    // h, d|r and size is illegal
    assert(is_undef(size) || (is_undef(r) && is_undef(d) && is_undef(h)) , "[CYLINDERPP] defining both 'size' and ('r'|'d'),'h' is not permited!");

    // check h
    assert(is_undef(h) || is_num(h), "[CYLINDERPP] argument 'h' is either undefined or scalar value!");
    // process heigh
    _h = !is_undef(h) ? h : 1;

    // check r and d
    assert(is_undef(r) || is_num(r), "[CYLINDERPP] argument 'r' is either undefined or scalar value!");
    assert(is_undef(d) || is_num(d), "[CYLINDERPP] argument 'd' is either undefined or scalar value!");
    assert(!is_undef(r) || !is_num(d), "[CYLINDERPP] defining both 'd' and 'r' is not permitted!");
    // process r and d
    _d = !is_undef(d) ?
            d :  
            !is_undef(r) ?
                2*r :
                undef;

    // d1,d2 and r1,r2 must be defined in pairs
    assert(is_undef(d1)==is_undef(d2), "[CYLINDERPP] either none or both arguments 'd1','d2' must be defined!");
    assert(is_undef(r1)==is_undef(r2), "[CYLINDERPP] either none or both arguments 'r1','r2' must be defined!");
    // d1, d2, r1, r2 are either undefined or numbers
    assert(is_undef(r1) || is_num(r1), "[CYLINDERPP] argument 'r1' is either undefined or scalar value!");
    assert(is_undef(d1) || is_num(d1), "[CYLINDERPP] argument 'd1' is either undefined or scalar value!");
    assert(is_undef(r2) || is_num(r2), "[CYLINDERPP] argument 'r2' is either undefined or scalar value!");
    assert(is_undef(d2) || is_num(d2), "[CYLINDERPP] argument 'd2' is either undefined or scalar value!");
    // both r1,r2 and d1,d2 pairs cannod be defined at the same time
    assert(!((!is_undef(d1) && !is_undef(d2)) && (!is_undef(r1) && !is_undef(r2))), "[CYLINDERPP] you cannot define both 'r1','r2' and 'd1','d2'!");
    
    // process r1,r2 or d1,d2 or _d to absolute diameters __d1,__d2
    __d1 = !is_undef(d1) ?
            d1 :
            !is_undef(r1) ?
                2*r1 :
                _d;
    
    __d2 = !is_undef(d2) ?
            d2 :
            !is_undef(r2) ?
                2*r2 :
                _d;
    
    // get maximum of the the diameters __d1,__d2
    _d_max = !is_undef(__d1) && ! is_undef(__d2) ?
                max(__d1,__d2) :
                undef;

    // d1 and d2 are either 1, or relative to each other
    _d1 = !is_undef(__d1) && !is_undef(_d_max) ?
            __d1/_d_max :
            1;
    
    _d2 = !is_undef(__d2) && !is_undef(_d_max) ?
            __d2/_d_max :
            1;

    // check zet
    // '-> it is string or undef
    assert(is_undef(zet) || is_string(zet), "[CYLINDERPP] arguments 'zet' is eithter 'undef' or a string!");
    
    // construct rotation
    _r = __solidpp__get_rotation_from_zet(zet,[0,0,0]);

    // check size
    __solidpp__assert_size_like(size, "size", __module_name);
    
    // create bounding box from size
    __size = __solidpp__get_argument_as_3Dlist(size, undef);
    // create bounding box, possibly using cylinder-specific arguments
    _size = !is_undef(__size) ?
                __size :
                !is_undef(__size) ?
                    __size :
                    !is_undef(_d_max) && !is_undef(_h) ?
                        __solidpp__construct_cylinderpp_size(_d_max, _h, zet) :
                        [1,1,1];

    // process the align and center to produce offset
    // '-> arguments 'align' and 'center' are checked within the function
    _o = __solidpp__produce_offset_from_align_and_center(
            _size=_size,
            align=align,
            center=center,
            solidpp_name=__module_name,
            def_align=CYLINDERPP_DEF_ALIGN);
    
    // construct the solid
    translate(_o)
        resize(_size)
            rotate(_r)
                cylinder(d1=_d1,d2=_d2,h=1, center=true);
}

// defining the cylinderpp 
__DEF_CYLINDERPP__ = true;