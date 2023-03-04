# Solid++

Solid++ improves basic [OpenSCAD](https://openscad.org/) geometries namely `cube`, `sphere` and `cylinder` to allow various centering and orientation without any laborious transformations within your code.
This repository is planned to be integrated into [OpenSCAD++] library.

## Main features

The `cube`, `sphere` and `cylinder` arguments are kept for their solid++ counterparts `cubepp`, `spherepp` and `cylinderpp`, but new unified arguments are presented, namely bounding box size (`size`), alignment (`align`) and orientation (`z`).
Moreover, `cubepp` and `cylinderpp` can be further modified using `modifiers` discussed below.

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

### Bounding-box related transformation

Since the `solidpp` unifies the size and alignments of the solids, the unified approach can be used for transformation to the significant points of the bounding box.

Namely `translate_to_spp(size,align,pos,x=undef,y=undef,z=undef)` uses the `pos` of the solid's to create translation to the bounding box shell using solid's bounding box `size` and `align` based on the following rules:

1. Argument `pos` is a string.
2. If the argument `pos` contains `x`/`y`/`z` the resulting translation is aligned with the relative origin of the bounding box in x-axis/y-axis/z-axis
3. If the argument `pos` contains `X`/`Y`/`Z` the resulting translation is aligned with the opposite end of the bounding box solid diagonal in x-axis/y-axis/z-axis.
4. If the argument `pos` contains neither `x`, nor `X` / `y`, nor `Y`/ `z`, nor `Z` the center of x/y/z-axis is used.
5. For each axis the rules are evaluated sequentially in the order 2., 3. and then 4.
6. Repetition and other characters are ignored.

For example, `pos=""` results in translation to the bounding box center, `pos="xyz"` is the left-front-bottom corner, `pos="Xyz"` and `pos="Xxxxxxxxxyz"` is the right-front-bottom corner, `pos="Z"` is the top side center, and `pos=XZ` is the center of the right-top bounding box edge.

Arguments `x`/`y`/`z` allow the continuous definition of the point of interest within the bounding box.
This definition work as follows:

1. All arguments are numbers in the range [0,1].
2. Values continuously interpolated on the particular axis between the `x` and `X`/ `y` and `Y` / `z` and `Z`
3. The `x`/`y`/`z` and `pos` can be combined, but values in `x`/`y`/`z` have greater priority.

For example, `x=0.5,y=0,z=1` is equivalent to `pos=yZ` and it means the middle of the front-top edge, `pos=yZ,x=0.25` is the point on the front-top edge 1/4 of the length from the left-front-top corner.

Note that the translation to the solidpp center might be different from the scope origin since the `align` might be used for the geometry.
Moreover, the string `cube`/`sphere`/`cylinder` can be used to signal that `cubepp`/`spherepp`/`cylinderpp` default alignment is used.
Alternatively, the default solidpp alignments are available in the `CUBEPP_DEF_ALIGN`, `CYLINDERPP_DEF_ALIGN` and `SPHEREPP_DEF_ALIGN`.

If one is interested in the numerical values of the transformation rather than the transform itself `get_translation_to_spp` function with the identical interface can be used.

### Extended geometries

Aside from the core geometries, solidpp library provides more geometries, that respect as many main features (`size`, `align` and `zet`) as possible.
Though some geometries simply cannot follow these principles, mainly the `size` is relaxed.

#### Prism (`prismpp(points=undef, h=undef, align=undef, zet=undef, center=false, mod=undef, stack=undef)`)

TODO:

- how to manage the beveling?
- what are the modifiers?

##### Unbounded prism (`prism(points=undef, h=undef, n=undef)`)

TODO:

- Creates an arbitrary prism.
- points must be in the same plain, 2D or 3D points, 3D points in case of normals, 2D points in case of h
- n is a normal (arbitrary vector 3D)
- h is the height (in z-axis)

#### Pyramid (`pyramidpp()`)

TODO

#### Trapezoid (`trapezoidpp()`)

TODO

#### Tube (`tubepp(t, r|d, R|D, h, align=undef, zet="z", mod_list=undef, inner_mod_list=undef, outer_mod_list=undef)`)

This module allows creation of the general cube using exactly two arguments inner radius/diameter (`r|d`), outer radius/diameter (`R|D`) or the shell thickness (`t`).
The height of the tube is defined by `h`.

Both inner radius/diameter (`r|d`) or outer radius/diameter (`R|D`) can be either a single number or a vector 2D.
In case of the 2D vector the first number expresses the radius/diameter of the cylinder bottom base and the second number expresses the radius/diameter of the cylider top base similarly to the cylinder `r1,r2|d1,d2`.

The tube can be modified using the there arguments: `mod_list`, `inner_mod_list` and `outer_mod_list`.
The argument `mod_list` defines the modifications to be applied to the tube itself.
The argument `inner_mod_list` defines the modifications for the inner cylinder (hole) only.
Similarlym, the argument `outer_mod_list` defines the modifications for the bounding-cylinder only (cylinder without drilled hole).
Using the combination of these list, one can create tube with edges beveled/rounded differently for the shell and the hole.
Note that the all list arguments must contain only the compatible modifiers (see bellow).

TODO: how the size is managed?

#### Torus (`toruspp()`)

TODO

### Modifiers

Solids with distinguished edges (`cubepp` and `cylinderpp`) can be further modified using modifiers such as rounding the edges, or corners, beveling, and cutting (bevelling) of edges or corners.
Modifiers are created using constructors in `modifiers.scad` that are basically just wrappers for computing a storing data required for solid modification.

#### Compatibility overview

|                 | `spherepp` | `cubepp` | `cylinderpp` |
|----------------:|:----------:|:--------:|:------------:|
| `round_bases`   |    NO      |   YES    |     YES      |
| `round_corners` |    NO      |   YES    |     NO       |
| `round_edges`   |    NO      |   YES    |     NO       |
| `bevel_bases`   |    NO      |   YES    |     YES      |
| `bevel_corners` |    NO      |   YES    |     NO       |
| `bevel_edges`   |    NO      |   YES    |     NO       |
| `regular_base`  |    NO      |   NO     |     NO       |

As seen in the table, `spherepp` cannot be modified by any means, `cubepp` provides various modifiers and `cylinderpp` can support only base modifications.

|                 | `prismpp` | `pyramidpp` | `trapezoidpp` | `tubepp` | `toruspp` |
|----------------:|:---------:|:-----------:|:-------------:|:--------:|:---------:|
|   `round_bases` |    YES    |     ???     |     ???       |   YES    |    NO     |
| `round_corners` |    YES    |     YES     |     YES       |   NO     |    NO     |
|   `round_edges` |    YES    |     ???     |     NO        |   NO     |    NO     |
|   `bevel_bases` |    YES    |     YES     |     NO        |   YES    |    NO     |
| `bevel_corners` |    NO     |     NO      |     NO        |   NO     |    NO     |
|   `bevel_edges` |    NO     |     NO      |     NO        |   NO     |    NO     |
|  `regular_base` |    YES    |     YES     |     NO        |   NO     |    NO     |

TODO

#### Round bases (`round_bases(r|d, axis='z', r_base|d_base=undef, r_top|d_top=undef)`)

TODO description

TODO: how to round other edges, then the bases? - using rounded sides can be achieved by nesting the modifiers

#### Round corners (`round_corners(r|d)`)

Round corners (and consequently the edges) of the `cubepp`, `prismpp`, `pyramidpp`, and `trapezoid` in the same manner as using `minkowski` operation between the object and the sphere.
Argument `r|d` defines the radius/diameter of the sphere used for rounding.
Moreover, in the case of `cubepp`, the `r|d` can also be vector 3D defining the semi-/axis of the ellipsoid used for un-even rounding.

#### Round edges (`round_edges(r|d, axes='xy')`)

Round edges of the `cubepp` and `prismpp` using `r|d` parameter.
The function of `r|d` parameter and its effect on solids depends on the number of the axis chosen in `axes` and the solidpp modified by it.

For `cubepp`, the `axes` argument defines which directions/axis are used for rounding.
If a single axis is used, the sides with the normals parallel to such axis are considered the bases and only their edges are rounded, e.g. `axes="z"` affects the edges of the top and bottom sides.
If two axes are defined, only the edges whose neighbor sides have normals perpendicular to those axes are rounded, e.g. `axes="xy"` affects only the edges between front and right, right and back, back and left, left and front sides.
If all axes are defined, all edges are rounded.
Note that the axis order does not matter and the axes can be specified by both small and capital letters.
For `prismpp`, the `axes` are ignored.

The valid dimensions of the `r|d` parameters depend on the number of utilized axes and the solidpp modified by it.
For `cubepp` and a single axis, `r|d` defines the radius/diameter of the sphere (a single integer) or the semi-/axis of the ellipsoid (a list of size 3) used to round the edges.
For `cubepp` and two axes (`'ab'`), `r|d` can be either an integer defining the diameter/radius of the circle used to round the edges perpendicular to the ab-plane or a vector of size 2 defining the semi-/axis of the ellipse.
Note that, the semi-/axis ordering follows axis priority x > y > z, e.g. for `axes=zx`/`axes=xz`, the `r=[2,3]` is interpreted as `r_x=2` and `r_z=3`.
For `cubepp` and and all three axes, `r|d` defines the radius/diameter of the sphere (a single integer) or the semi-/axis of the ellipsoid (a list of size 3) used to round the edges.
Note that if all axes are chosen, the resulting geometry is no different from the one obtained by `round_corner`.

For `prismpp`, the `r|d` argument can only be a number defining the radius/diameter of the base roundings.

#### Bevel bases (`bevel_bases(bevel=undef, axis='z', bevel_bottom=undef, bevel_top=undef)`)

The bevel base edges modifier is using `bevel` argument (or `bevel_bottom` and/or `bevel_top`) to bevel (cut off) the base edges.
It is applicable for `cubepp`, `cylinderpp` `prismpp`, `pyramidpp`, and `tubepp`.
In the case of multiple available bases (case of `cubepp`), the argument `axis` is used to define the dominant axis.

In the case of `cylinderpp`, `prismpp` and `tubepp`, only two bases are possible, and in the case `pyramidpp`, only one base is possible.
Therefore, the `axis` is ignored (it is considered to be always equal to `z`).
In the case of `cubepp`, `axis` is considered to be a single char denoting one of the axes (`x`/`X` for the x-axis, `y`/`Y` for the y-axis, `z`/`Z` for the z-axis).
The normals of bases that are parallel to the selected axis are considered bases.

The `bevel` argument can either be a single number (or a single element array) denoting the beveling uniform in all axis, two numbers denoting the [`a`,`h`], where `a` is the distance from the base edges and `h` is the height of the bevel (length of the bevel segment projected to the `axis`), or the triplet [`x`,`y`,`z`], where the `x` is the bevel projection to the x-axis, `y` is the bevel projection to the y-axis, and `z` is the bevel projection to the z-axis.
However, using [`x`,`y`,`z`] is available for `cubepp`, `cylinderpp` and `tubepp`.

In the same manner, the `bevel_bottom` and `bevel_top` affect only a particular base, where the *bottom* is the base with a lower value in the leading axis defined in `axis`.
Note that `pyramidpp` has only a single base considered to be the bottom one.
Moreover, a single base can be beveled by defining only a single `bevel_bottom` or `bevel_top` argument.

#### Bevel corners (`bevel_corners(bevel)`)

The bevel corners modifier is using `bevel` argument to bevel (cut off) the corners of the `cubepp`.

The argument `bevel` is either a single number (or a single number list) denoting the corner cut dimension in all axis, or a number triplet [`x`,`y`,`z`] denoting the cut sizes in the particular axis.

#### Bevel edges (`bevel_edges(bevel, axes='xyz')`)

The bevel edges modifier is using `bevel` argument to define the edge bevel (cut off) and `axes` argument to define the affected edges.
This modifier is applicable only on `cubepp`.

The effect of `bevel` argument is guided by the number of axes in `axes` argument that is required to be a string containing either lower or upper case character denoting axes (`x`/`X` for the x-axis, `y`/`Y` for the y-axis, `z`/`Z` for the z-axis).
If the `axes` contain a single axis, only the edges of the side with normals parallel to the said axis are affected, e.g. `axes="z"` affects the edges of the top and bottom sides.
If the `axes` contain two axes, only the edges whose neighboring sides have normals parallel to one of the axes are affected, e.g. `axes="xy"` affects only the edges between front and right, right and back, back and left, left and front sides.
If the `axes` contain all three axes, all edges are beveled.

The `bevel` argument can be a single number denoting the distance from the edges to be cut off regardless of the `axes` content.
In the case of `axes` containing a single or all axes, the `bevel` can be a triplet [`x`, `y`, `z`] denoting the distance from the edges along particular axes.
In the case of `axes` containing precisely two axes, the `bevel` can be a pair [`a`, `b`] denoting the distances from the edges along the axes in order `x`, `y`, `z`, i.e. if `axis="xy"` then `a` is x-axis bevel offset, `b` is the y-axis bevel offset if `axis="xz"` then `a` is x-axis bevel offset, `b` is the z-axis bevel offset, and if `axis="yz"` then `a` is y-axis bevel offset, `b` is the z-axis bevel offset.

#### Regular base (`regular_base(a=undef, h=undef, n=undef)`)

This modifier allows defining the regular bases for `prismpp` and `pyramidpp` by defining the number of `prismpp`/`pyramidpp` base sides.

The required argument `a` defines the length of the side, optional argument `h` defines the solid height and optional argument `n` defines the number of sides.
If the argument `h` is missing, the height is considered to be the same as the side length.

## Roadmap

### Basic solid++ roadmap

- [x] cube++
- [x] sphere++
- [x] cylinder++

### Advanced solid++ roadmap

- [ ] prism++
- [ ] pyramid++
- [ ] trapezoid++
- [ ] tube++
- [ ] torus++

### Transformation roadmap

- [ ] implement `transform_to_spp`
  - [x] implement `translate_to_spp`
  - [ ] implement normals or other stuff ???

### Modifiers roadmap

- [x] interfaces defined
- [ ] implement the back-end solids
  - [x] round_bases_cubepp
  - [x] round_corners_cubepp
  - [x] round_edges_cubepp
  - [x] bevel_bases_cubepp
  - [x] bevel_edges_cubepp
  - [x] bevel_corners_cubepp
  - [ ] round_bases_cylinderpp
  - [ ] bevel_bases_cylinderpp
- [ ] implement the utilities for the back-end solids
  - [x] trapezoid
  - [x] tetrahedron
  - [x] prism
- [ ] implement constructors
  - [ ] modifier `round_bases`
  - [x] modifier `round_corners`
  - [x] modifier `round_edges`
  - [x] modifier `bevel_bases`
  - [x] modifier `bevel_corners`
  - [x] modifier `bevel_edges`
- [ ] integrate constructors into the solid++
  - [ ] modifier `round_corners`
    - [ ] `cubepp`
    - [ ] `cylinderpp`
  - [ ] modifier `round_edges`
    - [ ] `cubepp`
    - [ ] `cylinderpp`
  - [ ] modifier `bevel_base`
    - [ ] `cubepp`
    - [ ] `cylinderpp`
  - [ ] modifier `bevel_corners`
    - [ ] `cubepp`
    - [ ] `cylinderpp`
  - [ ] modifier `bevel_edges`
    - [ ] `cubepp`
    - [ ] `cylinderpp`
