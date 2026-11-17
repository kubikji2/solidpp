// Edge and corner modifiers: bevel(), rounding(), bevel_corners()
//
// A modifier is plain data, the solid interprets it (see DESIGN.md, section 3):
//   ["__SPP_EDGE_MOD__", kind, value, [tokens] (, name)]          kind: "bevel" | "rounding"
//   ["__SPP_CORNER_MOD__", "bevel_corners", [x,y,z], [tokens] (, name)]
// - name      optional: the name the user called (an alias such as "fillet"), used in messages;
//             without it, messages use the kind
// - value     [across, along] or [x, y, z] (cubepp only); positive removes material,
//             negative adds a flare into the base plane, all zeros is a no-op
// - tokens    list of edge/corner selectors, e.g. ["t"], ["ti", "bo"], ["all"]
//
// NOTE: 'rounding' is not called 'round' because round() is an OpenSCAD built-in.

__SPP_EDGE_MOD_ID = "__SPP_EDGE_MOD__";
__SPP_CORNER_MOD_ID = "__SPP_CORNER_MOD__";

// index of the fields
__SPP_EDGE_MOD_KIND_IDX = 1;
__SPP_EDGE_MOD_VALUE_IDX = 2;
__SPP_EDGE_MOD_WHERE_IDX = 3;
__SPP_EDGE_MOD_NAME_IDX = 4;

// name of a modifier for messages: the alias the user called, or the kind
function __spp_mod_name(m) = len(m) > __SPP_EDGE_MOD_NAME_IDX ? m[__SPP_EDGE_MOD_NAME_IDX] : m[__SPP_EDGE_MOD_KIND_IDX];

// the record 'm' with the name of 'src' (a record rebuilt by the engine keeps the alias)
function __spp_mod_keep_name(m, src) =
    len(src) > __SPP_EDGE_MOD_NAME_IDX ? concat([for (i = [0:3]) m[i]], [src[__SPP_EDGE_MOD_NAME_IDX]]) : m;

// the call as the user wrote it, for messages, e.g. fillet(5), flare(2, where=["b"])
// - 'shown' the value to show (the stored value by default)
function __spp_mod_call(m, shown=undef) =
    let(
        name = __spp_mod_name(m),
        v0 = is_undef(shown) ? m[__SPP_EDGE_MOD_VALUE_IDX] : shown,
        // equal components are shown as the single number the user most likely wrote
        v = is_list(v0) && len([for (x = v0) if (x != v0[0]) 1]) == 0 ? v0[0] : v0,
        flare = name == "flare",
        where = m[__SPP_EDGE_MOD_WHERE_IDX]
    )
    str(name, "(", flare ? -v : v,
        flare && m[__SPP_EDGE_MOD_KIND_IDX] == "bevel" ? ", kind=\"bevel\"" : "",
        where == ["all"] ? "" : str(", where=", where), ")");


// chamfer the selected edges
// - argument 'd' is a number, [across, along] or [x, y, z] (cubepp only)
//   '-> 'across' is measured in the base plane, 'along' along the solid axis ('zet')
//   '-> [x, y, z] are the extents along the axes of the parent frame
//   '-> negative values add a chamfered flare into the base plane
// - argument 'where' is a string or a list of strings selecting the edges
function bevel(d, where="all") = __spp_new_edge_mod("bevel", d, where, "BEVEL");


// round (fillet) the selected edges
// - argument 'r' is a number (circle), [across, along] or [x, y, z] (ellipse semi-axes)
//   '-> negative values add a concave fillet into the base plane
// - argument 'where' is a string or a list of strings selecting the edges
function rounding(r, where="all") = __spp_new_edge_mod("rounding", r, where, "ROUNDING");


// aliases (CAD names); the records remember the alias for the messages
// - chamfer(d, where):          bevel(d, where)
// - fillet(r, where):           rounding(r, where)
// - chamfer_corners(d, where):  bevel_corners(d, where)
// - flare(r, where, kind):      rounding(-r, where) ("rounding", default) or bevel(-r, where)
//   ('kind' "bevel"); 'r' is positive: material added into the base (a base plane of a solid, the
//   base side of a 2D shape: the first name of a token)
function chamfer(d, where="all") = __spp_mod_alias(bevel(d, where), "chamfer");
function fillet(r, where="all") = __spp_mod_alias(rounding(r, where), "fillet");
function chamfer_corners(d, where="all") = __spp_mod_alias(bevel_corners(d, where), "chamfer_corners");
function flare(r, where="all", kind="rounding") =
    assert(kind == "rounding" || kind == "bevel",
        str("[FLARE] argument 'kind' must be \"rounding\" or \"bevel\", got ", kind))
    assert(is_num(r) ? r > 0 : (is_list(r) && len([for (x = r) if (!is_num(x) || x <= 0) 1]) == 0),
        str("[FLARE] argument 'r' must be positive (the size of the flare), got ", r))
    __spp_mod_alias(kind == "rounding" ? rounding(-r, where) : bevel(-r, where), "flare");

