// Backward compatibility of the old modifiers
//
// The old constructors (round_corners, round_edges, round_bases, bevel_edges, bevel_bases)
// keep their signatures. They return a legacy record that every solid translates to the
// new modifiers, printing a "DEPRECATED" echo with the replacement:
//   ["__SPP_LEGACY_MOD__", name, data, description of the call]
//
// Notes on the translation (see DESIGN.md, section 6):
// - old modifiers were applied from the last to the first; a mod_list made only of old
//   modifiers is reversed to keep the result
// - bevel <= 0 was silently ignored, it is skipped with an echo
// - tubepp 'inner_mod_list' modified the cylinder cut out of the tube: a bevel of the
//   cut-out adds material into the hole, i.e. it becomes a negative (flare) modifier of
//   the inner edges

include<edge_modifiers.scad>
include<../engine/profile.scad>

__SPP_LEGACY_MOD_ID = "__SPP_LEGACY_MOD__";


// ------------------------------------------------------------------ old constructors

function round_corners(r=undef, d=undef) =
    [__SPP_LEGACY_MOD_ID, "round_corners",
        [__spp_legacy_r(r, d, "round_corners")],
        __spp_legacy_call("round_corners", ["r", r, "d", d])];

function round_edges(r=undef, d=undef, axes="xy") =
    [__SPP_LEGACY_MOD_ID, "round_edges",
        [__spp_legacy_r(r, d, "round_edges"), __spp_legacy_axes(axes, "round_edges")],
        __spp_legacy_call("round_edges", ["r", r, "d", d, "axes", axes])];

function bevel_edges(bevel, axes="xyz") =
    [__SPP_LEGACY_MOD_ID, "bevel_edges",
        [__spp_legacy_value(bevel, "bevel_edges"), __spp_legacy_axes(axes, "bevel_edges")],
        __spp_legacy_call("bevel_edges", ["bevel", bevel, "axes", axes])];

function round_bases(r=undef, d=undef, axis="z", r_bottom=undef, d_bottom=undef, r_top=undef, d_top=undef) =
    let(
        _both = !is_undef(r) || !is_undef(d),
        _rb = _both ? __spp_legacy_r(r, d, "round_bases") :
              (is_undef(r_bottom) && is_undef(d_bottom) ? undef : __spp_legacy_r(r_bottom, d_bottom, "round_bases")),
        _rt = _both ? __spp_legacy_r(r, d, "round_bases") :
              (is_undef(r_top) && is_undef(d_top) ? undef : __spp_legacy_r(r_top, d_top, "round_bases"))
    )
    assert(!(_both && (!is_undef(r_bottom) || !is_undef(d_bottom) || !is_undef(r_top) || !is_undef(d_top))),
        "[round_bases] 'r|d' cannot be combined with 'r_bottom|d_bottom' or 'r_top|d_top'")
    assert(!is_undef(_rb) || !is_undef(_rt), "[round_bases] 'r|d', 'r_bottom|d_bottom' or 'r_top|d_top' must be defined")
    [__SPP_LEGACY_MOD_ID, "round_bases", [_rb, _rt, __spp_legacy_axis(axis, "round_bases")],
        __spp_legacy_call("round_bases", ["r", r, "d", d, "axis", axis, "r_bottom", r_bottom, "d_bottom", d_bottom,
                                          "r_top", r_top, "d_top", d_top])];

function bevel_bases(bevel=undef, axis="z", bevel_bottom=undef, bevel_top=undef) =
    let(
        _both = !is_undef(bevel),
        _bb = _both ? __spp_legacy_value(bevel, "bevel_bases") :
              (is_undef(bevel_bottom) ? undef : __spp_legacy_value(bevel_bottom, "bevel_bases")),
        _bt = _both ? __spp_legacy_value(bevel, "bevel_bases") :
              (is_undef(bevel_top) ? undef : __spp_legacy_value(bevel_top, "bevel_bases"))
    )
    assert(!(_both && (!is_undef(bevel_bottom) || !is_undef(bevel_top))),
        "[bevel_bases] 'bevel' cannot be combined with 'bevel_bottom' or 'bevel_top'")
    assert(!is_undef(_bb) || !is_undef(_bt), "[bevel_bases] 'bevel', 'bevel_bottom' or 'bevel_top' must be defined")
    [__SPP_LEGACY_MOD_ID, "bevel_bases", [_bb, _bt, __spp_legacy_axis(axis, "bevel_bases")],
        __spp_legacy_call("bevel_bases", ["bevel", bevel, "axis", axis, "bevel_bottom", bevel_bottom,
                                          "bevel_top", bevel_top])];


// ------------------------------------------------------------------ helpers

function __spp_is_legacy_mod(mod) =
    is_list(mod) && len(mod) == 4 && mod[0] == __SPP_LEGACY_MOD_ID;

