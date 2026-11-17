include<../utils/vector_operations.scad>
include<../engine/revolved.scad>

// mirror, but if 'copy' is set to true, keeps the original solid
// - argument 'v' is the normal of the mirror plane: a 2D or 3D vector, or axis letters
//   '-> a vector: a single mirror (as mirror())
//   '-> letters "x", "y", "z" (case does not matter), e.g. "xy": the mirrors in all these axes and
//       all their combinations ("xy": mirrored in x, in y and in both)
// - argument 'copy' defines whether the original is kept (true) or only the mirrored copies are
//   made (false, default, as mirror())
//   '-> mirrorpp("xy", copy=true) translate([a, b, 0]) hole(); makes four holes in the corners
// - argument 'point' is a point of the mirror plane(s) (default: the origin)
module mirrorpp(v=undef, copy=false, point=undef)
{
    // module name
    __module_name = "MIRROR++";

    // copy must be bool
    assert( is_bool(copy),
            str("[",__module_name, "] argument 'copy' must be boolean!"));

    // argument 'v' is either 3D vector, a 2D vector or axis letters
    assert( is_vector_3D(v) || is_vector_2D(v) || __spp_mirror_letters_ok(v),
            str("[", __module_name, "] argument 'v' must be a 2D/3D vector or axis letters, each axis once (e.g. \"x\", \"xy\"), got ", v));

    assert( is_undef(point) || is_vector_3D(point) || is_vector_2D(point),
            str("[", __module_name, "] argument 'point' must be a 2D or 3D point, got ", point));

    _p = is_undef(point) ? [0, 0, 0] : (len(point) == 2 ? [point[0], point[1], 0] : point);

    // list of mirrors, every one a list of normals applied in turn ([] = the original)
    _mirrors = is_string(v) ?
        let(
            axes = [for (c = ["x", "y", "z"]) if (__spp_char_in(c, v) || __spp_char_in(__spp_upper(c), v)) c],
            normals = [for (a = axes) a == "x" ? [1, 0, 0] : (a == "y" ? [0, 1, 0] : [0, 0, 1])],
            k = len(normals)
        )
        // all subsets of the normals (bit i of m selects normal i)
        [for (m = [0:1:pow(2, k)-1]) [for (i = [0:1:k-1]) if (floor(m / pow(2, i)) % 2 == 1) normals[i]]] :
        [[], [v]];

    for (_m = _mirrors)
        if (len(_m) > 0 || copy)
            translate(_p)
                __spp_mirror_chain(_m)
                    translate(-_p)
                        children();
}

// applies the mirrors of the list in turn
module __spp_mirror_chain(normals, i=0)
{
    if (i >= len(normals))
        children();
    else
        mirror(normals[i])
            __spp_mirror_chain(normals, i+1)
                children();
}

// true iff 'v' is a string of distinct axis letters
function __spp_mirror_letters_ok(v) =
    is_string(v) && len(v) > 0 && __spp_all_chars_in(v, "xyzXYZ") &&
    len(__spp_unique([for (k = [0:1:len(v)-1]) __spp_lower(v[k])])) == len(v);

function __spp_lower(c) = let(k = ord(c)) k >= 65 && k <= 90 ? chr(k + 32) : c;
function __spp_upper(c) = let(k = ord(c)) k >= 97 && k <= 122 ? chr(k - 32) : c;
