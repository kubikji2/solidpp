include<../utils/solidpp_utils.scad>

// Conditional CSG operations: if 'condition' is true, the operation is applied to the children,
// otherwise the argument 'otherwise' selects what is kept:
// - "first" (default): children(0), e.g. the body without the holes
// - "rest":            children(1), ..., e.g. only the holes (support blockers for a slicer)
// - "all":             union of all children
// - "none":            nothing
// - a number or a list of numbers: these children
// The old argument 'ommit_children' (true: "first", false: "all") still works, but is deprecated.

module hull_if(condition, otherwise=undef, ommit_children=undef)
{
    _o = __spp_if_otherwise("HULL_IF", condition, otherwise, ommit_children, $children);
    if (condition)
        hull()
            children();
    else if (len(_o) > 0)
        children(_o);
}

module minkowski_if(condition, otherwise=undef, ommit_children=undef)
{
    _o = __spp_if_otherwise("MINKOWSKI_IF", condition, otherwise, ommit_children, $children);
    if (condition)
        minkowski()
            children();
    else if (len(_o) > 0)
        children(_o);
}

module difference_if(condition, otherwise=undef, ommit_children=undef)
{
    _o = __spp_if_otherwise("DIFFERENCE_IF", condition, otherwise, ommit_children, $children);
    if (condition)
        difference()
        {
            children(0);
            if ($children > 1)
                children([1:1:$children-1]);
        }
    else if (len(_o) > 0)
        children(_o);
}

module intersection_if(condition, otherwise=undef, ommit_children=undef)
{
    _o = __spp_if_otherwise("INTERSECTION_IF", condition, otherwise, ommit_children, $children);
    if (condition)
        intersection()
            children();
    else if (len(_o) > 0)
        children(_o);
}

// checks the arguments, returns the indices of the children kept when 'condition' is false
function __spp_if_otherwise(name, condition, otherwise, ommit_children, n) =
    assert(is_bool(condition), str("[", name, "] argument 'condition' must be a boolean, got ", condition))
    assert(is_undef(otherwise) || is_undef(ommit_children),
        str("[", name, "] use 'otherwise' only, 'ommit_children' is deprecated"))
    assert(is_undef(ommit_children) || is_bool(ommit_children),
        str("[", name, "] argument 'ommit_children' must be a boolean, got ", ommit_children))
    let(
        _dep = is_undef(ommit_children) ? 0 :
            echo(str("[", name, "] DEPRECATED: ommit_children=", ommit_children, " -> use otherwise=\"",
                     ommit_children ? "first" : "all", "\"")) 0,
        o = !is_undef(ommit_children) ? (ommit_children ? "first" : "all") : (is_undef(otherwise) ? "first" : otherwise)
    )
    assert(o == "first" || o == "rest" || o == "all" || o == "none" || is_num(o) ||
           (is_list(o) && len([for (i = o) if (!is_num(i)) 1]) == 0),
        str("[", name, "] argument 'otherwise' must be \"first\", \"rest\", \"all\", \"none\" or child ",
            "index/indices, got ", otherwise))
    let(
        idx = o == "first" ? (n > 0 ? [0] : []) :
              o == "rest" ? [for (i = [1:1:n-1]) i] :
              o == "all" ? [for (i = [0:1:n-1]) i] :
              o == "none" ? [] :
              is_num(o) ? [o] : o
    )
    assert(len([for (i = idx) if (i != round(i) || i < 0 || i >= n) 1]) == 0,
        str("[", name, "] argument 'otherwise': child index out of range (", n, " children), got ", otherwise))
    idx;
