// defining the tubepp
__DEF_TUBEPP__ = true;

// including utils and the profile engine
include<../utils/solidpp_utils.scad>
include<../engine/section.scad>

// tubepp default alignment
TUBEPP_DEF_ALIGN = "z";


// tube (hollow cylinder)
// - exactly two of 't', 'r|d', 'R|D' must be defined (default r=0.5, R=1)
//   '-> argument 't' is the wall thickness
//   '-> argument 'r'|'d' is the hole radius/diameter
//   '-> argument 'R'|'D' is the outer radius/diameter
//   '-> each is a number, or [bottom, top]
// - argument 'size' defines the bounding box in the parent frame (counts as 'R|D' and 'h')
//   '-> a number, or [x, y, z]; the two base dimensions must be equal
// - argument 'h' defines the height (default 1)
// - argument 'align' aligns the bounding box, see README (default "z")
// - argument 'zet' is the axis of the tube: "x", "y" or "z" (default)
// - argument 'center' overrides 'align' if true
// - argument 'mod_list' is a list of edge modifiers applied in reading order
//   '-> bevel(d, where) and rounding(r, where)
//   '-> edges: "bi", "bo", "to", "ti" (b/t bottom/top, i/o inner/outer)
//   '-> e.g. bevel(0.5, "ti") chamfers the top of the hole (heat inserts)
//   '-> negative values add a flare into the base plane
// - arguments 'outer_fn', 'inner_fn' are the numbers of sides of the outer wall and of the hole
//   '-> undef (default) uses $fn/$fa/$fs like OpenSCAD
// - arguments 'outer_polygon', 'inner_polygon' define how a polygonal wall is measured
//   '-> "corners" (default, as OpenSCAD) vertices lie on the circle
//   '-> "flats" flats lie on the circle (e.g. nut traps)
//   '-> "polyhole" flats on the circle with max(round(2*d), 3) sides (nophead's polyholes,
//       printed holes keep their size); the 'fn' of that wall must not be set
// - argument 'flare_in_align' if true, alignment includes flares (default false)
// - argument 'flare_in_size' if true, the outer diameter includes flares, the body shrinks (default false)
// - arguments 'outer_cross_section', 'inner_cross_section' are the shapes of the outer wall and of the hole
//   '-> teardrop(up, angle, cap), serration(n, depth, profile, width), or [teardrop(), serration()]
//   '-> e.g. inner_cross_section=serration(6, 0.25, "round") gives crush ribs in the hole
// - argument 'sector' cuts a sector of the outer body (a C-shape): an angle or [from, to] in degrees
//   '-> right-hand rule around 'zet', 0 at +x (zet "z"), +y (zet "x"), +z (zet "y")
//   '-> the bounding box (alignment) is the one of the full tube
//   '-> only for the circle 'outer_cross_section'
// - arguments 'inner_mod_list', 'outer_mod_list' are deprecated, use 'mod_list' with "i"/"o" selectors
// See DESIGN.md for details.
module tubepp(size=undef, t=undef, r=undef, d=undef, R=undef, D=undef, h=undef,
              align=undef, zet=undef, center=false, mod_list=undef,
              outer_fn=undef, inner_fn=undef, outer_polygon="corners", inner_polygon="corners",
              flare_in_align=false, flare_in_size=false,
              outer_cross_section=undef, inner_cross_section=undef, sector=undef,
              inner_mod_list=undef, outer_mod_list=undef)
{
    __module_name = "TUBEPP";

    _zet = __spp_check_zet(zet, __module_name);
    _outer_fn = __spp_check_fn(outer_fn, "outer_fn", __module_name);
    _inner_fn = __spp_check_fn(inner_fn, "inner_fn", __module_name);
    // '-> deprecated 'outer_mod_list'/'inner_mod_list' are translated to 'o'/'i' edges
    _mods = concat(
        __spp_resolve_mod_list(mod_list, "revolved", __module_name),
        __spp_legacy_restrict(__spp_resolve_mod_list(outer_mod_list, "revolved", __module_name), "o", __module_name),
        __spp_legacy_restrict(__spp_resolve_mod_list(inner_mod_list, "revolved", __module_name), "i", __module_name));
    _osec = __spp_resolve_section(outer_cross_section, _zet, __module_name, "outer_cross_section");
    _isec = __spp_resolve_section(inner_cross_section, _zet, __module_name, "inner_cross_section");
    _sector = __spp_check_sector(sector, _zet, __module_name);
    assert(is_undef(_sector) || __spp_is_plain_section(_osec),
        str("[", __module_name, "] argument 'sector' cannot be combined with 'outer_cross_section' (teardrop, serration)"));
    assert(is_bool(flare_in_align) && is_bool(flare_in_size),
        str("[", __module_name, "] arguments 'flare_in_align' and 'flare_in_size' must be booleans"));

    // [r1, r2, R1, R2, h]
    _args = __spp_tube_args(size=size, t=t, r=r, d=d, R=R, D=D, h=h, zet=_zet, ctx=__module_name);

    // [outer body points, hole cutter points, alignment radius, tagged profile, body radius, body args]
    _spec = __spp_tube_spec(_args, _mods, flare_in_size, flare_in_align, __module_name);

    _size = __solidpp__construct_cylinderpp_size(2*_spec[2], _args[4], _zet);

    // process the align and center to produce offset
    // '-> arguments 'align' and 'center' are checked within the function
    _o = __solidpp__produce_offset_from_align_and_center(
            _size=_size,
            align=align,
            center=center,
            solidpp_name=__module_name,
            def_align=TUBEPP_DEF_ALIGN);

    _rot = __solidpp__get_rotation_from_zet(_zet, [0,0,0]);

    translate(_o)
        rotate(_rot)
            difference()
            {
                if (__spp_is_plain_section(_osec))
                    __spp_revolve(_spec[0], _outer_fn, outer_polygon, __module_name, _sector, _spec[4]);
                else
                    let(_chain = __spp_rev_outer_chain(_spec[3], _args[4], _spec[5][2], _spec[5][3]))
                    __spp_section_geometry(
                        __spp_section_pieces(_chain[0], _chain[1], _chain[2], _spec[4], _osec,
                                             _outer_fn, outer_polygon, __module_name));

                if (__spp_is_plain_section(_isec))
                    __spp_revolve(_spec[1], _inner_fn, inner_polygon, __module_name, undef, max(_args[0], _args[1]));
                else
                    let(_chain = __spp_rev_inner_chain(_spec[3], _args[4],
                                    __spp_rev_inner_protrusion(_args[0], _args[1], _args[4]), _args[0], _args[1]))
                    __spp_section_geometry(
                        __spp_section_pieces(_chain[0], _chain[1], _chain[2], max(_args[0], _args[1]), _isec,
                                             _inner_fn, inner_polygon, __module_name));
            }
}