// value: number, [a, b] or [x, y, z]
function __spp_legacy_value(v, name) =
    assert(is_num(v) ||
           (is_list(v) && (len(v) == 2 || len(v) == 3) && len([for (x = v) if (!is_num(x)) 1]) == 0),
        str("[", name, "] value must be a number, a list of 2 or 3 numbers, got ", v))
    v;

// radius from 'r' or 'd'
function __spp_legacy_r(r, d, name) =
    assert(is_undef(r) || is_undef(d), str("[", name, "] use either 'r' or 'd', not both"))
    assert(!is_undef(r) || !is_undef(d), str("[", name, "] argument 'r' or 'd' must be defined"))
    !is_undef(r) ? __spp_legacy_value(r, name) : __spp_legacy_value(d, name) / 2;

// axes as a list of axis indices
function __spp_legacy_axes(axes, name) =
    assert(is_string(axes), str("[", name, "] argument 'axes' must be a string, got ", axes))
    let(m = [for (k = [0:2]) if (__spp_char_in(["x", "y", "z"][k], axes) || __spp_char_in(["X", "Y", "Z"][k], axes)) k])
    assert(len(m) > 0, str("[", name, "] argument 'axes' must contain at least one axis, got ", axes))
    m;

// axis as an index
function __spp_legacy_axis(axis, name) =
    let(m = __spp_legacy_axes(axis, name))
    assert(len(m) == 1, str("[", name, "] argument 'axis' must be a single axis, got ", axis))
    m[0];

// description of the call from [name, value, ...], skipping undefined arguments
function __spp_legacy_call(fname, args) =
    let(parts = [for (i = [0:2:len(args)-1]) if (!is_undef(args[i+1]))
                    is_string(args[i+1]) ? str(args[i], "=\"", args[i+1], "\"") : str(args[i], "=", args[i+1])])
    str(fname, "(", __spp_join(parts, ", "), ")");

function __spp_join(l, sep, idx=0) =
    idx >= len(l) ? "" : str(l[idx], idx < len(l)-1 ? sep : "", __spp_join(l, sep, idx+1));

// text of a new modifier, e.g. rounding(1, "t")
function __spp_mod_text(m) =
    let(w = m[__SPP_EDGE_MOD_WHERE_IDX], v = m[__SPP_EDGE_MOD_VALUE_IDX])
    str(m[1], "(",
        len(v) == 2 && v[0] == v[1] ? v[0] : v,
        w == ["all"] ? "" : str(", ", len(w) == 1 ? str("\"", w[0], "\"") : w),
        ")");

// [x, y, z] from the old [a, h] of a base along 'axis' (index)
function __spp_legacy_expand_ah(v, axis) =
    axis == 0 ? [v[1], v[0], v[0]] : (axis == 1 ? [v[0], v[1], v[0]] : [v[0], v[0], v[1]]);

// positive value for bevels, the old code ignored non-positive bevels
function __spp_legacy_positive(v) = is_num(v) ? v > 0 : len([for (x = v) if (x <= 0) 1]) == 0;


// ------------------------------------------------------------------ translation

// new modifiers of a legacy modifier for the box family (cubepp)
function __spp_legacy_to_box(lm) =
    let(name = lm[1], data = lm[2], X = ["x", "y", "z"], XU = ["X", "Y", "Z"])
    name == "round_corners" ?
        [rounding(data[0])] :
        name == "round_edges" || name == "bevel_edges" ?
            let(
                kind = name == "round_edges" ? "rounding" : "bevel",
                v = data[0],
                axes = data[1]
            )
            assert(len(axes) != 3 || is_num(v) || len(v) == 3,
                str("[", name, "] value for three axes must be a number or [x, y, z], got ", v))
            assert(len(axes) != 2 || is_num(v) || len(v) == 2,
                str("[", name, "] value for two axes must be a number or a list of 2 numbers, got ", v))
            len(axes) == 3 ?
                [__spp_new_edge_mod(kind, v, "all", name)] :
                len(axes) == 2 ?
                    let(
                        k = [for (a = [0:2]) if (!__spp_in_list(a, axes)) a][0],
                        // components of the two axes, the third one is unused
                        v3 = is_num(v) ? v : [for (a = [0:2]) a == axes[0] ? v[0] : (a == axes[1] ? v[1] : v[0])]
                    )
                    [__spp_new_edge_mod(kind, v3, str(X[k], "-edges"), name)] :
                    [__spp_new_edge_mod(kind, v, [X[axes[0]], XU[axes[0]]], name)] :
            // round_bases, bevel_bases
            let(
                kind = name == "round_bases" ? "rounding" : "bevel",
                axis = data[2],
                conv = function(v) is_num(v) || len(v) == 3 ? v : __spp_legacy_expand_ah(v, axis),
                vb = data[0],
                vt = data[1],
                use_b = !is_undef(vb) && (kind == "rounding" || __spp_legacy_positive(vb)),
                use_t = !is_undef(vt) && (kind == "rounding" || __spp_legacy_positive(vt))
            )
            use_b && use_t && vb == vt ?
                [__spp_new_edge_mod(kind, conv(vb), [X[axis], XU[axis]], name)] :
                [   if (use_b) __spp_new_edge_mod(kind, conv(vb), X[axis], name),
                    if (use_t) __spp_new_edge_mod(kind, conv(vt), XU[axis], name)];

