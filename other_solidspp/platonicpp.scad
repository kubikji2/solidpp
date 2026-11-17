// defining the platonicpp
__DEF_PLATONICPP__ = true;

// including utils and the platonic engine
include<../utils/solidpp_utils.scad>
include<../engine/platonic.scad>

// platonicpp default alignment (centered in x/y, on z = 0)
PLATONICPP_DEF_ALIGN = "z";


// Platonic solid (dice: n = 4, 6, 8, 12, 20 faces)
// - argument 'n' is the number of faces: 4 (tetrahedron), 6 (cube), 8 (octahedron),
//   12 (dodecahedron), 20 (icosahedron)
// - size: at most one of
//   '-> argument 'a' edge length (default 1)
//   '-> argument 'd' diameter of the inscribed sphere (distance between opposite faces of a die,
//       for the tetrahedron half of its height)
//   '-> argument 'D' diameter of the circumscribed sphere (through the vertices)
// - the solid lies on a face (outward normal -zet), one edge of that face is parallel to x
//   (zet "z"); 'zet' turns it like every solidpp solid
// - argument 'align' aligns the bounding box, see README (default "z": centered in x/y, on z = 0)
// - argument 'zet' is the up axis: "x", "y" or "z" (default)
// - argument 'center' overrides 'align' if true (centers the bounding box)
// - argument 'mod_list' modifiers of all edges/corners (where="all" only, single numbers):
//   '-> bevel(d):         chamfer with the leg d along both faces
//   '-> bevel_corners(d): cut of the corners at the distance d along the edges (d = a/2 cuts the
//                         edges away completely)
//   '-> rounding(r):      rounds every edge and corner (also of the cuts), must be the last one
//   '-> the face planes stay in place, so the alignment and platonicpp_faces are not affected
// See DESIGN.md for details.
module platonicpp(n=6, a=undef, d=undef, D=undef, align=undef, zet=undef, center=false, mod_list=undef)
{
    __module_name = "PLATONICPP";

    _spec = __spp_plat_spec(n, __spp_plat_edge(n, a, d, D, __module_name), __module_name);
    _m = __spp_plat_mods(mod_list, _spec, __module_name);

    __spp_plat_place(_spec, align, zet, center, __module_name)
        __spp_plat_geometry(_spec, _m);
}

// wrappers
module tetrahedronpp(a=undef, d=undef, D=undef, align=undef, zet=undef, center=false, mod_list=undef)
    platonicpp(4, a=a, d=d, D=D, align=align, zet=zet, center=center, mod_list=mod_list);

module hexahedronpp(a=undef, d=undef, D=undef, align=undef, zet=undef, center=false, mod_list=undef)
    platonicpp(6, a=a, d=d, D=D, align=align, zet=zet, center=center, mod_list=mod_list);

module octahedronpp(a=undef, d=undef, D=undef, align=undef, zet=undef, center=false, mod_list=undef)
    platonicpp(8, a=a, d=d, D=D, align=align, zet=zet, center=center, mod_list=mod_list);

module dodecahedronpp(a=undef, d=undef, D=undef, align=undef, zet=undef, center=false, mod_list=undef)
    platonicpp(12, a=a, d=d, D=D, align=align, zet=zet, center=center, mod_list=mod_list);

module icosahedronpp(a=undef, d=undef, D=undef, align=undef, zet=undef, center=false, mod_list=undef)
    platonicpp(20, a=a, d=d, D=D, align=align, zet=zet, center=center, mod_list=mod_list);


