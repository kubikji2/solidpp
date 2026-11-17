include<../utils/solidpp_utils.scad>
include<../engine/shape2d.scad>

SQUAREPP_DEF_ALIGN = "xy";

// improved version of the square module
// - argument 'size' is a number or [x, y] (default [1, 1])
// - argument 'align' aligns the bounding box, see README (default "xy", as square())
// - argument 'center' overrides 'align' if true
// - argument 'mod_list' is a list of corner modifiers applied in reading order
//   '-> bevel(d, where) and rounding(r, where); d/r is a number or [dx, dy] (legs along x and y,
//       an elliptical rounding)
//   '-> sides "x", "X", "y", "Y"; a corner is named by its two sides: "xy", "Xy", "XY", "xY";
//       "x" selects both corners of the side x, "all" all four
//   '-> negative values add a flare: the first letter of a token is the base side that is
//       extended beyond the corner, the second one selects the corner ("yX": the side y extended
//       beyond its corner with X, "y": both corners of y)
// - argument 'flare_in_align' if true, alignment includes flares (default false)
// See DESIGN.md for details.
module squarepp(size=undef, align=undef, center=false, mod_list=undef, flare_in_align=false)
{
    // module name
    __module_name = "SQUARE++";

    // check size
    __solidpp__assert_2D_vector_like(size, "size", __module_name);

    // parse size
    _size = __solidpp__get_argument_as_2Dlist(size, [1,1]);
    assert(_size[0] > 0 && _size[1] > 0,
        str("[", __module_name, "] the size must be positive, got ", size));

    _mods = __spp_2d_mods(mod_list, __module_name);
    _pts = __spp_square_outline(_size, _mods, __module_name);

    // bounding box: nominal, or of the outline with the flares
    _box = flare_in_align ?
        [[min([for (p = _pts) p[0]]), min([for (p = _pts) p[1]])], [max([for (p = _pts) p[0]]), max([for (p = _pts) p[1]])]] :
        [-_size/2, _size/2];

    // process the align and center to produce offset
    // '-> arguments 'align' and 'center' are checked within the function
    __o = __solidpp__produce_offset_from_align_and_center(
            _size=[each _box[1] - _box[0], 0],
            align=align,
            center=center,
            solidpp_name=__module_name,
            def_align=SQUAREPP_DEF_ALIGN);

    // throw away z-axis, offset of the bounding box center
    _o = [__o[0], __o[1]] - (_box[0] + _box[1])/2;

    translate(_o)
        if (len(_mods) == 0)
            square(_size, center=true);
        else
            polygon(_pts);
}

// outline of a centered rectangle with the modifiers (points)
function __spp_square_outline(size, mods, ctx) =
    let(
        a = size/2,
        names = [["y"], ["X"], ["Y"], ["x"]],
        pts = [[-a[0], -a[1]], [a[0], -a[1]], [a[0], a[1]], [-a[0], a[1]]],
        tags = ["xy", "Xy", "XY", "xY"],
        profile = [for (k = [0:3]) [pts[k][0], pts[k][1], tags[k], true]]
    )
    __spp_profile_points(__spp_2d_apply_mods(profile, mods, [pts, names], "xXyY", "projected", ctx));
