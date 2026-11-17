include<../utils/solidpp_utils.scad>
include<../engine/prism.scad>
include<../engine/shape2d.scad>

// polygonpp default alignment: the points as given (as polygon)
POLYGONPP_DEF_ALIGN = "keep";

// polygon with corner modifiers
// - argument 'points' is the outline: [x, y] or [x, y, "tag"]; concave outlines are allowed, it
//   must not intersect itself; any orientation
//   '-> sides "s0", "s1", ... (side k runs from point k to point k+1), a tag adds names to the side
//       starting at its point (a letter optionally followed by digits; t b s x X y Y z Z reserved)
//   '-> a corner is named by its two sides, e.g. "s0s1"; points collinear with their neighbours are
//       not corners
// - argument 'align' aligns the bounding box, see README (default "keep": the points as given)
// - argument 'center' overrides 'align' if true
// - argument 'mod_list' is a list of corner modifiers applied in reading order
//   '-> bevel(d, where) and rounding(r, where), d/r a single number (legs along the sides)
//   '-> tokens: "all", "s2" (both corners of side 2), "s1s2" (one corner), "g" (tagged side)
//   '-> positive values on concave corners fill them (add material)
//   '-> negative values add a flare: the first name of a token is the base side that is extended
//       beyond the corner ("s0": both corners of s0, "s0s1": only the one shared with s1)
// - argument 'flare_in_align' if true, alignment includes flares (default false)
// See DESIGN.md for details.
module polygonpp(points, align=undef, center=false, mod_list=undef, flare_in_align=false)
{
    __module_name = "POLYGON++";

    _mods = __spp_2d_mods(mod_list, __module_name, "a single number");
    // [points CCW, side names, letters, corner flags]
    _base = __spp_2d_base(points, __module_name);
    _pts = __spp_polygon_outline(_base, _mods, __module_name);

    _src = flare_in_align ? _pts : _base[0];
    _box = [[min([for (p = _src) p[0]]), min([for (p = _src) p[1]])], [max([for (p = _src) p[0]]), max([for (p = _src) p[1]])]];
    _align = is_undef(align) ? POLYGONPP_DEF_ALIGN : align;

    if (_align == "keep" && !center)
        polygon(_pts);
    else
    {
        __o = __solidpp__produce_offset_from_align_and_center(
                _size=[each _box[1] - _box[0], 0],
                align=_align,
                center=center,
                solidpp_name=__module_name,
                def_align=POLYGONPP_DEF_ALIGN);

        translate([__o[0], __o[1]] - (_box[0] + _box[1])/2)
            polygon(_pts);
    }
}

// outline of polygonpp with the modifiers (points)
function __spp_polygon_outline(base, mods, ctx) =
    let(profile = __spp_2d_profile(base[0], base[1], base[3], function(names) __spp_prism_tag(names)))
    __spp_profile_points(__spp_2d_apply_mods(profile, mods, [base[0], base[1]], base[2], "along", ctx));
