include<utils/solidpp_utils.scad>
include<utils/vector_operations.scad>
include<utils/__cylinderpp_utils.scad>

// cylinder mods
include<cylinderpp_mods/bevel_bases_cylinderpp.scad>
include<cylinderpp_mods/round_bases_cylinderpp.scad>
include<cylinderpp_mods/round_corners_cylinderpp.scad>

// mod queue management
include<modifiers/modifiers.scad>
include<modifiers/__modifiers_queue.scad>

// cylinderpp default alignment
CYLINDERPP_DEF_ALIGN = "z";

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
//       - a vector 2D,
//       - 'undef' (default value) to use default radius
//   '-> note that you cannot define both 'r' and 'd'
// - argument 'd' defines the cylinder diameter
//   '-> it can either be:
//       - a single number,
//       - a vector 2D,
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
module cylinderpp(size=undef, r=undef, d=undef, h=undef, align=undef, zet=undef, center=false,
                    r1=undef, r2=undef, d1=undef, d2=undef, mod_list=undef, __mod_queue=undef)
{

    __module_name = "CYLINDERPP";

    // check size
    __solidpp__assert_size_like(size, "size", __module_name);

    // check mod_list
    assert(
            is_undef(mod_list) || __solidpp__is_valid_modifier_list(mod_list),
            str("[", __module_name, "] argument 'mod_list' be either undef or list of valid 'modifiers'!")
            );

    // handlign default zet
    _zet = is_undef(zet) ? "z" : zet;

    // parsing and checking cylinder-related data
    cyl_data = __solidpp__cylinderpp__check_params(
                    module_name=__module_name, size=size, r=r, d=d, h=h,
                    r1=r1, r2=r2, d1=d1, d2=d2, zet=_zet);
    
    // data extraction
    _h = cyl_data[__CYLINDERPP_UTILS__h_idx];
    _size = cyl_data[__CYLINDERPP_UTILS__size_idx];
    _d1 = cyl_data[__CYLINDERPP_UTILS__d1_idx];
    _d2 = cyl_data[__CYLINDERPP_UTILS__d2_idx];
    
    // for uniform size
    __d1 = cyl_data[__CYLINDERPP_UTILS___d1_idx];
    __d2 = cyl_data[__CYLINDERPP_UTILS___d2_idx];
    _is_non_uniform = cyl_data[__CYLINDERPP_UTILS__non_uniform];

    // process the align and center to produce offset
    // '-> arguments 'align' and 'center' are checked within the function
    _o = __solidpp__produce_offset_from_align_and_center(
            _size=_size,
            align=align,
            center=center,
            solidpp_name=__module_name,
            def_align=CYLINDERPP_DEF_ALIGN);

    // check zet
    // '-> it is string or undef
    assert(is_undef(zet) || is_string(zet), "[CYLINDERPP] arguments 'zet' is eithter 'undef' or a string!");
    
    // construct rotation
    _rot = __solidpp__get_rotation_from_zet(zet,[0,0,0]);

    // construct the solid

    _resize_size = 0;
    if(is_undef(mod_list) && is_undef(__mod_queue))
    {
        if (_is_non_uniform)
        {
            translate(_o)
                resize(_size)
                    rotate(_rot)
                        cylinder(d1=_d1,d2=_d2,h=1, center=true);
        }
        else
        {
            translate(_o)    
            rotate(_rot)
            rotate_extrude()
                if($children==0)
                {
                    __solidpp__cylinderpp__get_def_plane(d1=__d1, d2=__d2, h=_h);
                }
                else 
                {
                    children();
                }
        }
                                 
    }
    else
    {
        _tmp_queue = is_undef(__mod_queue) ? __solidpp__new_queue(mod_list) : __mod_queue;
        _ret = __solidpp__pop(_tmp_queue);
        _mod = _ret[0];
        _mod_queue = __solidpp__queue_size(_ret[1]) > 0 ? _ret[1] : undef;

        translate(_o)
        rotate(_rot)
        if (__solidpp__is_valid_bevel_bases_modifier(_mod))
        {
            // bevel bases
            bevel_bases_cylinderpp(size=size, r=r, d=d, h=h, r1=r1, r2=r2, d1=d1, d2=d2,
                                    center=true, mod=_mod, __mod_queue=_mod_queue)
            if ($children==0)
            {
                __solidpp__cylinderpp__get_def_plane(d1=__d1, d2=__d2, h=_h);
            }
            else
            {
                children();
            }
        }
        else if (__solidpp__is_valid_round_bases_modifier(_mod))
        {
            // round bases 
            round_bases_cylinderpp(size=size, r=r, d=d, h=h, r1=r1, r2=r2, d1=d1, d2=d2,
                                    center=true, mod=_mod, __mod_queue=_mod_queue)
            if ($children==0)
            {
                __solidpp__cylinderpp__get_def_plane(d1=__d1, d2=__d2, h=_h);
            }
            else
            {
                children();
            }
        }
        else if (__solidpp__is_valid_round_corners_modifier(_mod))
        {
            // round corners
            round_corners_cylinderpp(size=size, r=r, d=d, h=h, r1=r1, r2=r2, d1=d1, d2=d2,
                                    center=true, mod=_mod, __mod_queue=_mod_queue)
            if ($children==0)
            {
                __solidpp__cylinderpp__get_def_plane(d1=__d1, d2=__d2, h=_h);
            }
            else
            {
                children();
            }
        }
        else if (__solidpp__is_valid_modifier(_mod))
        {
            // bevel edges
            assert(false,
            str("[", __module_name, "] unsupported modifier!"));
        }
        else
        {
            assert(false,
            str("[", __module_name, "] something went wrong regarding modifiers!"));
        }
    }
}

// defining the cylinderpp 
__DEF_CYLINDERPP__ = true;