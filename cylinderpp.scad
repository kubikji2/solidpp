// defining the cylinderpp
__DEF_CYLINDERPP__ = true;

// including utils and the profile engine
include<utils/solidpp_utils.scad>
include<engine/revolved.scad>

// cylinderpp default alignment
CYLINDERPP_DEF_ALIGN = "z";


// improved version of the cylinder module
// - argument 'size' defines the bounding box in the parent frame
//   '-> a number, or [x, y, z]; the two base dimensions (given by 'zet') must be equal,
//       elliptical cylinders are not supported
//   '-> cannot be combined with 'r|d' and 'h'
//   '-> can be combined with 'r1|d1', 'r2|d2'; then the greater base fits the 'size'
// - argument 'r'|'d' defines the radius/diameter
//   '-> a number, or [bottom, top] for a cone
// - argument 'h' defines the height (default 1)
// - arguments 'r1'|'d1', 'r2'|'d2' define the bottom and top radius/diameter (both required)
//   '-> a zero radius is allowed for one base (cone apex)
// - argument 'align' aligns the bounding box, see README (default "z")
// - argument 'zet' is the axis of the cylinder: "x", "y" or "z" (default)
//   '-> the bottom base is at the low end of the axis
// - argument 'center' overrides 'align' if true
// - argument 'mod_list' is a list of edge modifiers applied in reading order
//   '-> bevel(d, where) and rounding(r, where)
//   '-> edges: "bo" bottom outer, "to" top outer; tokens "b", "t", "o", "all"
//   '-> negative values add a flare into the base plane
// - argument 'fn' is the number of sides of the cylinder
//   '-> undef (default) uses $fn/$fa/$fs like OpenSCAD
//   '-> arcs of rounding always use $fn/$fa/$fs
// - argument 'polygon' defines how a polygonal cylinder is measured
//   '-> "corners" (default, as OpenSCAD) vertices lie on the circle
//   '-> "flats" flats lie on the circle (e.g. nut traps)
// - argument 'flare_in_align' if true, alignment includes flares (default false)
// - argument 'flare_in_size' if true, the diameter includes flares, the body shrinks (default false)
// See DESIGN.md for details.
module cylinderpp(size=undef, r=undef, d=undef, h=undef, align=undef, zet=undef, center=false,
                  r1=undef, r2=undef, d1=undef, d2=undef, mod_list=undef,
                  fn=undef, polygon="corners", flare_in_align=false, flare_in_size=false)
{
    __module_name = "CYLINDERPP";

    _zet = __spp_check_zet(zet, __module_name);
    _fn = __spp_check_fn(fn, "fn", __module_name);
    _mods = __spp_resolve_mod_list(mod_list, "revolved", __module_name);
    assert(is_bool(flare_in_align) && is_bool(flare_in_size),
        str("[", __module_name, "] arguments 'flare_in_align' and 'flare_in_size' must be booleans"));

    // [R1, R2, h]
    _args = __spp_cyl_args(size=size, r=r, d=d, h=h, r1=r1, r2=r2, d1=d1, d2=d2,
                           zet=_zet, ctx=__module_name);

    // [points, alignment radius, tagged profile]
    _spec = __spp_cyl_spec(_args, _mods, flare_in_size, flare_in_align, __module_name);

    _size = __solidpp__construct_cylinderpp_size(2*_spec[1], _args[2], _zet);

    // process the align and center to produce offset
    // '-> arguments 'align' and 'center' are checked within the function
    _o = __solidpp__produce_offset_from_align_and_center(
            _size=_size,
            align=align,
            center=center,
            solidpp_name=__module_name,
            def_align=CYLINDERPP_DEF_ALIGN);

    _rot = __solidpp__get_rotation_from_zet(_zet, [0,0,0]);

    translate(_o)
        rotate(_rot)
            __spp_revolve(_spec[0], _fn, polygon, __module_name);
}
