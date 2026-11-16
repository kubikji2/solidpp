// defining the revolvepp
__DEF_REVOLVEPP__ = true;

// including utils and the profile engine
include<../utils/solidpp_utils.scad>
include<../engine/section.scad>

// revolvepp default alignment
REVOLVEPP_DEF_ALIGN = "z";


// solid of revolution of a profile given by points
// - argument 'points' is the closed profile: [x, y], [x, y, "tag"] or [x, y, "tag", "f"]
//   '-> x is the distance from the axis (x >= 0), y the position along 'zet'
//   '-> the profile must not intersect itself, its orientation does not matter
//   '-> the segment from a point to the next one is a face of the solid, every face gets an
//       automatic name: "t"/"b" horizontal facing up/down, "o"/"i" facing away from/to the axis,
//       none on the axis
//   '-> a tag adds names to the segment starting at its point: a letter optionally followed by
//       digits, e.g. "g", "g1"; x X y Y z Z are reserved; t, b, o, i only refine a segment that
//       already has that name (e.g. "t1"), to add the segment to another default group use the
//       flag "f": [x, y, "t", "f"]
//   '-> a vertex is an edge named by both its faces, e.g. "to", "og1"
// - argument 'align' aligns the bounding box, see README (default "z")
//   '-> the bounding box is the one of the full revolution, the y offset of the points is dropped
//   '-> "keep" places the points as given: the axis through the origin, y along +zet
// - argument 'zet' is the axis of revolution: "x", "y" or "z" (default)
// - argument 'center' overrides 'align' if true (also "keep")
// - argument 'mod_list' is a list of edge modifiers applied in reading order
//   '-> bevel(d, where) and rounding(r, where); a token selects edges whose faces include all its
//       face names, a bare letter matches its family ("g" matches "g", "g1", ...)
//   '-> on a concave edge, a positive value fills the corner
//   '-> negative values add a flare along the horizontal face of a convex edge
// - argument 'fn' is the number of sides, undef (default) uses $fn/$fa/$fs like OpenSCAD
// - argument 'polygon' "corners" (default), "flats" or "polyhole", see cylinderpp
//   '-> measured at the largest radius of the profile
// - argument 'flare_in_align' if true, alignment includes flares (default false)
// - argument 'sector' cuts a sector, see cylinderpp
// See DESIGN.md for details.
module revolvepp(points, align=undef, zet=undef, center=false, mod_list=undef,
                 fn=undef, polygon="corners", flare_in_align=false, sector=undef)
{
    __module_name = "REVOLVEPP";

    _zet = __spp_check_zet(zet, __module_name);
    _fn = __spp_check_fn(fn, "fn", __module_name);
    _mods =
        assert(is_undef(mod_list) || !is_list(mod_list) ||
               len([for (m = mod_list) if (__spp_is_legacy_mod(m)) 1]) == 0,
            str("[", __module_name, "] old modifiers are not supported, use bevel() and rounding()"))
        __spp_resolve_mod_list(mod_list, "revolved", __module_name);
    _sector = __spp_check_sector(sector, _zet, __module_name);
    assert(is_bool(flare_in_align),
        str("[", __module_name, "] argument 'flare_in_align' must be a boolean"));

    _keep = align == "keep" && !center;

    // [points, alignment radius, tagged profile, body radius, height]
    _spec = __spp_revp_spec(points, _mods, flare_in_align, __module_name, _keep);

    _size = __solidpp__construct_cylinderpp_size(2*_spec[1], _spec[4], _zet);

    _o = _keep ? [0, 0, 0] : __solidpp__produce_offset_from_align_and_center(
            _size=_size,
            align=align,
            center=center,
            solidpp_name=__module_name,
            def_align=REVOLVEPP_DEF_ALIGN);

    _rot = __solidpp__get_rotation_from_zet(_zet, [0,0,0]);

    translate(_o)
        rotate(_rot)
            __spp_revolve(_spec[0], _fn, polygon, __module_name, _sector, _spec[3], convexity=10);
}