function __spp_mod_alias(m, name) = concat(m, [name]);


// cut the selected corners of cubepp by a plane
// - argument 'd' is a positive number or [x, y, z]: distances of the cut from the corner
//   along the edges (axes of the parent frame)
// - argument 'where' selects corners, e.g. "all", "t", "X", "xY", "txY"
// - argument 'bevel' is the deprecated name of 'd'
function bevel_corners(d=undef, where="all", bevel=undef) =
    let(
        _d = is_undef(d) ? bevel : d,
        _v = is_num(_d) ? [_d, _d, _d] : _d,
        _w = __spp_edge_mod_where(where),
        _dep = is_undef(bevel) ?
                0 :
                echo(str("[BEVEL_CORNERS] DEPRECATED: argument 'bevel' -> use bevel_corners(d=", bevel, ")")) 0
    )
    assert(is_undef(d) || is_undef(bevel), "[BEVEL_CORNERS] use either 'd' or 'bevel', not both")
    assert(is_list(_v) && len(_v) == 3 && is_num(_v[0]) && is_num(_v[1]) && is_num(_v[2]) &&
           _v[0] > 0 && _v[1] > 0 && _v[2] > 0,
        str("[BEVEL_CORNERS] argument 'd' must be a positive number or a list of 3 positive numbers, got ", _d))
    assert(!is_undef(_w),
        str("[BEVEL_CORNERS] argument 'where' must be a string or a non-empty list of strings, got ", where))
    [__SPP_CORNER_MOD_ID, "bevel_corners", _v, _w];


// __private__ value as a list of 2 or 3 numbers, or undef if invalid
function __spp_edge_mod_value(v) =
    is_num(v) ?
        [v, v] :
        is_list(v) && (len(v) == 2 || len(v) == 3) && len([for (x = v) if (!is_num(x)) 1]) == 0 ?
            v :
            undef;


// __private__ 'where' as a non-empty list of strings or undef if invalid
function __spp_edge_mod_where(where) =
    is_string(where) ?
        [where] :
        is_list(where) && len(where) > 0 && len([for (w = where) if (!is_string(w)) 1]) == 0 ?
            where :
            undef;


// __private__ modifier constructor shared by bevel() and rounding()
function __spp_new_edge_mod(kind, value, where, name) =
    let(
        _v = __spp_edge_mod_value(value),
        _w = __spp_edge_mod_where(where)
    )
    assert(!is_undef(_v),
        str("[", name, "] value must be a number, [across, along] or [x, y, z], got ", value))
    assert(!is_undef(_w),
        str("[", name, "] argument 'where' must be a string or a non-empty list of strings, got ", where))
    assert(len([for (x = _v) if (x == 0) 1]) == 0 || len([for (x = _v) if (x != 0) 1]) == 0,
        str("[", name, "] components must be all zero or all non-zero, got ", _v))
    assert(len([for (x = _v) if (x > 0) 1]) == 0 || len([for (x = _v) if (x < 0) 1]) == 0,
        str("[", name, "] components must have the same sign, got ", _v))
    [__SPP_EDGE_MOD_ID, kind, _v, _w];


// returns true iff 'mod' is an edge modifier created by bevel() or rounding()
function __spp_is_edge_mod(mod) =
    is_list(mod) &&
    (len(mod) == 4 || (len(mod) == 5 && is_string(mod[4]))) &&
    mod[0] == __SPP_EDGE_MOD_ID;

// returns true iff 'mod' is a corner modifier created by bevel_corners()
function __spp_is_corner_mod(mod) =
    is_list(mod) &&
    (len(mod) == 4 || (len(mod) == 5 && is_string(mod[4]))) &&
    mod[0] == __SPP_CORNER_MOD_ID;

// value of an edge modifier as [across, along] for revolved solids
function __spp_edge_mod_pair(mod, ctx) =
    let(v = mod[__SPP_EDGE_MOD_VALUE_IDX])
    assert(len(v) == 2,
        str("[", ctx, "] value [x, y, z] is supported only by cubepp, use a number or [across, along], got ", v))
    v;
