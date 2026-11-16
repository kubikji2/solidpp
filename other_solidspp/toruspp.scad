// defining the toruspp
__DEF_TORUSPP__ = true;

// including utils and the profile engine
include<../utils/solidpp_utils.scad>
include<../engine/revolved.scad>

// toruspp default alignment (centered)
TORUSPP_DEF_ALIGN = "";


// torus (ring with an elliptical tube)
// - exactly two of 't', 'r|d', 'R|D' must be defined (default r=0.5, R=1)
//   '-> argument 't' is the radial width of the tube
//   '-> argument 'r'|'d' is the inner radius/diameter (the hole), may be 0
//   '-> argument 'R'|'D' is the outer radius/diameter
// - argument 'h' is the height of the tube along 'zet' (default 't', i.e. a circular tube)
// - argument 'align' aligns the bounding box, see README (default "", centered)
// - argument 'zet' is the axis of the torus: "x", "y" or "z" (default)
// - argument 'center' overrides 'align' if true
// - argument 'fn' is the number of sides of the revolution
//   '-> undef (default) uses $fn/$fa/$fs like OpenSCAD; the tube always uses $fn/$fa/$fs
// - argument 'polygon' "corners" (default, as OpenSCAD) or "flats" (flats on the circles)
// - argument 'sector' cuts a sector, see cylinderpp
//   '-> the bounding box (alignment) is the one of the full torus
// See DESIGN.md for details.
module toruspp(t=undef, r=undef, d=undef, R=undef, D=undef, h=undef, align=undef, zet=undef, center=false,
               fn=undef, polygon="corners", sector=undef)
{
    __module_name = "TORUSPP";

    _zet = __spp_check_zet(zet, __module_name);
    _fn = __spp_check_fn(fn, "fn", __module_name);
    _polygon = assert(polygon != "polyhole",
        str("[", __module_name, "] polygon mode \"polyhole\" is meant for holes, use \"corners\" or \"flats\""))
        polygon;
    _sector = __spp_check_sector(sector, _zet, __module_name);

    // [r, R, t, h]
    _args = __spp_torus_args(t=t, r=r, d=d, R=R, D=D, h=h, ctx=__module_name);

    _size = __solidpp__construct_cylinderpp_size(2*_args[1], _args[3], _zet);

    _o = __solidpp__produce_offset_from_align_and_center(
            _size=_size,
            align=align,
            center=center,
            solidpp_name=__module_name,
            def_align=TORUSPP_DEF_ALIGN);

    _rot = __solidpp__get_rotation_from_zet(_zet, [0,0,0]);

    translate(_o)
        rotate(_rot)
            __spp_revolve(__spp_torus_profile(_args[0], _args[2], _args[3]), _fn, _polygon, __module_name,
                          _sector, _args[1], convexity=4);
}
