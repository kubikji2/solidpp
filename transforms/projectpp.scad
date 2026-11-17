include<../utils/solidpp_utils.scad>
include<../engine/frame.scad>

// projection onto any plane
// - argument 'point' a point of the plane (default the origin)
// - argument 'normal' the normal of the plane: a 3D vector or a face letter "x", "X", "y", "Y", "z",
//   "Z" (default [0, 0, 1], as projection())
//   '-> the result is seen from the side the normal points to: for "Z" (or [0, 0, 1]) x and y stay,
//       for "X" the 2D x is +y and the 2D y is +z, for "z" (from below) the 2D x is -x
// - argument 'cut' as in projection(): false (default) the shadow of the whole object, true only the
//   section in the plane
// e.g. projectpp(point=[0, 0, 5], cut=true) children();  // section at z = 5
module projectpp(point=[0, 0, 0], normal=[0, 0, 1], cut=false)
{
    __module_name = "PROJECT++";

    assert(__solidpp__is_list_of_numbers(point) && len(point) == 3,
        str("[", __module_name, "] argument 'point' must be a point [x, y, z], got ", point));
    _n = is_string(normal) ? __spp_letter_vector(normal) : normal;
    assert(is_string(normal) ? !is_undef(_n) && len(normal) == 1 :
           __solidpp__is_list_of_numbers(normal) && len(normal) == 3 && norm(normal) > 0,
        str("[", __module_name, "] argument 'normal' must be a non-zero vector [x, y, z] or one of \"x\", \"X\", ",
            "\"y\", \"Y\", \"z\", \"Z\", got ", normal));
    assert(is_bool(cut), str("[", __module_name, "] argument 'cut' must be a boolean, got ", cut));

    projection(cut=cut)
        multmatrix(__spp_frame_inverse(__spp_frame(point, _n / norm(_n))))
            children();
}
