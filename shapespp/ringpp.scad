include<../utils/solidpp_utils.scad>
include<../engine/section.scad>
include<circlepp.scad>

RINGPP_DEF_ALIGN = "";

// ring (annulus), the 2D counterpart of tubepp
// - exactly two of 't', 'r|d', 'R|D' must be defined (default r=0.5, R=1)
//   '-> argument 't' is the width of the ring
//   '-> argument 'r'|'d' is the inner radius/diameter (the hole), must be positive
//   '-> argument 'R'|'D' is the outer radius/diameter
// - argument 'align' aligns the bounding box (the outer circle), see README (default "", centered)
// - argument 'center' overrides 'align' if true
// - arguments 'outer_fn', 'inner_fn' number of sides of each circle (undef: $fn/$fa/$fs)
// - arguments 'outer_polygon', 'inner_polygon': "corners" (default), "flats", "polyhole"
// - argument 'sector' an angle or [from, to]: a slice of the ring
// - arguments 'outer_section', 'inner_section': teardrop() and/or serration(), as for circlepp
//   '-> teardrop(up=...) with "x", "X", "y", "Y", default "Y"
// See DESIGN.md for details.
module ringpp(t=undef, r=undef, d=undef, R=undef, D=undef, align=undef, center=false,
              outer_fn=undef, inner_fn=undef, outer_polygon="corners", inner_polygon="corners",
              sector=undef, outer_section=undef, inner_section=undef)
{
    __module_name = "RINGPP";

    // [r, R, t, h]
    _args = __spp_torus_args(t, r, d, R, D, undef, __module_name, "; use circlepp for a disc");
    _ofn = __spp_check_fn(outer_fn, "outer_fn", __module_name);
    _ifn = __spp_check_fn(inner_fn, "inner_fn", __module_name);

    _outer = __spp_circle_shape(_args[1], _ofn, outer_polygon, sector, outer_section, __module_name);
    _inner = __spp_circle_shape(_args[0], _ifn, inner_polygon, undef, inner_section, __module_name);

    // the hole must stay inside the ring (with its polygon mode and section)
    _rmax = max([for (p = _inner) norm(p)]);
    _Rmin = min([for (p = is_undef(sector) ? _outer : __spp_circle_shape(_args[1], _ofn, outer_polygon, undef,
                                                                       outer_section, __module_name)) norm(p)]);
    assert(_rmax < _Rmin,
        str("[", __module_name, "] the hole (up to ", _rmax, " from the center) does not fit into the ring ",
            "(down to ", _Rmin, "), make the ring wider"));

    __o = __solidpp__produce_offset_from_align_and_center(
            _size=[2*_args[1], 2*_args[1], 0],
            align=align,
            center=center,
            solidpp_name=__module_name,
            def_align=RINGPP_DEF_ALIGN);

    translate([__o[0], __o[1]])
        difference()
        {
            polygon(_outer);
            polygon(_inner);
        }
}
