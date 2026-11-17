include<../utils/solidpp_utils.scad>
include<../engine/revolved.scad>

// just a really big number
__solidpp_big_m = 1000;

// cuts a wedge (a sector around an axis) out of the children, e.g. for cut-away views
// - argument 'sector' the angles of the removed wedge, as for the 'sector' of the solids
//   (right-hand rule around 'zet'; 0 is +x for zet "z", +y for "x", +z for "y"):
//   '-> a positive angle a: [0, a]; a negative angle a: [a, 0]
//   '-> [from, to]: from 'from' counter-clockwise to 'to'; if 'to' is smaller, it wraps around
//       ([90, -90] removes the half from 90 to 270, [-90, 90] the half from -90 to 90)
// - argument 'zet' the axis: "x", "y" or "z" (default)
// - argument 'point' a point of the axis (default the origin)
// - argument 'size' the size of the wedge: a number or [x, y, z], its largest value is used as
//   the radius and the height (default 1000)
// - arguments 'align', 'center' are deprecated: they never had an effect
module cut(sector, align=undef, zet=undef, size=undef, center=undef, point=undef)
{
    // set module name
    __module_name = "CUT";

    if (!is_undef(align) || !is_undef(center))
        echo(str("[", __module_name, "] DEPRECATED: 'align' and 'center' have no effect, remove them; ",
                 "use 'point' to move the axis"));

    _s = __spp_cut_sector(sector, __module_name);
    _zet = __spp_check_zet(zet, __module_name);
    _size = __solidpp__get_argument_as_3Dlist(size, [__solidpp_big_m, __solidpp_big_m, __solidpp_big_m]);
    _m = max(_size);
    _p = is_undef(point) ? [0, 0, 0] : point;
    assert(__solidpp__is_list_of_numbers(_p) && len(_p) == 3,
        str("[", __module_name, "] argument 'point' must be a point [x, y, z], got ", point));

    difference()
    {
        children();

        translate(_p)
            rotate(__solidpp__get_rotation_from_zet(_zet, [0, 0, 0]))
                rotate([0, 0, __spp_sector_ref(_zet) + _s[0]])
                    translate([0, 0, -_m/2])
                        rotate_extrude(angle=_s[1] - _s[0])
                            polygon([[0, 0], [_m, 0], [_m, _m], [0, _m]]);
    }
}

// [from, to] of the removed wedge (to > from, at most 360 apart)
function __spp_cut_sector(sector, ctx) =
    assert(is_num(sector) || (is_list(sector) && len(sector) == 2 && is_num(sector[0]) && is_num(sector[1])),
        str("[", ctx, "] argument 'sector' must be an angle or [from, to], got ", sector))
    let(s = is_num(sector) ? (sector >= 0 ? [0, sector] : [sector, 0]) : sector)
    assert(s[0] != s[1] && abs(s[1] - s[0]) <= 360,
        str("[", ctx, "] argument 'sector' must cover more than 0 and at most 360 degrees, got ", sector))
    s[1] > s[0] ? s : [s[0], s[1] + 360];