// places the children on the faces of the platonicpp with the same arguments
// - arguments 'n', 'a', 'd', 'D', 'align', 'zet', 'center' as in platonicpp ('mod_list' does not
//   move the faces)
// - argument 'idx' number(s) of the faces: undef (all, default), a number or a list
// - argument 'numbering':
//   '-> "opposite" (default): face k is opposite to face n-1-k (dice: opposite faces add up to n+1
//       with the labels k+1); the tetrahedron has no opposite faces, it uses the geometric order
//   '-> "sequential": consecutive faces share an edge and the last face is adjacent to the first
//       one (life counters, spindown dice), starting with the top face
// - the children get the frame of the face: the origin in its center, z outward, y towards the up
//   axis (x for the top and bottom faces), so text(...) reads from outside
// - special variables available in the children:
//   '-> $face          number of the face (0 ... n-1)
//   '-> $face_vertices numbers of its corners (as in platonicpp_vertices), counter-clockwise
//   '-> $face_corners  2D positions of its corners in the frame of the face (same order)
module platonicpp_faces(n=6, a=undef, d=undef, D=undef, align=undef, zet=undef, center=false,
                        idx=undef, numbering="opposite")
{
    __module_name = "PLATONICPP_FACES";

    _spec = __spp_plat_spec(n, __spp_plat_edge(n, a, d, D, __module_name), __module_name);
    _order = assert(numbering == "opposite" || numbering == "sequential",
        str("[", __module_name, "] argument 'numbering' must be \"opposite\" or \"sequential\", got ", numbering))
        numbering == "opposite" ? _spec[8] : _spec[9];
    _idx = __spp_plat_idx(idx, n, "face", __module_name);
    // number of the vertex with the index i
    _vnum = [for (i = [0:1:len(_spec[0])-1]) [for (k = [0:1:len(_spec[7])-1]) if (_spec[7][k] == i) k][0]];

    __spp_plat_place(_spec, align, zet, center, __module_name)
        for (k = _idx)
        {
            _f = _order[k];
            _M = __spp_plat_frame(_spec[2][_f], _spec[3][_f]);
            $face = k;
            $face_vertices = [for (i = _spec[1][_f]) _vnum[i]];
            $face_corners = [for (i = _spec[1][_f])
                let(q = _spec[0][i] - _spec[2][_f]) [q * [_M[0][0], _M[1][0], _M[2][0]], q * [_M[0][1], _M[1][1], _M[2][1]]]];
            multmatrix(_M)
                children();
        }
}

// places the children on the vertices of the platonicpp with the same arguments
// - arguments as in platonicpp_faces (no 'numbering': the vertices are numbered from the top down,
//   then counter-clockwise)
// - the children get the frame of the vertex: the origin in the vertex, z outward (from the center),
//   y towards the up axis
// - special variable $vertex: number of the vertex
module platonicpp_vertices(n=6, a=undef, d=undef, D=undef, align=undef, zet=undef, center=false, idx=undef)
{
    __module_name = "PLATONICPP_VERTICES";

    _spec = __spp_plat_spec(n, __spp_plat_edge(n, a, d, D, __module_name), __module_name);
    _idx = __spp_plat_idx(idx, len(_spec[0]), "vertex", __module_name);

    __spp_plat_place(_spec, align, zet, center, __module_name)
        for (k = _idx)
        {
            _v = _spec[0][_spec[7][k]];
            $vertex = k;
            multmatrix(__spp_plat_frame(_v, _v / norm(_v)))
                children();
        }
}

// moves the children from the local frame of the solid to the aligned position
module __spp_plat_place(spec, align, zet, center, ctx)
{
    _zet = __spp_check_zet(zet, ctx);
    _box = spec[6];
    _box_size = __spp_box_to_parent_extents(_box[1] - _box[0], _zet);
    _box_center = __spp_box_to_parent_position((_box[0] + _box[1]) / 2, _zet);

    _o = __solidpp__produce_offset_from_align_and_center(
            _size=_box_size,
            align=align,
            center=center,
            solidpp_name=ctx,
            def_align=PLATONICPP_DEF_ALIGN);

    _rot = __solidpp__get_rotation_from_zet(_zet, [0,0,0]);

    translate(_o - _box_center)
        rotate(_rot)
            children();
}
