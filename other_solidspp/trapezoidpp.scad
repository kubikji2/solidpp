include<../utils/solidpp_utils.scad>
include<../cubepp.scad>

// DEPRECATED: use cubepp(size=[bottom, h], size_top=[a, b]) (a tapered cubepp, with modifiers)
// - argument 'base' is the size of the bottom base [a, b] (default [1, 1])
// - argument 'top' is the size of the top base [a, b] (default [0.5, 0.5])
// - argument 'h' is the height along 'zet' (default 1)
// - arguments 'align', 'zet', 'center' as in cubepp
// '-> [a, b] are along the local x/y axes of the 'zet' frame (as the old polyhedron was built)
// '-> translated to cubepp with an echo showing the replacement call
module trapezoid(base=undef, top=undef, h=undef, align=undef, zet=undef, center=false)
{
    // module name
    __module_name = "TRAPEZOID";

    __solidpp__assert_2D_vector_like(base, "base" , __module_name);
    __solidpp__assert_2D_vector_like(top, "top" , __module_name);
    assert(is_undef(h) || is_num(h), str("[", __module_name, "] argument 'h' must be either 'undef' or a number.") );

    _base = __solidpp__get_argument_as_2Dlist(base, [1, 1]);
    _top = __solidpp__get_argument_as_2Dlist(top, [0.5, 0.5]);
    _h = is_undef(h) ? 1 : h;
    _zet = __spp_check_zet(zet, __module_name);

    // bottom size in the parent frame, top base [a, b] perpendicular to 'zet'
    _size_bottom = __spp_box_to_parent_extents([_base[0], _base[1], _h], _zet);
    _size_top = __spp_box_size_to_base(__spp_box_to_parent_extents([_top[0], _top[1], _h], _zet), _zet);

    echo(str("[", __module_name, "] DEPRECATED: ",
             __spp_legacy_call("trapezoid", ["base", base, "top", top, "h", h, "zet", zet]),
             " -> use cubepp(size=", _size_bottom, ", size_top=", _size_top,
             _zet == "z" || _zet == "Z" ? "" : str(", zet=\"", _zet, "\""), ")"));

    cubepp(size=_size_bottom, size_top=_size_top, align=align, zet=_zet, center=center);
}
