# Solid++

Solid++ improves basic [OpenSCAD](https://openscad.org/) geometries namely `cube`, `sphere` and `cylinder` to allow various centering and orientation without any laborious transformations within your code.
This repository is planned to be integrated into [OpenSCAD++] library.

## Main features

The `cube`, `sphere` and `cylinder` arguments are kept for their solid++ counterparts `cubepp`, `shperepp` and `cylinderpp`, but new unified arguments are presented, namely bounding box size (`size`), alignment (`align`) and orientation (`z`).
Moreover, `cubepp` and `cylinderp` can be further modified using `modifiers` discussed below.

### Bounding box size aka `size` argument

Bounding box size defines the solid bounding box.
It is the first positional argument; therefore, its name can be omitted from the code.

For `cubepp`, this argument replaces `cube` size with all its features:

```openscad
// following lines result in same solids
cubepp(size=[a,b,c]);
cubepp([a,b,c]);
cube([a,b,c]);

// following lines result in same solids
cubepp(a);
cubepp([a]);
cubepp([a,a,a]);
```

For `spherepp`, this argument overrides radius `r` and diameter `d` and expresses the ellipsoid axis sizes, but the behavior is backward compatible with `d`:

```openscad
// following lines result in same solids
spherepp(size=[d,d,d]);
spherepp([d,d,d]);
spherepp([d]);
spherepp(d=d); // discouraged
spherepp(d);
sphere(d);

// following lines result in same solids
spherepp([a,b,c]);
resize([a,b,c])
    sphere();
```

For `cylinderpp`, this argument overrides radius `r`, diameter `d` and height `h`. The first two elements express the axis size in the xy-plane and the last element defines the height in the z-axis.
If `r1,r2|d1,d2` are used, the `size` defines the bounding box of the greater bases, see `cylinderpp`-specific features below for edge cases.

```openscad
// following lines result in same solids
cylinderpp([a,a,b]);
cylinder(d=a, h=b);
cylinder(r=a/2, d=b);

// following lines result in same solids
cylinderpp([a,b,c]);
resize([a,b,c])
    cylinder();
```

### Alignment aka `align` argument

Solid++ allow individual axis alignment that can be achieved by the following rules.

1. If the `align` is a string and it contains a small letter `x`/`y`/`z` the solid is aligned such that the bounding box is touching the origin from the `right`/`back`/`top` respectively.
2. If the `align` is a string and it contains a capital letter `X`/`Y`/`Z` the solid is aligned such that its bounding box is touching the origin from the `left`/`front`/`bottom` respectively.
3. If the `align` is a string and neither (`x` nor `X`)/(`y` nor `Y`)/(`z` nor `Z`) are present in the string, then the bounding box is centered in the `x`/`y`/`z`-axis respectively.
4. The rules 1.-3. can be combined.
5. If the `align` is an empty string or string containing only other letters is equivalent to the `center=true`.
6. Default alignment for the `cubepp`, `spherepp` and `cylinderpp` remains the same as for their basic counterparts.

The default `cube` and `cubepp` alignment are `align="xyz"`, the default `sphere` and `spherepp` alignment are `align=""` (`align="c"`), and the default `cylinder` and `cylinderpp` are `align="z"`.

```openscad
// following lines results in the same solids
cube([a,b,c]);
cubepp([a,b,c]);
cube([a,b,c], align="xyz");

// following lines results in the same solids
cubepp([a,b,c], align="z");
translate([-a/2,-b/2,0])
    cube([a,b,c]);

// following lines results in the same solids
cubepp([a,b,c], align="");
cubepp([a,b,c], center=true); // discouraged
cube([a,b,], center=true);

// following lines results in the same solids
cubepp([a,b,c], aling="X");
translate([-a, -b/2, -c/2])
    cube([a,b,c]);
```

### Orientation aka `zet` argument

In the main contributor's experience, the most laborious process is the rotation and alignment of the cylinders.
Therefore, Solid++ provides `zet` argument, that specifies which of the `x`/`y`/`z` axis is the z-axis of the original model. 

For `cylinderpp`, the `zet="x"` results in the horizontal cylinder in the left-right orientation, the `zet="y"` results in the horizontal cylinder in the front-back orientation, and the default orientation `zet="z"` results in the regular vertical orientation.
For `cubepp` and `spherepp`, the `zet` argument plays no role.

Note that the solids are rotated according to the `zet` and then `align` and `size` are considered independently. Therefore, the `align` is always in the main (parent) transform frame, so you do not need to worry about the axis changes caused by `zet`. Moreover, using the `size=[x,y,z]` assures that the left-right/front-back/bottom-up bounding box dimension is `x`/`y`/`z` respectively regardless of the `zet`.

### Modifiers

Solids with distinguished edges (`cubepp` and `cylinderpp`) can be further modified using modifiers such as rounding the edges, or corners, beveling, and cutting of edges or corners.
Modifiers are created using constructors in `modifiers.scad` that are basically just wrappers for computing a storing data required for solid modification.

#### Round corners (`round_corners(r|d)`)

Round corners of the `cubepp` or `cylinderpp` using the `r|d` parameter that defines either the radius/diameter of the sphere used for rounding or the semi-/axis of the ellipsoid used for un-even rounding.
This modifier cannot be applied to the `spherepp` and connects the `cubepp`/`cylinderpp` to `spherocube`/`spherocylinder`.  
Note that the edges are consequently rounded as well.

#### Round edges (`round_edges(r|d, axes='xy')`)

Round edges of the `cubepp` or `cylinderpp` using `r|d` parameter.
The function of `r|d` parameter and its effect on solids depends on the number of the axis chosen in `axes` and the solidpp modified by it.
For `cylinderpp`, the `axes` are omitted, since only the base edges are affected by the rounding.
The `r|d` argument can be either an integer defining the diameter/radius of the sphere used for even rounding or a vector of size 3 defining the size of semi-/axes of the ellipsoid used for un-even rounding.
Note that, for `cylinderpp`, `round_edges` modifier's effect is the same as `round_corners`.
For `cubepp`, the `axes` argument defines which directions/axis are used for rounding.
If a single axis is used, the sides with the normals parallel to such axis are considered the bases and only their edges are rounded.
If two axes are defined, only the edges whose neighbor sides have normals perpendicular to those axes are rounded.
If all axes are defined, all edges are rounded.
Note that the axis order does not matter and the axes can be specified by both small and capital letters.
The valid dimensions of the `r|d` parameters depend on the number of utilized axes.
For a single axis, `r|d` defines the radius/diameter of the sphere (a single integer) or the semi-/axis of the ellipsoid (a list of size 3) used to round the edges.
For two axes ('ab'), `r|d` can be either an integer defining the diameter/radius of the circle used to round the edges perpendicular to the ab-plane or a vector of size 2 defining the semi-/axis of the ellipse.
Note that, the semi-/axis ordering follows axis priority x > y > z, e.g. for `axes=zx`/`axes=xz`, the `r=[2,3]` is interpreted as `r_x=2` and `r_z=3`.
For all three axes, `r|d` defines the radius/diameter of the sphere (a single integer) or the semi-/axis of the ellipsoid (a list of size 3) used to round the edges.
Note that if all axes are chosen, the resulting geometry is different from the one obtained by `round_corner`.
Moreover, the `round_edges` unify an interface to the `cylindrocube` (TODO check).

### Bevel base (`bevel_base(bevel, axis='z', bevel_bottom=undef, bevel_top=undef)`)

Bevel edges of the bases using `bevel` and defined by `axis`.
In the case of `cylinderpp`, only two bases are possible.
Therefore, the `axis` is ignored (it is considered to be always equal to `z`).
In the case of `cubepp`, `axis` is considered to be a single char denoting one of the axes (`x`/`X` for the x-axis, `y`/`Y` for the y-axis, `z`/`Z` for the z-axis).
The normals of bases that are parallel to the selected axis are considered bases.

The `bevel` argument can either be a single number (or a single element array) denoting the beveling uniform in all axis, two numbers denoting the [`a`,`h`], where `a` is the distance from the base edges and `h` is the height of the bevel (length of the bevel segment projected to the `axis`), ...
**VARIANT 1**:
... or the triplet [`a`,`b`,`h`], where the `a` is the distance from the base edges along the *main axis*, `b` is the distance from the base edges along the *side axis*, `h` is the height of the bevel (length of the bevel segment projected to the `axis`).
The *main axis* and *side axis* as the two remaining axes complementary to the argument `axis`, e.g. for `axis=z`, the x-axis is the main axis, the y-axis is the side axis, for `axis=y`, the x-axis is the main axis, and the z-axis is the side axis.
**VARIANT 2**:
... or the triplet [`x`,`y`,`z`], where the `x` is the bevel projection to the x-axis, `y` is the bevel projection to the y-axis, and `z` is the bevel projection to the z-axis.
TODO DECIDE VARIANT ^^^

In the same manner, the `bevel_bottom` and `bevel_top` affect only a particular base, where the *bottom* is the base with a lower value in the leading axis defined in `axis`.

#### Bevel corners (`bevel_corners(cut)`)

Cuts off (bevels) the `cubepp` corners using the `cut` argument defining the cut size.
Note that the modifier's effect on the `cylinderpp` is the same as the `bevel_base`.

The argument `cut` is either a single number (or a single number list) denoting the corner cut dimension in all axis, or a number triplet [`x`,`y`,`z`] denoting the cut sizes in the particular axis.
