include<../utils/solidpp_utils.scad>
include<../engine/section.scad>

CIRCLEPP_DEF_ALIGN = "";

// improved version of the circle module
// - argument 'size' defines the size of the bounding box: a number or [x, y] (an ellipse)
// - argument 'r'|'d' defines the radius/diameter: a number or [x, y] (an ellipse)
//   '-> only one of 'size', 'r', 'd' can be used, default size is [1, 1]
// - argument 'align' aligns the bounding box, see README (default: centered)
//   '-> the bounding box is the one of the full circle (also with 'sector' and 'cross_section')
// - argument 'center' overrides 'align' if true
// - argument 'fn' is the number of sides, undef (default) uses $fn/$fa/$fs like circle()
// - argument 'polygon': "corners" (default, as circle()), "flats" (the flats on the circle) or
//   "polyhole" (flats, sides by the diameter, a hole for printing; no 'fn')
// - argument 'sector' an angle or [from, to] (counter-clockwise from +x): a pie slice
// - argument 'cross_section' teardrop() and/or serration(), as for cylinderpp
//   '-> teardrop(up=...) with "x", "X", "y", "Y", default "Y" (the tip points to +y)
// - 'polygon' "flats"/"polyhole", 'sector' and 'cross_section' work for circles only (not ellipses)
// - the circle is made with the largest diameter, so $fn/$fa/$fs act as in circle(),
//   an ellipse is that circle scaled down along the other axis
//   '-> as in OpenSCAD, the vertices lie on the circle (polygon "corners")
module circlepp(size=undef, r=undef, d=undef, align=undef, center=false,
                fn=undef, polygon="corners", sector=undef, cross_section=undef)
{
    // module name
    __module_name = "CIRCLE++";

    // check r and d
    __d = !is_undef(d) ?
            d :
            !is_undef(r) ?
                2*r :
                undef;
    // check mutex group {size, r, }
    assert( is_undef(__d) || is_undef(size),
            str("[", __module_name, "] it is allowed to use only single argument {r,d,size} simulatanously.")
    );
    // check size
    __solidpp__assert_2D_vector_like(size, "size", __module_name);
    // parse size
    __size = __solidpp__get_argument_as_2Dlist(size, [1,1]);
    // create size
    _size = !is_undef(__d) ?
                (is_num(__d) ? [__d, __d] : __d) :
                __size;
    assert(is_list(_size) && len(_size) == 2 && is_num(_size[0]) && is_num(_size[1]) &&
           _size[0] > 0 && _size[1] > 0,
        str("[", __module_name, "] the size must be a positive number or a list of 2 positive numbers, got ", _size));

    // process the align and center to produce offset
    // '-> arguments 'align' and 'center' are checked within the function
    __o = __solidpp__produce_offset_from_align_and_center(
            _size=[each _size,0],
            align=align,
            center=center,
            solidpp_name=__module_name,
            def_align=CIRCLEPP_DEF_ALIGN);
    // throw away z-axis
    _o = [__o[0], __o[1]];

    _fn = __spp_check_fn(fn, "fn", __module_name);
    _is_circle = _size[0] == _size[1];
    _D = max(_size);

    translate(_o)
        if (_is_circle)
            polygon(__spp_circle_shape(_D/2, _fn, polygon, sector, cross_section, __module_name));
        else
        {
            assert(polygon == "corners" && is_undef(sector) && is_undef(cross_section),
                str("[", __module_name, "] 'polygon' \"flats\"/\"polyhole\", 'sector' and 'cross_section' work only for ",
                    "circles, not for ellipses (size ", _size, ")"));
            // '-> circle of the largest diameter (fragments computed from the real radius),
            //     scaled down along the other axis for an ellipse
            scale([_size[0]/_D, _size[1]/_D])
                circle(d=_D, $fn = is_undef(_fn) ? $fn : _fn);
        }
}

// outline of a circle with the radius 'R' (points)
// - 'fn', 'polygon_mode', 'sector', 'cross_section' as the arguments of circlepp
function __spp_circle_shape(R, fn, polygon_mode, sector, cross_section, ctx) =
    let(
        sec = __spp_resolve_section(cross_section, "z", ctx, "cross_section", "Y"),
        _sector = __spp_check_sector(sector, "z", ctx),
        _fn = __spp_wall_sides(fn, polygon_mode, R, ctx),
        n = is_undef(_fn) ? __spp_fragments(R) : _fn
    )
    assert(is_undef(_sector) || __spp_is_plain_section(sec),
        str("[", ctx, "] 'sector' cannot be combined with 'cross_section'"))
    !is_undef(_sector) ?
        let(
            k = __spp_polygon_scale(polygon_mode, n, ctx),
            m = max(1, ceil(n * _sector[1] / 360))
        )
        concat([[0, 0]], [for (i = [0:1:m]) let(a = _sector[0] + _sector[1]*i/m) k*R*[cos(a), sin(a)]]) :
        let(O = __spp_section_outline(R, n, sec[0], polygon_mode, ctx))
        is_undef(sec[1]) ?
            O :
            let(sr = sec[1])
            assert(sr[1] < 0.5*R,
                str("[", ctx, "] serration: the depth ", sr[1], " is too large for the radius ", R))
            __spp_serrate(O, __spp_serration_plan(O, sr, sec[0], R, ctx), sr);
