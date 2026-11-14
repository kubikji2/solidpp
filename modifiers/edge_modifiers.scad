// Edge modifiers: bevel() and rounding()
//
// A modifier is plain data, the solid interprets it (see DESIGN.md, section 3):
//   ["__SPP_EDGE_MOD__", kind, [across, along], [tokens]]
// - kind      "bevel" | "rounding"
// - value     [across, along]; positive removes material, negative adds a flare
//             into the base plane, [0, 0] is a no-op
// - tokens    list of edge selectors, e.g. ["t"], ["ti", "bo"], ["all"]
//
// NOTE: 'rounding' is not called 'round' because round() is an OpenSCAD built-in.

__SPP_EDGE_MOD_ID = "__SPP_EDGE_MOD__";

// index of the fields
__SPP_EDGE_MOD_KIND_IDX = 1;
__SPP_EDGE_MOD_VALUE_IDX = 2;
__SPP_EDGE_MOD_WHERE_IDX = 3;


// chamfer the selected edges
// - argument 'd' is a number or [across, along]
//   '-> 'across' is measured in the base plane, 'along' along the solid axis
//   '-> negative values add a chamfered flare into the base plane
// - argument 'where' is a string or a list of strings selecting the edges
function bevel(d, where="all") = __spp_new_edge_mod("bevel", d, where, "BEVEL");


// round (fillet) the selected edges
// - argument 'r' is a number (circle) or [across, along] (ellipse semi-axes)
//   '-> negative values add a concave fillet into the base plane
// - argument 'where' is a string or a list of strings selecting the edges
function rounding(r, where="all") = __spp_new_edge_mod("rounding", r, where, "ROUNDING");


// __private__ value as [across, along] or undef if invalid
function __spp_edge_mod_value(v) =
    is_num(v) ?
        [v, v] :
        is_list(v) && len(v) == 2 && is_num(v[0]) && is_num(v[1]) ?
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
        str("[", name, "] value must be a number or [across, along], got ", value))
    assert(!is_undef(_w),
        str("[", name, "] argument 'where' must be a string or a non-empty list of strings, got ", where))
    assert((_v[0] == 0) == (_v[1] == 0),
        str("[", name, "] components must be both zero or both non-zero, got ", _v))
    assert(_v[0] * _v[1] >= 0,
        str("[", name, "] components must have the same sign, got ", _v))
    [__SPP_EDGE_MOD_ID, kind, _v, _w];


// returns true iff 'mod' is an edge modifier created by bevel() or rounding()
function __spp_is_edge_mod(mod) =
    is_list(mod) &&
    len(mod) == 4 &&
    mod[0] == __SPP_EDGE_MOD_ID;


// returns true iff 'mod' looks like a modifier of the old API (round_bases, ...)
function __spp_is_legacy_mod(mod) =
    is_list(mod) &&
    len(mod) > 0 &&
    is_string(mod[0]) &&
    mod[0] != __SPP_EDGE_MOD_ID &&
    len(mod[0]) > 2 &&
    mod[0][0] == "_" && mod[0][1] == "_";


// checks 'mod_list' of a solid using edge modifiers and returns it as a list
// '-> 'undef' results in an empty list
function __spp_check_edge_mod_list(mod_list, name) =
    is_undef(mod_list) ?
        [] :
        assert(is_list(mod_list),
            str("[", name, "] argument 'mod_list' must be a list of modifiers, got ", mod_list))
        let(
            _legacy = [for (m = mod_list) if (__spp_is_legacy_mod(m)) m],
            _invalid = [for (m = mod_list) if (!__spp_is_edge_mod(m)) m]
        )
        assert(len(_legacy) == 0,
            str("[", name, "] old modifiers (round_bases, bevel_bases, round_corners, ...) are not supported, ",
                "use bevel(d, where) and rounding(r, where) instead"))
        assert(len(_invalid) == 0,
            str("[", name, "] 'mod_list' contains invalid modifiers: ", _invalid))
        mod_list;
