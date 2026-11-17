// defining the prismpp
__DEF_PRISMPP__ = true;

// including utils and the prism engine
include<../utils/solidpp_utils.scad>
include<../engine/prism.scad>

// prismpp default alignment: the points as given (as linear_extrude)
PRISMPP_DEF_ALIGN = "keep";


// right prism over a convex base polygon
// - argument 'points' is the base: [x, y] or [x, y, "tag"], strictly convex, any orientation
//   '-> the points are drawn as for zet="z"; the solid is then turned like every solidpp solid
//       (zet "x": rotate([0, 90, 0]), zet "y": rotate([-90, 0, 0]))
//   '-> faces: "t", "b" (bases) and "s0", "s1", ... (side k runs from point k to point k+1)
//   '-> a tag adds names to the side starting at its point: a letter optionally followed by digits,
//       e.g. "g", "g1"; t, b, s, x, X, y, Y, z, Z are reserved
// - argument 'h' is the height along 'zet' (default 1)
// - argument 'align' aligns the bounding box, see README (default "keep")
//   '-> "keep" places the points as given, the base on the plane w = 0, the top at w = h
// - argument 'zet' is the axis of the prism: "x", "y" or "z" (default)
// - argument 'center' overrides 'align' if true
// - argument 'mod_list' is a list of edge modifiers applied in reading order, as for cubepp
//   '-> bevel(d, where) and rounding(r, where), d/r is a number or [across, along]
//   '-> tokens: "all", "t", "b", "s" (all sides), "s2" (the 4 edges of side 2), "ts2" (one edge),
//       "s1s2" (vertical edge between sides 1 and 2), "z-edges" (edges parallel to the z-axis), ...
//   '-> negative values add a flare into the base plane (base edges only)
// - argument 'flare_in_align' if true, alignment includes flares (default false)
// - taper (at most one of):
//   '-> argument 'scale' number > 0: the top is the base scaled about 'scale_center'
//       (default: the centroid of the base); > 1 makes the top larger (overhang)
//   '-> argument 'draft' angle or list of angles (one per side s0, s1, ...): the sides lean inwards
//       by the angle (outwards if negative), e.g. 45 for self-supporting walls, [0, 30, 30, 30]
//       keeps side s0 vertical
//   '-> the edges between the sides stay "<zet>-edges" (slanted), the bounding box includes the top
// See DESIGN.md for details.
module prismpp(points, h=1, align=undef, zet=undef, center=false, mod_list=undef, flare_in_align=false,
               scale=undef, scale_center=undef, draft=undef)
{
    __module_name = "PRISMPP";

    _zet = __spp_check_zet(zet, __module_name);
    _h = assert(is_num(h) && h > 0, str("[", __module_name, "] argument 'h' must be a positive number, got ", h)) h;
    _mods =
        assert(is_undef(mod_list) || !is_list(mod_list) ||
               len([for (m = mod_list) if (__spp_is_legacy_mod(m)) 1]) == 0,
            str("[", __module_name, "] old modifiers are not supported, use bevel() and rounding()"))
        __spp_resolve_mod_list(mod_list, "revolved", __module_name);
    _flare_in_align = assert(is_bool(flare_in_align),
        str("[", __module_name, "] argument 'flare_in_align' must be a boolean")) flare_in_align;
    _align = is_undef(align) ? PRISMPP_DEF_ALIGN : align;
    _keep = _align == "keep" && !center;

    // [CCW points, side names, centroid, letters]
    _base = __spp_prism_base(points, __module_name);

    // distances of the top sides (undef without a taper) and the top polygon (true coordinates)
    _Wt = __spp_prism_taper(_base, _h, scale, scale_center, draft, __module_name);
    _top = is_undef(_Wt) ? _base[0] : [for (p = __spp_prism_top(_base, _Wt, __module_name)) p + _base[2]];

    // [rings, is convex, [], local body box, local box with flares, flare range] or undef
    _spec = len(_mods) == 0 ?
        undef :
        let(
            _edges = __spp_prism_edges(_base[1]),
            _stages = __spp_prism_stages(_mods, _edges, _base[0], _base[3], _zet, __module_name)
        )
        __spp_prism_spec(_base, _h, _stages, __module_name, _Wt);

    _body_box = __spp_prism_body_box(_base[0], _top, _h);
    _box = !is_undef(_spec) && _flare_in_align ? _spec[4] : _body_box;

    _rot = __solidpp__get_rotation_from_zet(_zet, [0,0,0]);

    if (_keep)
        rotate(_rot)
            translate([0, 0, _h/2])
                __spp_prism_geometry(_base, _top, _h, _spec);
    else
    {
        _box_size = __spp_box_to_parent_extents(_box[1] - _box[0], _zet);
        _box_center = __spp_box_to_parent_position((_box[0] + _box[1]) / 2, _zet);

        _o = __solidpp__produce_offset_from_align_and_center(
                _size=_box_size,
                align=_align,
                center=center,
                solidpp_name=__module_name,
                def_align=PRISMPP_DEF_ALIGN);

        translate(_o - _box_center)
            rotate(_rot)
                __spp_prism_geometry(_base, _top, _h, _spec);
    }
}

// prism in the local frame, base centered on w = 0
// - 'top' polygon of the top (equal to the base without a taper)
module __spp_prism_geometry(base, top, h, spec)
{
    if (!is_undef(spec))
        __spp_box_geometry(spec);
    else if (top == base[0])
        linear_extrude(height=h, center=true)
            polygon(base[0]);
    else
        __spp_rings_hull([[-h/2, base[0]], [h/2, top]]);
}
