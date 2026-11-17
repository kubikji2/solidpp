// Section shapes: teardrop() and serration()
//
// A cross-section describes the shape of a wall perpendicular to the 'zet' axis of
// cylinderpp ('cross_section') and tubepp ('outer_cross_section', 'inner_cross_section'):
//   - at most one base shape: the circle (default) or teardrop()
//   - optionally followed by serration()
// e.g. cross_section=teardrop(), cross_section=serration(8, 0.2), cross_section=[teardrop(cap="bridge"), serration(8, 0.2)]
//
// Records:
//   ["__SPP_SECTION__", "teardrop", up, angle, cap]
//   ["__SPP_SECTION__", "serration", n, depth, profile, width]

__SPP_SECTION_ID = "__SPP_SECTION__";


// teardrop shape for holes printed horizontally (no support needed)
// - argument 'up' is the face letter of the parent frame the tip points to
//   ("x", "X", "y", "Y", "z", "Z"; lowercase = low side as in 'align')
//   '-> it must be perpendicular to 'zet'
//   '-> undef: "Z" (printing up) if zet is "x" or "y", "x" if zet is "z"
// - argument 'angle' is the angle of the tip faces from the horizontal (default 45)
// - argument 'cap' is "point" (classic teardrop) or "bridge" (tip cut flat at the top
//   of the circle, the hole stays within its diameter and the flat part is a short bridge)
function teardrop(up=undef, angle=45, cap="point") =
    assert(is_undef(up) || (is_string(up) && len(up) == 1),
        str("[TEARDROP] argument 'up' must be one of \"x\", \"X\", \"y\", \"Y\", \"z\", \"Z\", got ", up))
    assert(is_num(angle) && angle > 0 && angle < 90,
        str("[TEARDROP] argument 'angle' must be a number in (0, 90), got ", angle))
    assert(cap == "point" || cap == "bridge",
        str("[TEARDROP] argument 'cap' must be \"point\" or \"bridge\", got ", cap))
    [__SPP_SECTION_ID, "teardrop", up, angle, cap];


// serration: 'n' grooves along the axis cut into the wall (only along its straight part)
// - 'd' of the solid is measured at the tips; on a hole the grooves of the cut-out
//   leave ribs in the hole (crush ribs for press fits)
// - argument 'depth' is the depth of the grooves
// - argument 'profile' is "triangle" (zig-zag, knurl-like) or "round" (round grooves)
// - argument 'width' is the width of a round groove (default 2*depth, a half circle)
function serration(n, depth, profile="triangle", width=undef) =
    assert(is_num(n) && n >= 2 && n == floor(n),
        str("[SERRATION] argument 'n' must be an integer >= 2, got ", n))
    assert(is_num(depth) && depth > 0,
        str("[SERRATION] argument 'depth' must be a positive number, got ", depth))
    assert(profile == "triangle" || profile == "round",
        str("[SERRATION] argument 'profile' must be \"triangle\" or \"round\", got ", profile))
    assert(is_undef(width) || (is_num(width) && width > 0),
        str("[SERRATION] argument 'width' must be a positive number, got ", width))
    assert(is_undef(width) || profile == "round",
        "[SERRATION] argument 'width' is used only by the \"round\" profile")
    [__SPP_SECTION_ID, "serration", n, depth, profile, width];


function __spp_is_section(s) = is_list(s) && len(s) >= 2 && s[0] == __SPP_SECTION_ID;
