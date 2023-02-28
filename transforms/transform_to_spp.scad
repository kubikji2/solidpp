include<../utils/solidpp_utils.scad>
include<../utils/vector_operations.scad>

// produce the offset
// '-> given input string 's' for axis defined by 'c' and 'C' of length 'l' 
function __solidpp__transforms__process_size_char(l, s, c, C) = 
    __solidpp__is_c_in_s(c,s) ?
        -0.5*l :
        __solidpp__is_c_in_s(C,s) ?
            0.5*l :
            0;


// produce the offset including possible interpolation
function __solidpp__transforms__process_size_el(l, s, c, C, int) = 
    is_undef(int) ?
        __solidpp__transforms__process_size_char(l=l,s=s,c=c,C=C) :
        (int-0.5)*l;


// Get translation to the position relative to the bounding box
// - arguments `size` and `align` describes bounding box size and alignment
// - argument `pos` describes the position within the bounding box
//   '-> Following rules apply for `pos` argument:
//       1. Argument `pos` is a string.
//       2. If the argument `pos` contains `x`/`y`/`z` the resulting translation
//          is alligned with the relative origin of the bounding box in x-axis/y-axis/z-axis
//       3. If the argument `pos` contains `X`/`Y`/`Z` the resulting translation
//          is alligned with the oposite end of the bounding box solid diagonal in x-axis/y-axis/z-axis.
//       4. If the argument `pos` contains neither `x`, nor `X` / `y`, nor `Y`/ `z`, nor `Z`
//          the center of x/y/z-axis is used.
//       5. For each axis the rules are evaluated sequentially in the order 2., 3. and then 4.
//       6. Repetition and other characters are ignored.
//   '-> For example `pos=""` results in translation to the bounding box center,
//       `pos="xyz"` is the left-front-bottom corner,
//       `pos="Xyz"` and `pos="Xxxxxxxxxyz"` is the right-front-bottom corner, 
//       `pos="Z"` is the top side center, and `pos=XZ` is the center of the right-top bounding box edge.
// - arguments `x`/`y`/`z` allows continous defintion of the point of interest within the bounding box.
//   '-> Following rules apply:
//       1. All arguments are numbers in the range [0,1].
//       2. Values continously interpolated on the particular axis
//          between the `x` and `X`/ `y` and `Y` / `z` and `Z`
//       3. The `x`/`y`/`z` and `pos` can be combined, but values in `x`/`y`/`z` have greater priority.
//   '-> For example `x=0.5,y=0,z=1` is equvalent to `pos=yZ` and it means the middle of the front-top edge,
//       `pos=yZ,x=0.25` is the point on the front-top edge 1/4 of the length from the left-front-top corner.
// NOTE: the translation to the solidpp center might be different to the scope origin
//       since the `align` might be use for the geometry.
// NOTE: the string `cube`/`sphere`/`cylinder` can be used to signals
//       that `cubepp`/`spherepp`/`cylinderpp` default alignment is used.
// NOTE: the default solidpp alignments are avaliable in
//       `CUBEPP_DEF_ALIGN`, `CYLINDERPP_DEF_ALIGN` and `SPHEREPP_DEF_ALIGN`.
function get_translation_to_spp(size, align, pos, x=undef, y=undef, z=undef) =
    add_vs
    (
        [
            __solidpp__transforms__process_size_el(l=size.x, s=pos, c="x", C="X", int=x),
            __solidpp__transforms__process_size_el(l=size.y, s=pos, c="y", C="Y", int=y),
            __solidpp__transforms__process_size_el(l=size.z, s=pos, c="z", C="Z", int=z)
        ],
        __solidpp__get_alignment_offset(size=size,align=align)
    );

/*
function get_translations_to_spp(size, align, pos, x=undef, y=undef, z=undef) =
    0;
*/


// Translate the children to the position relative to the bounding box
// - arguments `size` and `align` describes bounding box size and alignment
// - argument `pos` describes the position within the bounding box
//   '-> Following rules apply for `pos` argument:
//       1. Argument `pos` is a string.
//       2. If the argument `pos` contains `x`/`y`/`z` the resulting translation
//          is alligned with the relative origin of the bounding box in x-axis/y-axis/z-axis
//       3. If the argument `pos` contains `X`/`Y`/`Z` the resulting translation
//          is alligned with the oposite end of the bounding box solid diagonal in x-axis/y-axis/z-axis.
//       4. If the argument `pos` contains neither `x`, nor `X` / `y`, nor `Y`/ `z`, nor `Z`
//          the center of x/y/z-axis is used.
//       5. For each axis the rules are evaluated sequentially in the order 2., 3. and then 4.
//       6. Repetition and other characters are ignored.
//   '-> For example `pos=""` results in translation to the bounding box center,
//       `pos="xyz"` is the left-front-bottom corner,
//       `pos="Xyz"` and `pos="Xxxxxxxxxyz"` is the right-front-bottom corner, 
//       `pos="Z"` is the top side center, and `pos=XZ` is the center of the right-top bounding box edge.
// - arguments `x`/`y`/`z` allows continous defintion of the point of interest within the bounding box.
//   '-> Following rules apply:
//       1. All arguments are numbers in the range [0,1].
//       2. Values continously interpolated on the particular axis
//          between the `x` and `X`/ `y` and `Y` / `z` and `Z`
//       3. The `x`/`y`/`z` and `pos` can be combined, but values in `x`/`y`/`z` have greater priority.
//   '-> For example `x=0.5,y=0,z=1` is equvalent to `pos=yZ` and it means the middle of the front-top edge,
//       `pos=yZ,x=0.25` is the point on the front-top edge 1/4 of the length from the left-front-top corner.
// NOTE: the translation to the solidpp center might be different to the scope origin
//       since the `align` might be use for the geometry.
// NOTE: the string `cube`/`sphere`/`cylinder` can be used to signals
//       that `cubepp`/`spherepp`/`cylinderpp` default alignment is used.
// NOTE: the default solidpp alignments are avaliable in
//       `CUBEPP_DEF_ALIGN`, `CYLINDERPP_DEF_ALIGN` and `SPHEREPP_DEF_ALIGN`.
module translate_to_spp(size, align, pos, x=undef, y=undef, z=undef) 
{
    // check size
    // '-> it is either list of nums of size 3, or scalar
    __solidpp__assert_size_like(size, "size" ,"TRANSLATE TO SPP");
    
    // expand size if needed
    _size = __solidpp__get_argument_as_3Dlist(size,[1,1,1]);

    // check align
    assert(is_string(align), "[TRANSLATE TO SPP] argument 'align' must be string!");

    // check pos
    assert(is_string(pos), "[TRANSLATE TO SPP] argument 'pos' must be string!");
    
    // produce offset
    __off = get_translation_to_spp(size=_size, align=align, pos=pos, x=x, y=y, z=z);

    // translate the children
    translate(__off)
    {
        children();
    }

}