// new modifiers of a legacy modifier for the revolved family (cylinderpp, tubepp)
function __spp_legacy_to_revolved(lm, ctx) =
    let(
        name = lm[1],
        data = lm[2],
        // [across, along] from a number, [a, h] or [x, y, z]
        conv = function(v) is_num(v) || len(v) == 2 ? v : [v[0], v[2]]
    )
    assert(name != "round_edges" && name != "bevel_edges",
        str("[", ctx, "] ", lm[3], " is not supported, use bevel(d, where) or rounding(r, where)"))
    name == "round_corners" ?
        [rounding(conv(data[0]))] :
        let(
            kind = name == "round_bases" ? "rounding" : "bevel",
            vb = data[0],
            vt = data[1],
            use_b = !is_undef(vb) && (kind == "rounding" || __spp_legacy_positive(vb)),
            use_t = !is_undef(vt) && (kind == "rounding" || __spp_legacy_positive(vt))
        )
        use_b && use_t && vb == vt ?
            [__spp_new_edge_mod(kind, conv(vb), ["b", "t"], name)] :
            [   if (use_b) __spp_new_edge_mod(kind, conv(vb), "b", name),
                if (use_t) __spp_new_edge_mod(kind, conv(vt), "t", name)];

// translates one legacy modifier with an echo
function __spp_legacy_translate(lm, family, ctx) =
    let(
        out = family == "box" ? __spp_legacy_to_box(lm) : __spp_legacy_to_revolved(lm, ctx),
        _msg = echo(str("[", ctx, "] DEPRECATED: ", lm[3], " -> ",
                        len(out) == 0 ?
                            "no effect (non-positive bevel), remove it" :
                            str("use ", __spp_join([for (m = out) __spp_mod_text(m)], ", "))))
               0
    )
    out;

// restricts modifiers of the old tubepp 'inner_mod_list'/'outer_mod_list' to inner/outer edges
// '-> inner modifiers changed the cut-out cylinder, so their values are negated
function __spp_legacy_restrict(mods, letter, ctx) =
    [for (m = mods)
        let(
            tokens = [for (tk = m[__SPP_EDGE_MOD_WHERE_IDX]) tk == "all" ? letter : str(tk, letter)],
            v = m[__SPP_EDGE_MOD_VALUE_IDX],
            nm = [m[0], m[1], letter == "i" ? -1*v : v, tokens],
            _msg = echo(str("[", ctx, "] DEPRECATED: ", letter == "i" ? "inner_mod_list" : "outer_mod_list",
                            " -> put ", __spp_mod_text(nm), " into 'mod_list'"))
                   0
        )
        nm];


// ------------------------------------------------------------------ resolution

// checks 'mod_list' of a solid, translates legacy modifiers, returns the list of new modifiers
// - 'family' is "box" or "revolved"
function __spp_resolve_mod_list(mod_list, family, ctx) =
    is_undef(mod_list) ?
        [] :
        assert(is_list(mod_list),
            str("[", ctx, "] argument 'mod_list' must be a list of modifiers, got ", mod_list))
        let(
            n_legacy = len([for (m = mod_list) if (__spp_is_legacy_mod(m)) 1]),
            reverse = n_legacy > 1 && n_legacy == len(mod_list),
            _msg = reverse ?
                    echo(str("[", ctx, "] DEPRECATED: old modifiers were applied from the last one to the first one, ",
                             "new modifiers are applied in reading order; the translated list is reversed"))
                    0 :
                    0,
            ordered = reverse ? [for (i = [len(mod_list)-1:-1:0]) mod_list[i]] : mod_list,
            out = [for (m = ordered) each (__spp_is_legacy_mod(m) ? __spp_legacy_translate(m, family, ctx) : [m])],
            corner = [for (m = out) if (__spp_is_corner_mod(m)) m],
            invalid = [for (m = out) if (!__spp_is_edge_mod(m) && !__spp_is_corner_mod(m)) m]
        )
        assert(len(invalid) == 0, str("[", ctx, "] 'mod_list' contains invalid modifiers: ", invalid))
        assert(family == "box" || len(corner) == 0,
            str("[", ctx, "] bevel_corners() is supported only by cubepp"))
        family == "revolved" ?
            [for (m = out) [m[0], m[1], __spp_edge_mod_pair(m, ctx), m[3]]] :
            out;
