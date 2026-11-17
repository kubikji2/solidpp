include<../utils/solidpp_utils.scad>
include<../engine/revolved.scad>

// just like 'linear_extrude',
// '-> but argument 'height' can be also negative which will cause object to be 'Z'-aligned rather
//     then 'z'-aligned as usual
// '-> moreover, the object is rotated to compensate for the 'twist' to create continous alignment
//     '-> compensation can be turned off by setting 'compensate_rotation' to false
// '-> argument 'zet' extrudes along "x", "y" or "z" (default); the 2D children are turned like every
//     solidpp solid (zet "x": rotate([0, 90, 0]), zet "y": rotate([-90, 0, 0]))
module linear_extrudepp(height = 5,
                        center = false,
                        convexity = 10,
                        twist = 0,
                        slices = 20,
                        scale = 1.0,
                        compensate_rotation=true,
                        zet = undef)
{
    _zet = __spp_check_zet(zet, "LINEAR_EXTRUDE++");

    // detecting negative height
    _is_negative = height < 0;
    // parsing the height
    _h = abs(height);

    // compose translation and rotation
    _t = _is_negative ? [0, 0, -_h] : [0,0,0];
    _r = (_is_negative && compensate_rotation) ? twist : 0;

    // constructing the geometry
    rotate(__solidpp__get_rotation_from_zet(_zet, [0, 0, 0]))
    translate(_t)
    rotate(_r)
    linear_extrude( height = _h,
                    center = center,
                    convexity = convexity,
                    twist = twist,
                    slices = slices,
                    scale = scale)
    {
        children();
    }
}

// just like 'rotate_extrude', with the solidpp conventions
// - the 2D children lie in x >= 0 (x is the distance from the axis, y the position along it)
// - argument 'zet' the axis: "x", "y" or "z" (default), turned like every solidpp solid
// - argument 'sector' an angle or [from, to]: a part of the revolution, the angles as for the
//   'sector' of the solids (right-hand rule around 'zet', 0 is +x for zet "z", +y for "x", +z for "y")
// - argument 'fn' the number of sides (undef: $fn/$fa/$fs)
// - argument 'convexity' as in rotate_extrude (default 10)
// NOTE: OpenSCAD cannot measure the children, so there is no alignment; use transform_to_spp
module rotate_extrudepp(zet=undef, sector=undef, fn=undef, convexity=10)
{
    __module_name = "ROTATE_EXTRUDE++";
    _zet = __spp_check_zet(zet, __module_name);
    _fn = __spp_check_fn(fn, "fn", __module_name);
    _sector = __spp_check_sector(sector, _zet, __module_name);

    rotate(__solidpp__get_rotation_from_zet(_zet, [0, 0, 0]))
        if (is_undef(_sector))
            rotate_extrude(convexity=convexity, $fn = is_undef(_fn) ? $fn : _fn)
                children();
        else
            rotate([0, 0, _sector[0]])
                rotate_extrude(angle=_sector[1], convexity=convexity, $fn = is_undef(_fn) ? $fn : _fn)
                    children();
}
