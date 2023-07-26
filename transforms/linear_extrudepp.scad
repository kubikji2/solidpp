

// just like 'linear_extrude',
// '-> but argument 'height' can be also negative which will cause object to be 'Z'-aligned rather
//     then 'z'-aligned as usual
// '-> moreover, the object is rotated to compensate for the 'twist' to create continous alignment
//     '-> compensation can be turned off by setting 'compensate_rotation' to false  
module linear_extrudepp(height = 5,
                        center = false,
                        convexity = 10,
                        twist = 0,
                        slices = 20,
                        scale = 1.0,
                        compensate_rotation=true)
{
    // detecting negative height
    _is_negative = height < 0;
    // parsing the height
    _h = abs(height);

    // compose translation and rotation
    _t = _is_negative ? [0, 0, -_h] : [0,0,0];
    _r = (_is_negative && compensate_rotation) ? twist : 0;

    // constructing the geometry
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
