# Solid++

Solid++ improves basic [OpenSCAD](https://openscad.org/) geometries namely `cube`, `sphere` and `cylinder` to allow various centering and orientation without any laborious transformations within your code.
This repository is planned to be integrated into [OpenSCAD++] library.

## Main features

The `cube`, `sphere` and `cylinder` arguments are kept for their solid++ counterparts `cubepp`, `shperepp` and `cylinderpp`, but new unified arguments are presented, namely bounding box size (`size`), alignment (`align`) and orientation (`z`).

### Bounding box size aka `size` argument

Bounding box size defines the solids bounding box.
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

The default `cube` and `cubepp` alignment is `align="xyz"`, the default `sphere` and `spherepp` alignment is `align=""` (`align="c"`), and the default `cylinder` and `cylinderpp` is `align="z"`.

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
cube([a,b,], center=true);

// following lines results in the same solids
cubepp([a,b,c], aling="X");
translate([-a, -b/2, -c/2])
    cube([a,b,c]);
```


### Unified orientation aka `z` argument

### Solid-specific properties