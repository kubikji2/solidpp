# Solid++

Solid++ improves basic [OpenSCAD](https://openscad.org/) geometries namely `cube`, `sphere` and `cylinder` to allow various centering and orientation without any laborious transformations within your code.
This repository is planned to be integrated into [OpenSCAD++] library.

## Main features

The `cube`, `sphere` and `cylinder` arguments are kept for their solid++ counterparts `cubepp`, `shperepp` and `cylinderpp`, but new unified arguments are presented, namely bounding box size (`size`), alignment (`center`) and orientation (`z`).

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

### Unified alignment aka `center` argument

### Unified orientation aka `z` argument

### Solid-specific properties