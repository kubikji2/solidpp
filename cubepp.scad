// defining the cubepp
__DEF_CUBEPP__ = true;

// including utils and the box engine
include<utils/solidpp_utils.scad>
include<engine/box.scad>

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
// - argument 'zet' is the base axis of the modifiers: "x", "y" or "z" (default)
//   '-> the faces perpendicular to 'zet' are the bases ("b" bottom, "t" top)
// - argument 'center' is a bool and provides backward compatibility with the "cube(center=true)"
//   '-> note that 'center=true' overrides any 'align'
// - argument 'mod_list' is a list of modifiers applied in reading order
//   '-> bevel(d, where), rounding(r, where), bevel_corners(d, where)
//   '-> selectors use the letters of the parent frame x X y Y z Z, "t"/"b" for the bases,
//       "x-edges"/"y-edges"/"z-edges" for edges parallel to an axis, or "all"
//       e.g. "t" (edges of the top base), "xY" (one edge), "z-edges", "txY" (one corner)
//   '-> values: a number, [across, along] (along = 'zet'), or [x, y, z]
//   '-> negative values add a flare into the base plane (base edges only)
//   '-> a modifier of edges parallel to 'zet' placed before the base modifiers is followed
//       by them (swept); placed after a base modifier it is a straight cut
// - argument 'flare_in_align' if true, alignment includes flares (default false)
// - argument 'flare_in_size' if true, 'size' includes flares, the body shrinks (default false)
// See DESIGN.md for details.
module cubepp(size=undef, align=undef, zet=undef, center=false, mod_list=undef,
              flare_in_align=false, flare_in_size=false)
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

    _zet = __spp_check_zet(zet, __module_name);
    _mods = __spp_resolve_mod_list(mod_list, "box", __module_name);
    assert(is_bool(flare_in_align) && is_bool(flare_in_size),
        str("[", __module_name, "] arguments 'flare_in_align' and 'flare_in_size' must be booleans"));

    if (len(_mods) == 0)
    {
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
    else
    {
        _stages = __spp_box_stages(_mods, _zet, __module_name);

        // [rings, is convex, corner cutters, local body box, local box with flares]
        _spec = __spp_box_spec(__spp_box_to_local_extents(_size, _zet), _stages, flare_in_size, _zet, __module_name);

        // box used for alignment (local frame), may be off-center when flares differ per side
        _box = flare_in_align ? _spec[4] : _spec[3];
        _box_size = __spp_box_to_parent_extents(_box[1] - _box[0], _zet);
        _box_center = __spp_box_to_parent_position((_box[0] + _box[1]) / 2, _zet);

        _o = __solidpp__produce_offset_from_align_and_center(
                _size=_box_size,
                align=align,
                center=center,
                solidpp_name=__module_name,
                def_align=CUBEPP_DEF_ALIGN);

        _rot = __solidpp__get_rotation_from_zet(_zet, [0,0,0]);

        translate(_o - _box_center)
            rotate(_rot)
                __spp_box_geometry(_spec);
    }
}
