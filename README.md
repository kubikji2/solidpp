# Solid++

Solid++ extends the basic [OpenSCAD](https://openscad.org/) 2D shapes, 3D solids and
transformations with what everyday design for 3D printing needs, while keeping the original
arguments and behaviour. It stays plain OpenSCAD, so it is easy to pick up and to mix with
existing code.

- **Drop-in replacement.** Every `xxxpp` module behaves like its OpenSCAD original when called with the original named arguments: `cubepp([a, b, c])` is `cube([a, b, c])`, `mirrorpp(v)` is   `mirror(v)`. Everything else is optional.
- **No more positioning math.** `align` places a solid by its bounding box, `zet` turns it to any axis, and the transforms turn recurring patterns into one call: four corner holes, bolt   circles, holes drilled into a face, a part and its support blocker from one source.
- **Edges and holes made for printing.** Bevel, round or flare any edge with a list of modifiers (`mod_list=[fillet(2, "t"), chamfer(1, "b")]`), applied in one go without Minkowski sums; teardrop and polyhole holes, crush ribs, nut traps with flats, sectors.
- **More solids.** Tubes for heat inserts, tori, solids of revolution from your own profile,prisms over any convex base with a taper, the Platonic solids with helpers to engrave dice,   and 2D shapes with rounded corners.
- **One vocabulary for all solids.** The bounding box (`size`), its placement (`align`), the axis (`zet`) and the names of faces and edges work the same way everywhere.
- **Errors you can act on.** Arguments are validated and the messages say what is wrong and how to fix it, e.g. `fillet(6, where=["t"]): does not fit, ... the face is only 5 long`.
- **Deprecation instead of breakage.** Old arguments and modules keep working and echo the exact replacement call.
- **No dependencies.** Solid++ is plain OpenSCAD and does not depend on other libraries.

<table>
<tr><td align="center">

![quick start](docs/img/quickstart.png)

*a plate with rounded edges, corner holes and a teardrop hole*

</td></tr>
<tr><td>

```openscad
include<solidpp/solidpp.scad>

// a plate with rounded vertical edges and a chamfered top,
// four corner holes and a horizontal teardrop hole that prints without supports
difference()
{
    cubepp([60, 40, 10], center=true, mod_list=[rounding(5, "z-edges"), chamfer(1, "t")]);
    // one hole, mirrored into all four corners
    mirrorpp("xy", copy=true)
        translate([24, 14, 0])
            cylinderpp(d=3.4, h=20, center=true, mod_list=[chamfer(-0.8, "t")]);
    // horizontal hole along x with a teardrop pointing up (+z)
    cylinderpp(d=6, h=70, zet="x", center=true, section=teardrop(up="Z"));
}
```

</td></tr>
</table>

**Requirements:** OpenSCAD 2021.01 or newer. A [nightly build](https://openscad.org/downloads.html#snapshots) with the Manifold backend renders much faster, but is not required.

**Installation:** clone the repository (or add it as a git submodule) into your project or into the [OpenSCAD library folder](https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Libraries), and include the whole library with a single line:

```openscad
include<solidpp/solidpp.scad>
```

## Contents

- [Design ideas](#design-ideas)
- [Features at a glance](#features-at-a-glance)
- [Basic geometries and their OpenSCAD counterparts](#basic-geometries-and-their-openscad-counterparts)
  - [Bounding box: `size`](#bounding-box-size)
  - [Alignment: `align`](#alignment-align)
  - [Orientation: `zet`](#orientation-zet)
- [Modifiers](#modifiers)
  - [Naming the edges](#naming-the-edges)
  - [`bevel` and `rounding`](#bevel-and-rounding)
  - [Flares](#flares)
  - [Corners](#corners)
  - [Order and layering](#order-and-layering)
  - [Compatibility of the basic geometries](#compatibility-of-the-basic-geometries)
- [Round-solid options](#round-solid-options)
  - [Polygons and polyholes](#polygons-and-polyholes)
  - [Sectors](#sectors)
  - [Sections: teardrops and serrations](#sections-teardrops-and-serrations)
  - [Taper of `cubepp`](#taper-of-cubepp)
- [More solids](#more-solids)
  - [`tubepp`](#tubepp)
  - [`toruspp`](#toruspp)
  - [`revolvepp`](#revolvepp)
  - [`prismpp`](#prismpp)
  - [`platonicpp` and dice](#platonicpp-and-dice)
  - [Modifier support of all solids](#modifier-support-of-all-solids)
- [2D shapes](#2d-shapes)
- [Transforms](#transforms)
- [Migration from older versions](#migration-from-older-versions)
- [Tests, galleries and images](#tests-galleries-and-images)

## Sizing and Positioning

Three concepts apply to every Solid++ solid:

- `size`: the size of the solid's (axis-aligned) bounding box,
- `align`: the position of the bounding box relative to the origin, and
- `zet`: the dominant axis of the solid.

These concepts are shown using `cubepp`, `cylinderpp` and `spherepp`. Their original arguments (`r`, `d`, `h`, `r1`, `r2`, `d1`, `d2`, `center`) and the resolution (`$fn`, `$fa`, `$fs`) are kept and behave exactly as in OpenSCAD.

### Bounding box: `size`

The argument `size` is the size of the axis-aligned bounding box. It is the first positional argument, so the name can be omitted. A single number means the same value on all axes, as in `cube`. The same `size` works for `cylinderpp` and `spherepp` as well: the solid fills its bounding box.

| ![basic solids](docs/img/basic_solids.png)                                                             |
|:------------------------------------------------------------------------------------------------------:|
| *cubepp, cylinderpp (a cylinder and a cone), spherepp (a sphere and an ellipsoid), cylinderpp by size* |

The objects in the image, from left to right:

| Solid++ with `size`        | Solid++ with named arguments    | Raw OpenSCAD                    |
|----------------------------|---------------------------------|---------------------------------|
| `cubepp([20, 10, 8])`      | -                               | `cube([20, 10, 8])`             |
| `cylinderpp([10, 10, 12])` | `cylinderpp(d=10, h=12)`        | `cylinder(d=10, h=12)`          |
| -                          | `cylinderpp(d1=12, d2=4, h=12)` | `cylinder(d1=12, d2=4, h=12)`   |
| `spherepp(10)`             | `spherepp(d=10)`                | `sphere(d=10)`                  |
| `spherepp([16, 10, 10])`   | -                               | `resize([16, 10, 10]) sphere()` |
| `cylinderpp([10, 10, 16])` | `cylinderpp(d=10, h=16)`        | `cylinder(d=10, h=16)`          |

In general:

| Solid++                       | Raw OpenSCAD                                |
|-------------------------------|---------------------------------------------|
| `cubepp(a)`                   | `cube(a)`                                   |
| `cubepp([a, b, c])`           | `cube([a, b, c])`                           |
| `cylinderpp(a)`               | `cylinder(d=a, h=a)`                        |
| `cylinderpp([d, d, h])`       | `cylinder(d=d, h=h)`                        |
| `cylinderpp(d=[d1, d2], h=h)` | `cylinder(d1=d1, d2=d2, h=h)`               |
| `spherepp(a)`                 | `sphere(d=a)`                               |
| `spherepp([a, b, c])`         | `resize([a, b, c]) sphere()` (an ellipsoid) |

Good to know:

- The single positional argument behaves differently from OpenSCAD for the round solids, in favour of a unified behaviour:
  - `cylinder(10)` is a cylinder with `h=10` and `r=1`, while `cylinderpp(10)` fits the bounding box `[10, 10, 10]`,
  - `sphere(10)` has the radius 10, while `spherepp(10)` fits the bounding box `[10, 10, 10]`,
  - with named arguments (`r`, `d`, `h`) they behave exactly like the originals.
- `size` is always given in the parent frame `[x, y, z]`, whatever the orientation of the solid (see `zet` below).
- Elliptical cylinders are not supported: the two base dimensions of a `cylinderpp` must be equal.
- For a cone (`r1|d1`, `r2|d2`) the larger base defines the bounding box.
- `spherepp` builds the sphere with the largest diameter and scales it down for an ellipsoid, so the resolution follows the size and the vertices lie on the sphere as in OpenSCAD.

### Alignment: `align`

`align` places the bounding box relative to the origin, axis by axis:

1. a lowercase letter `x` / `y` / `z` in `align`: the box lies on the positive side of that axis
   - it touches the origin with its left / front / bottom side,
2. an uppercase letter `X` / `Y` / `Z` in `align`: the box lies on the negative side
   - it touches the origin with its right / back / top side,
3. an axis that is not mentioned is centered
   - `align=""` centers the box on all axes, the same as `center=true`.

| ![align](docs/img/align.png)                                                  |
|:-----------------------------------------------------------------------------:|
| *the coordinate frames mark the origins; align = "xyz", "", "z", "XYz", "xZ"* |

The cubes in the image, from left to right:

| Solid++                            | Raw OpenSCAD                                 |
|------------------------------------|----------------------------------------------|
| `cubepp([16, 12, 8], align="xyz")` | `cube([16, 12, 8])`                          |
| `cubepp([16, 12, 8], align="")`    | `cube([16, 12, 8], center=true)`             |
| `cubepp([16, 12, 8], align="z")`   | `translate([-8, -6, 0]) cube([16, 12, 8])`   |
| `cubepp([16, 12, 8], align="XYz")` | `translate([-16, -12, 0]) cube([16, 12, 8])` |
| `cubepp([16, 12, 8], align="xZ")`  | `translate([0, -6, -8]) cube([16, 12, 8])`   |

The defaults are those of the OpenSCAD originals:

- `cube` sits in the positive octant (`align="xyz"`),
- `cylinder` is centered in x/y and stands on z = 0 (`align="z"`),
- `sphere` is centered (`align=""`).

Good to know:

- `center=true` takes priority over any `align`.
- Some solids (`revolvepp`, `prismpp` and `polygonpp`) have one more option, `align="keep"`, which places their points exactly as given.

### Orientation: `zet`

Rotating and aligning cylinders is one of the most laborious parts of everyday OpenSCAD code. `zet` says which axis of the parent frame is the axis of the solid:

- `zet="x"` gives a horizontal cylinder left-right,
- `zet="y"` front-back,
- `zet="z"` (default) the usual vertical one.

| ![zet](docs/img/zet.png) |
|:------------------------:|
| *zet = "x", "y", "z"*    |

The cylinders in the image:

| Solid++                                       | Raw OpenSCAD                                                    |
|-----------------------------------------------|-----------------------------------------------------------------|
| `cylinderpp(d=10, h=24, zet="x", align="xz")` | `translate([0, 0, 5]) rotate([0, 90, 0]) cylinder(d=10, h=24)`  |
| `cylinderpp(d=10, h=24, zet="y", align="yz")` | `translate([0, 0, 5]) rotate([-90, 0, 0]) cylinder(d=10, h=24)` |
| `cylinderpp(d=10, h=24)` (`zet="z"`, default) | `cylinder(d=10, h=24)`                                          |

Good to know:

- The solid is turned first, then `size` and `align` are applied in the parent frame, so you never have to think about the rotated axes: `size=[x, y, z]` is always the left-right / front-back / bottom-top extent.
- Uppercase letters are accepted and mean the same axis: `zet="X"` is `zet="x"`, the solid is not flipped. The top of a solid is always its end in the positive direction of `zet`.
- `zet` also works for `cubepp`, where it decides which faces are the top and the bottom (this matters for the modifiers, described later).

## Modifiers

Modifiers change the edges and corners of a solid. They are passed as a list in `mod_list` and applied in reading order, for example `cubepp(20, mod_list=[rounding(5, "z-edges"), bevel(3, "t")])`. There are three modifiers; each takes a size value and an optional selector `where` (all edges or all corners by default). A negative value adds material instead of removing it, which has its own alias `flare`. The modifiers are as follows:

| modifier                        | alias                           | effect                               |
|---------------------------------|---------------------------------|--------------------------------------|
| `bevel(d, where="all")`         | `chamfer(d, where)`             | flat cut of the edges                |
| `rounding(r, where="all")`      | `fillet(r, where)`              | round (circular or elliptical) edges |
| `bevel_corners(d, where="all")` | `chamfer_corners(d, where)`     | flat cut of the corners (`cubepp`)   |
| `rounding(-r, where)`           | `flare(r, where)`               | a concave fillet into the base plane |
| `bevel(-d, where)`              | `flare(d, where, kind="bevel")` | a flat flare into the base plane     |

The aliases build exactly the same modifier; error messages show the name you used.

### Naming the edges

The following rules work for all solids:

- *Faces* have names.
- An *edge* is named by its two neighbouring faces.
- A *corner* is named by its three neighbouring faces.
- A *selector* selects every edge (or corner) whose faces include all faces of the selector.

| ![edge names](docs/img/edge_names.png) |
|:--------------------------------------:|
| *the face names of a box*              |

The faces are named as follows:

- For `cubepp`, the faces are named in the same way as for `align`: `x` / `X` left / right, `y` / `Y` front / back, `z` / `Z` bottom / top.
  - For example, the edge between the right and the back face is `"XY"`, and the corner at the top right back is `"XYZ"`.
- On every solid, the top `t` and the bottom `b` are the faces perpendicular to `zet` (for `zet="z"`: `t` = `Z`, `b` = `z`).
- For axially symmetric solids (such as `cylinderpp` and `tubepp`), the faces are the top `t`, the bottom `b`, the outer wall `o` and, if the solid has a hole, the inner wall `i`.
  - For example, `"to"` is the top outer edge, `"bi"` the bottom edge of the hole.
- For prisms and polygons, the sides are numbered `s0`, `s1`, ... in the order of the points.
- You can also give your own names: `revolvepp`, `prismpp` and `polygonpp` accept tags on their points (see the particular solids below).

Selectors (`where`) are a string or a list of strings:

| selector                              | selects                         | example                           |
|---------------------------------------|---------------------------------|-----------------------------------|
| `"all"`                               | every edge (the default)        | `cubepp`: 12 edges                |
| one face                              | every edge of that face         | `"t"`: the 4 top edges            |
| two faces                             | the edge between them           | `"XY"`: one vertical edge         |
| `"x-edges"`, `"y-edges"`, `"z-edges"` | the edges parallel to that axis | `"z-edges"`: the 4 vertical edges |
| a letter without a number             | all faces with that letter      | `"s"`: `s0`, `s1`, `s2`, ...      |
| a list                                | the union                       | `["t", "xy"]`                     |

Good to know:

- The order of the letters does not matter (`"to"` = `"ot"`).
- Names are case-sensitive: `x` and `X` are different faces.
- A selector that is invalid or matches nothing is an error.

### `bevel` and `rounding` modifiers

`bevel(d, where)` (alias `chamfer`) replaces each selected edge with a flat face: it cuts off the material between two lines, one on each face of the edge, at the distance `d` from the edge. `rounding(r, where)` (alias `fillet`) replaces each selected edge with an arc tangent to both faces: a circle of the radius `r`, or an ellipse.

The value can be:

- a number: the same size on both faces of the edge (the legs of a bevel, the radius of a rounding),
- a pair `[across, along]`:
  - `across` measured in the base plane,
  - `along` measured along `zet` (an asymmetric bevel, an elliptical rounding);
  - on an edge parallel to `zet` both faces are vertical, so `across` applies to both of them,
- a triplet `[x, y, z]` (`cubepp` only):
  - the size of the cut along each parent axis;
  - an edge uses the two components of the axes it runs across,
  - e.g. `bevel([3, 1, 0.5], "z-edges")` cuts 3 along x and 1 along y, and a top edge parallel to x is cut 1 along y and 0.5 along z.

| ![modifiers](docs/img/modifiers.png)                                                                                |
|:-------------------------------------------------------------------------------------------------------------------:|
| *rounding(3), bevel(3), rounding(5, "z-edges"), bevel(4, "t"), rounding([6, 2], "t"), bevel_corners(6), a cylinder* |

```openscad
cubepp(20, mod_list=[rounding(3)]);                     // all edges
cubepp(20, mod_list=[bevel(3)]);                        // = chamfer(3)
cubepp(20, mod_list=[rounding(5, "z-edges")]);          // edges parallel to z
cubepp(20, mod_list=[bevel(4, "t")]);                   // edges of the top base
cubepp(20, mod_list=[rounding([6, 2], "t")]);           // elliptical: [across, along]
cubepp(20, mod_list=[bevel_corners(6)]);                // corners
cylinderpp(d=20, h=20, mod_list=[rounding(4, "t"), bevel(2, "b")]);
```

Good to know:

- A modifier that does not fit (two roundings meeting on a face that is too short, a rounding crossing the axis of a cylinder) is an error that says which edges and how much is missing.

### Negative-value `bevel` and `rounding` (flares)

A negative value of `bevel` or `rounding` (or the alias `flare` with a positive value) adds material instead of removing it: a fillet or a chamfer from the wall of the solid into the base plane, e.g. where a part meets the print bed or another part.

| ![flares](docs/img/flares.png)                                         |
|:----------------------------------------------------------------------:|
| *flares on a cylinder, a box, a tube and a box aligned with its flare* |

```openscad
cylinderpp(d=10, h=20, mod_list=[flare(3, "b")]);                    // = rounding(-3, "b")
cubepp([16, 16, 20], align="z", mod_list=[flare(4, "b", kind="bevel")]);
tubepp(d=8, D=14, h=20, mod_list=[flare(3, "bo"), chamfer(1, "ti")]);
cubepp([12, 12, 16], mod_list=[flare(3, "b")], flare_in_align=true);
```

Good to know:

- Flares are allowed on base edges only (the edges of `t` and `b`).
- On a slanted wall (a cone, a tapered solid), the flare is tangent to the wall and to the base plane, so it follows the slope: on a wall leaning inwards, a flare of radius `r` reaches less than `r` along the base, on a wall leaning outwards more.
- The bounding box (and so `align`) ignores the flares by default; they stick out of it. For `cubepp` and `cylinderpp` (and the solids described later) this can be changed:
  - `flare_in_align=true` aligns the box including the flares, or
  - `flare_in_size=true` makes `size` include the flares (the body shrinks).

### Corner modifiers for `cubepp`

`bevel_corners(d, where)` (alias `chamfer_corners`) cuts the corners of a `cubepp` by a plane at the distance `d` along the three edges of each corner; `d` is a single value or `[x, y, z]` for each axis independently. The selector works as for edges: a corner is selected if its three faces include all faces of the selector:

- three faces select a single corner (`"XYZ"`, `"txy"`),
- two faces select the two corners of that edge (`"XY"`: the top and the bottom corner of the right back edge),
- one face selects its four corners (`"t"`: the four top corners).

### Order and layering

Modifiers are applied in reading order, which matters for boxes:

| ![layering](docs/img/layering.png)                        |
|:---------------------------------------------------------:|
| *vertical edges first, base edges first, a rounded bevel* |

```openscad
cubepp(20, mod_list=[rounding(5, "z-edges"), bevel(3, "t")]);   // the bevel follows the rounding
cubepp(20, mod_list=[bevel(3, "t"), rounding(5, "z-edges")]);   // the rounding cuts straight down
cubepp(20, mod_list=[bevel(5, "t"), rounding(1.5, "t")]);       // a bevel with rounded edges
```

- Edges parallel to `zet` modified *before* the base edges: the base modifiers follow the modified outline (swept). Modified *after* them: a straight vertical cut.
- A bevel can be rounded afterwards (its two new edges keep the name of the original edge).
- A rounded edge is final: modifying it again is an error ("already rounded").
- Zero values do nothing, so modifiers can be switched off with a variable.

### Compatibility of the basic geometries

| feature                             | `cubepp` | `cylinderpp` | `spherepp` |
|-------------------------------------|----------|--------------|------------|
| `bevel` / `chamfer`                 | **yes**  | **yes**      | no         |
| `rounding` / `fillet`               | **yes**  | **yes**      | no         |
| `[across, along]` values            | **yes**  | **yes**      | no         |
| `[x, y, z]` values                  | **yes**  | no           | no         |
| flares                              | **yes**  | **yes**      | no         |
| `bevel_corners` / `chamfer_corners` | **yes**  | no           | no         |
| `flare_in_align`, `flare_in_size`   | **yes**  | **yes**      | no         |

The table for all solids is at the end of [More solids](#modifier-support-of-all-solids).

## Additional Arguments for Round Solids

On top of the modifiers, the axially symmetric (round) solids have arguments of their own: `fn` and `polygon` set the polygon that approximates the circle, `sector` keeps only a part of the revolution, and `cross_section` changes the shape of the circle (teardrops for printable horizontal holes, serrations for grip and press fits). Not every round solid has all of them (`spherepp` has none):

| solid        | `fn`, `polygon`                            | `sector` | `cross_section`                              |
|--------------|--------------------------------------------|----------|----------------------------------------------|
| `cylinderpp` | **yes**                                    | **yes**  | **yes**                                      |
| `tubepp`     | per wall: `outer_fn`, `inner_polygon`, ... | **yes**  | `outer_cross_section`, `inner_cross_section` |
| `toruspp`    | **yes** (no `"polyhole"`)                  | **yes**  | no                                           |
| `revolvepp`  | **yes**                                    | **yes**  | no                                           |
| `circlepp`   | **yes**                                    | **yes**  | **yes**                                      |
| `ringpp`     | per wall: `outer_fn`, `inner_polygon`, ... | **yes**  | `outer_cross_section`, `inner_cross_section` |

### Polygons and polyholes

OpenSCAD approximates a circle by a regular polygon. This matters for printed parts: a hexagonal nut needs a hexagon that measures its size across the flats, and a small printed hole comes out smaller than its diameter. Two arguments control the polygon directly: `fn` gives the number of sides, `polygon` decides how the polygon relates to the diameter.

| ![polygons](docs/img/polygons.png)                                                        |
|:-----------------------------------------------------------------------------------------:|
| *fn = 6 with corners and with flats on the circle, a polyhole; the circle is transparent* |

```openscad
cylinderpp(d=12, h=6, fn=6);                            // corners on the circle (as OpenSCAD)
cylinderpp(d=12, h=6, fn=6, polygon="flats");           // flats on the circle: nut traps
cylinderpp(d=4, h=6, polygon="polyhole");               // nophead's polyhole
```

`fn` sets the number of sides of the solid only; the arcs of roundings keep following `$fn`, `$fa`, `$fs`. Without `fn`, the solid follows `$fn`, `$fa`, `$fs` as in OpenSCAD.

`polygon` is one of:

- `"corners"` (default) puts the corners on the circle, as OpenSCAD does: a hexagon with `d=12` measures *12 across the corners*.
- `"flats"` puts the flats on the circle: a hexagon with `d=12` measures *12 across the flats*, which is what a nut trap needs.
- `"polyhole"` implements [nophead's polyhole](https://hydraraptor.blogspot.com/2011/02/polyholes.html): the flats are on the circle and the number of sides is `max(round(2*d), 3)` (`d` in mm), so small printed holes keep their size. The number of sides is given, so setting `fn` as well is an error. A polyhole is meant for holes, so `toruspp` does not accept it.

The bounding box (and so `align`) is the one of the circle `d` in every mode.

### Sectors

`sector` keeps only a part of the revolution, e.g. a quarter of a cylinder or a C-shaped clip.

| ![sectors](docs/img/sectors.png)                                           |
|:--------------------------------------------------------------------------:|
| *sector = 90, [-45, 45], [0, 270] with rounding(1), and 90 with zet = "x"* |

```openscad
cylinderpp(d=16, h=4, sector=90);                                // a quarter
cylinderpp(d=16, h=4, sector=[-45, 45]);                         // a quarter around +x
cylinderpp(d=16, h=4, sector=[0, 270], mod_list=[rounding(1)]);  // the end faces stay sharp
cylinderpp(d=16, h=4, zet="x", sector=90);                       // starts at +y
```

- The value is either:
  - a single angle `a`: the sector from 0 to `a` (`sector=90` is a quarter), or
  - a pair `[from, to]`: the sector from `from` to `to`; `from` may be negative (`[-45, 45]`).
- The angles are in degrees; the sweep (`a`, or `to - from`) must be more than 0 and at most 360.
- The angles go counter-clockwise around `zet` (the right-hand rule), with 0 at the next axis of the cycle x -> y -> z -> x: +x for `zet="z"`, +y for `zet="x"` and +z for `zet="y"`.

Good to know:

- The bounding box (and so `align`) stays the one of the full solid.
- The flat end faces of the sector cannot be modified by `mod_list`; the other edges work as usual.
- A `tubepp` with a sector is a C-shape (a clip), see [More solids](#more-solids).
- A sector cannot be combined with `cross_section`.

### Cross-sections: teardrops and serrations

`cross_section` changes the shape of the circle of a round solid (its cross-section perpendicular to `zet`): `teardrop()` replaces the circle with a teardrop, `serration()` cuts grooves into the wall. A cross-section is an argument, not a modifier, so it works together with `mod_list`: the modifiers follow the new outline (a rounded teardrop).

| ![sections](docs/img/sections.png)                                |
|:-----------------------------------------------------------------:|
| *teardrop, bridged teardrop, serration, both, a rounded teardrop* |

```openscad
cylinderpp(d=12, h=6, zet="y", cross_section=teardrop(up="Z"));
cylinderpp(d=12, h=6, zet="y", cross_section=teardrop(up="Z", cap="bridge"));
cylinderpp(d=12, h=6, zet="y", cross_section=serration(16, 0.6));
cylinderpp(d=12, h=6, zet="y", cross_section=[teardrop(up="Z"), serration(12, 0.6, "round")]);
cylinderpp(d=12, h=6, zet="y", cross_section=teardrop(up="Z"), mod_list=[rounding(1)]);
```

Cross-sections are available for the circular walls of:

- `cylinderpp` as `cross_section`,
- `tubepp` as `outer_cross_section`, and `inner_cross_section` for inner and outer crossesction respectively,
- `circlepp` as `cross_section`, and
- `ringpp` as `outer_cross_section`, and `inner_cross_section` for inner and outer crossesction respectively.

The bounding box (and so `align`) is always the one of the circle.

#### Teardrop

`teardrop(up, angle=45, cap="point")` makes a hole printable without supports when its axis is parallel to the print bed. The top of a circular hole is an overhang that sags; a teardrop replaces it with two flat faces meeting in a tip.

| argument | meaning                                                                                                      |
|----------|--------------------------------------------------------------------------------------------------------------|
| `up`     | the face letter the tip points to (`x`, `X`, `y`, `Y`, `z`, `Z` as in `align`), perpendicular to `zet`       |
| `angle`  | the angle of the two tip faces from the horizontal, between 0 and 90 (default 45, the usual printable slope) |
| `cap`    | `"point"`: the classic tip; `"bridge"`: the tip cut flat at the top of the circle (a short bridge)           |

Good to know:

- The default `up` is `"Z"` (the tip points up) for a horizontal axis (`zet="x"` or `"y"`), and `"x"` for `zet="z"`.
- With `cap="point"` the tip sticks out of the circle (and out of the bounding box); with `cap="bridge"` the hole stays within its diameter.
- A teardrop works only with `polygon="corners"` (the default).

#### Serration

`serration(n, depth, profile="triangle", width)` cuts `n` grooves of the depth `depth` into the wall, along the axis:

| argument  | meaning                                                                        |
|-----------|--------------------------------------------------------------------------------|
| `n`       | the number of grooves (at least 2)                                             |
| `depth`   | the depth of the grooves                                                       |
| `profile` | `"triangle"`: a zig-zag of tips and roots (a knurl); `"round"`: round grooves  |
| `width`   | the width of a round groove (`"round"` only), default `2*depth`: a half circle |

Good to know:

- The grooves remove material, so `d` is measured at the tips.
- On a solid, serration gives grip (a knurled knob). On a hole (a serrated cylinder cut out of a part), the grooves leave ribs in the hole: crush ribs, a press fit for a pin, a bearing or a heat insert.
- The grooves run only along the straight part of the wall: the ends modified by `mod_list` (chamfers, roundings, flares) stay plain, which gives e.g. a hole with a lead-in chamfer without ribs. If the modifiers leave no straight part, it is an error.

#### Teardrop with serration

A list combines them: `cross_section=[teardrop(...), serration(...)]`. The teardrop (the base shape) comes first, then the serration; anything else is an error. The grooves are spread over the circular part of the teardrop only: the tip faces do not touch the rod, and grooves there would spoil the printable overhang.

## Taper

A tapered solid has two bases of different sizes joined by slanted walls. The cone `cylinderpp(d=[d1, d2], h=h)` from [Sizing and Positioning](#sizing-and-positioning) is one; `cubepp` tapers into a frustum of a pyramid when one of its bases is given by `size_top` or `size_bottom`.

| ![taper](docs/img/taper.png)                                                                |
|:-------------------------------------------------------------------------------------------:|
| *size_top with rounding(2), size_bottom with bevel(1, "t"), zet = "x" with rounded x-edges* |

```openscad
cubepp([24, 16, 14], size_top=[12, 8], mod_list=[rounding(2)]);
cubepp([16, 16, 12], size_bottom=10, mod_list=[bevel(1, "t")]);
cubepp([20, 14, 10], zet="x", size_top=[8, 4], mod_list=[rounding(1, "x-edges")]);
```

- `size` gives the height (along `zet`) and one base; `size_top` gives the top base instead, or `size_bottom` the bottom base (only one of them).
- The base is `[a, b]` along the two axes across `zet` in the order x, y, z:
  - `[x, y]` for `zet="z"`,
  - `[y, z]` for `zet="x"`, and
  - `[x, z]` for `zet="y"`.
  - A single number is a square base.

Good to know:

- Both bases are centred on the same axis.
- The bounding box (and so `align`) is the one of the larger base.
- The modifiers follow the slanted walls; the edges along `zet` are slanted but keep their names (`"z-edges"` for `zet="z"`).
- The deprecated `trapezoid()` is now a tapered `cubepp`; it echoes the replacement.
- `prismpp` (see [More solids](#more-solids)) tapers by a scale or by a draft angle.

## More solids

On top of the counterparts of the OpenSCAD primitives, Solid++ adds solids without a direct counterpart. They follow the same conventions: `align`, `zet` and `center` place them, and `mod_list` modifies their edges.

### `tubepp`

```openscad
tubepp(size, t, r|d, R|D, h, align, zet, center, mod_list,
       outer_fn, inner_fn, outer_polygon, inner_polygon,
       flare_in_align, flare_in_size, outer_cross_section, inner_cross_section, sector)
```

`tubepp` is a hollow cylinder defined by exactly two of:

- `t`: the wall thickness,
- `r|d`: the radius/diameter of the inside (the hole),
- `R|D`: the radius/diameter of the outside.

Each of them is a number or `[bottom, top]` (a conical tube). `h` is the height (default 1).

`size` follows the same convention as for `cylinderpp` (a number or `[x, y, z]` in the parent frame): it replaces `R|D` and `h`, so one of `t` or `r|d` is still needed, e.g. `tubepp(size=[10, 10, 5], t=1)`. Using `R|D`, `r|d`, `t` and `h` is recommended, as it reads more clearly.

The outside and the hole are independent: each wall has its own `fn`, `polygon` and `cross_section` (see [Additional Arguments for Round Solids](#additional-arguments-for-round-solids)), and the modifiers select the edges of the hole with `i` (`"ti"` is the top edge of the hole):

| argument                                     | meaning                                                                         |
|----------------------------------------------|---------------------------------------------------------------------------------|
| `outer_fn`, `inner_fn`                       | the number of sides of the outer wall and of the hole                           |
| `outer_polygon`, `inner_polygon`             | the polygon mode of each wall, e.g. `inner_polygon="polyhole"` a printed hole   |
| `outer_cross_section`, `inner_cross_section` | the cross-section of each wall, e.g. crush ribs in the hole                     |
| `flare_in_align`, `flare_in_size`            | as for `cylinderpp`; `flare_in_size` keeps the flares within the outer diameter |
| `sector`                                     | cuts the outer body only, the hole stays round: a C-shape                       |

| ![tube](docs/img/tube.png)                                    |
|:-------------------------------------------------------------:|
| *a heat insert boss, an octagonal tube, crush ribs, a C-clip* |

```openscad
tubepp(d=4.2, D=10, h=8, mod_list=[chamfer(0.6, "ti"), flare(2, "bo")]);              // heat insert boss
tubepp(d=6, D=14, h=10, outer_fn=8, outer_polygon="flats", mod_list=[rounding(1, "o")]);
tubepp(d=5.2, D=12, h=10, inner_cross_section=serration(6, 0.25, "round"));            // crush ribs
tubepp(d=10, D=14, h=6, sector=[-130, 130], mod_list=[rounding(0.8)]);                 // a C-clip
```

Good to know:

- The hole must be smaller than the outside at both ends, and its radius must be positive (a tube without a hole is a `cylinderpp`).
- A flare on a hole edge (`"bi"`, `"ti"`) adds material into the hole along the base plane: the hole narrows at that end.

### `toruspp`

```openscad
toruspp(t, r|d, R|D, h, align, zet, center, fn, polygon, sector)
```

`toruspp` is a ring with a circular or elliptical tube (a donut) defined by exactly two of:

- `t`: the width of the tube (radially, from the hole to the outside),
- `r|d`: the radius/diameter of the inside (the hole),
- `R|D`: the radius/diameter of the outside.

`h` is the height of the tube along `zet`: the default `h = t` gives a circular tube, another value an elliptical one. The default alignment is centered (`""`). The hole must not close: with `r = 0` the tube would touch the axis in a single point, which is not a valid solid. `fn` sets the number of sides around the axis only; the tube itself follows `$fn`, `$fa`, `$fs`. `toruspp` has no `mod_list`.

| ![torus](docs/img/torus.png)                  |
|:---------------------------------------------:|
| *a ring, an elliptical tube, a sector, flats* |

```openscad
toruspp(t=4, R=10);
toruspp(t=4, r=6, h=8);
toruspp(t=4, R=10, sector=[0, 270]);
toruspp(t=4, R=10, fn=6, polygon="flats");
```

### `revolvepp`

```openscad
revolvepp(points, align, zet, center, mod_list, fn, polygon, flare_in_align, sector)
```

`revolvepp` revolves your own profile around `zet`, with the modifiers. The profile is a list of points `[x, y]`:

- `x` is the distance from the axis (`x >= 0`),
- `y` is the position along `zet`,
- the profile is closed automatically: the last point connects to the first one, so do not repeat the first point at the end,
- the profile must not intersect itself; its orientation (clockwise or counter-clockwise) does not matter.

Unlike `rotate_extrude` of a 2D child, the bounding box is known (computed from the points), so `align` works. The default is `align="z"` as for `cylinderpp`; `align="keep"` places the points as given (the axis through the origin, `y` along `zet`).

Every segment (from a point to the next one) is a face with an automatic name:

- `t` / `b` if it is horizontal and faces up / down, otherwise
- `o` / `i` if it faces away from / towards the axis;
- a segment on the axis has no name (it is not a face).

A tag `[x, y, "name"]` adds a name to the segment that starts at that point:

| tag                                                         | result                                       |
|-------------------------------------------------------------|----------------------------------------------|
| a new name, e.g. `"g"`, `"k1"`                              | added                                        |
| the segment's own default letter, e.g. `"t1"` on a top face | added (a refinement: `"t"` still selects it) |
| another default letter, e.g. `"t"` on a slanted `o` face    | error, unless forced: `[x, y, "t", "f"]`     |
| `x X y Y z Z`                                               | error (reserved)                             |

| ![revolvepp](docs/img/revolvepp.png)               |
|:--------------------------------------------------:|
| *a knob from a profile, a grooved polygonal shaft* |

```openscad
knob = [[0, 0], [12, 0], [12, 6, "s"], [7, 6], [7, 18, "k"], [0, 18]];
revolvepp(knob, mod_list=[fillet(1.5, "s"), chamfer(1, "k"), fillet(1, "bo")]);
revolvepp([[0, 0], [10, 0], [10, 8], [8, 9, "g"], [10, 10], [10, 18], [0, 18]],
          fn=12, polygon="flats", mod_list=[fillet(0.5, "g"), chamfer(1, "t")]);
```

Good to know:

- A positive value on a concave edge fills it: the shoulder fillet above rounds the outer edge of the shoulder and fills the inner one.
- A broad selector also matches refined edges: with the top tagged `"k"`, `"to"` selects the edge `"tok"` too. Put the specific modifier first, or use specific names.
- The profile may touch the axis only along segments, not in a single point.
- `polygon` is measured at the largest radius of the profile.

### `prismpp`

```openscad
prismpp(points, h, align, zet, center, mod_list, flare_in_align, scale, scale_center, draft)
```

`prismpp` is a prism of the height `h` over a base given by `points`, with the same modifiers as `cubepp`:

- the points are `[x, y]` or `[x, y, "tag"]`, drawn as for `zet="z"`,
- the base must be strictly convex; its orientation does not matter,
- the base is closed automatically, as for `revolvepp`.

The faces are `t`, `b` and the sides `s0`, `s1`, ...: side `k` runs from point `k` to point `k+1` (also for clockwise input). A tag adds a name to the side that starts at its point; `t`, `b`, `s` and `x X y Y z Z` are reserved. The default alignment is `"keep"` (as `linear_extrude`): the points stay as given, the bottom on the plane through the origin.

| selector    | edges                                       |
|-------------|---------------------------------------------|
| `"s2"`      | the 4 edges of side 2                       |
| `"ts2"`     | the top edge of side 2                      |
| `"s1s2"`    | the edge between sides 1 and 2              |
| `"z-edges"` | the edges between the sides (for `zet="z"`) |
| `"g"`       | the edges of the side tagged `g`            |

A prism can be tapered by one of:

- `scale=s`: the top is the base scaled by `s` about `scale_center` (default the centroid of the base); `s > 1` makes the top larger (an overhang),
- `draft=angle` or `draft=[a0, a1, ...]` (one per side): every side leans inwards by its angle (outwards if negative); 45 gives self-supporting walls, 0 keeps a side vertical.

| ![prismpp](docs/img/prismpp.png)                                                       |
|:--------------------------------------------------------------------------------------:|
| *a pentagonal prism: vertical roundings, a flared base with one rounded side, a draft* |

```openscad
pent = [[0, 0], [16, 0, "g"], [19, 10], [8, 17], [-3, 10]];
prismpp(pent, h=8, mod_list=[fillet(3, "z-edges"), chamfer(1, "t")]);
prismpp(pent, h=8, mod_list=[flare(2, "b"), fillet(2, "tg")]);
prismpp(pent, h=12, draft=20, mod_list=[fillet(1.5)]);
prismpp([for (k = [0:5]) 10*[cos(60*k), sin(60*k)]], h=14, scale=0.5, mod_list=[rounding(1)]);
```

Good to know:

- The edges between the sides take a single number (the legs are measured along the sides); `[across, along]` works on the base edges only.
- With a taper, the edges between the sides are slanted but keep their selector (`"z-edges"` for `zet="z"`), and the bounding box includes the top.

### `platonicpp`

```openscad
platonicpp(n, a|d|D, align, zet, center, mod_list)
```

The five Platonic solids, with `n` = 4, 6, 8, 12 or 20 faces. They lie on a face (ready to print), with the default alignment `"z"`. Each has a wrapper that fixes `n` and takes the other arguments:

| wrapper          | `n` | die |
|------------------|-----|-----|
| `tetrahedronpp`  | 4   | d4  |
| `hexahedronpp`   | 6   | d6  |
| `octahedronpp`   | 8   | d8  |
| `dodecahedronpp` | 12  | d12 |
| `icosahedronpp`  | 20  | d20 |

The size is given by at most one of:

| size | meaning                                                                |
|------|------------------------------------------------------------------------|
| `a`  | the edge length (default 1)                                            |
| `d`  | the diameter of the inscribed sphere: the size of a die (face to face) |
| `D`  | the diameter of the circumscribed sphere (through the vertices)        |

The tetrahedron has no opposite faces: its `d` is half of its height.

All edges and corners are equivalent, so the modifiers take only `where="all"` (the default) and a single number:

- `bevel` / `chamfer`,
- `bevel_corners` / `chamfer_corners`, up to half the edge (`a/2` cuts the edges away completely),
- `rounding` / `fillet`, which must be the last one.

The faces stay in place, so the modifiers change neither the alignment nor the positions given by the helpers below.

### Dice: `platonicpp_faces` and `platonicpp_vertices`

```openscad
platonicpp_faces(n, a|d|D, align, zet, center, idx, numbering) children
platonicpp_vertices(n, a|d|D, align, zet, center, idx) children
```

The two helpers turn a Platonic solid into a die: they place their children on the faces or on the vertices of the `platonicpp` with the same arguments (`n`, size, `align`, `zet`, `center`).

- `platonicpp_faces` places the children on every face: the origin in the center of the face, z outward, y towards the top (x on the top and bottom faces), so `text()` reads from outside.
- `platonicpp_vertices` places the children on every vertex: the origin in the vertex, z outward from the center.
- `idx` selects the faces (vertices) by their numbers: a number or a list (default all).

The children see the special variables:

| variable         | meaning                                                                      |
|------------------|------------------------------------------------------------------------------|
| `$face`          | the number of the face (0 ... n-1)                                           |
| `$face_vertices` | the numbers of the corners of the face, counter-clockwise                    |
| `$face_corners`  | the 2D positions of the corners in the frame of the face (in the same order) |
| `$vertex`        | the number of the vertex (`platonicpp_vertices`), from the top down          |

`numbering` sets the order of the faces:

| `numbering`            | order of `$face`                                                                        |
|------------------------|-----------------------------------------------------------------------------------------|
| `"opposite"` (default) | face `k` is opposite to face `n-1-k`: labels `k+1` add up to `n+1` on opposite faces    |
| `"sequential"`         | consecutive faces share an edge, the last is next to the first: a spindown life counter |

| ![dice](docs/img/dice.png)         |
|:----------------------------------:|
| *d6, d20, a spindown d20 and a d4* |

```openscad
module label(s, size) translate([0, 0, -0.6]) linear_extrude(1) text(s, size=size, halign="center", valign="center");

difference() { hexahedronpp(d=16, mod_list=[fillet(1.5)]); platonicpp_faces(6, d=16) label(str($face + 1), 7); }
difference() { icosahedronpp(d=20, mod_list=[fillet(0.8)]); platonicpp_faces(20, d=20) label(str($face + 1), 3.5); }
difference()
{
    icosahedronpp(d=20, mod_list=[chamfer(0.5)]);
    platonicpp_faces(20, d=20, numbering="sequential") label(str(20 - $face), 3.5);
}
// a d4 is read at the corners: each face shows the numbers of its corners
difference()
{
    tetrahedronpp(a=24, mod_list=[fillet(1)]);
    platonicpp_faces(4, a=24)
        for (k = [0:2])
            let(c = $face_corners[k])
                translate(0.55*c) rotate(atan2(c[1], c[0]) - 90) label(str($face_vertices[k] + 1), 3);
}
```

### Modifier support of all solids

| feature                             | `cubepp` | `cylinderpp` | `spherepp` | `tubepp` | `toruspp` | `revolvepp` | `prismpp`  | `platonicpp` |
|-------------------------------------|----------|--------------|------------|----------|-----------|-------------|------------|--------------|
| `bevel` / `chamfer`                 | **yes**  | **yes**      | no         | **yes**  | no        | **yes**     | **yes**    | **yes**      |
| `rounding` / `fillet`               | **yes**  | **yes**      | no         | **yes**  | no        | **yes**     | **yes**    | **yes**      |
| selectors (`where`)                 | **yes**  | **yes**      | no         | **yes**  | no        | **yes**     | **yes**    | `"all"`      |
| `[across, along]` values            | **yes**  | **yes**      | no         | **yes**  | no        | **yes**     | base edges | no           |
| `[x, y, z]` values                  | **yes**  | no           | no         | no       | no        | no          | no         | no           |
| flares                              | **yes**  | **yes**      | no         | **yes**  | no        | **yes**     | **yes**    | no           |
| `bevel_corners` / `chamfer_corners` | **yes**  | no           | no         | no       | no        | no          | no         | **yes**      |
| `flare_in_align`                    | **yes**  | **yes**      | no         | **yes**  | no        | **yes**     | **yes**    | no           |
| `flare_in_size`                     | **yes**  | **yes**      | no         | **yes**  | no        | no          | no         | no           |
| `fn`, `polygon`                     | no       | **yes**      | no         | per wall | **yes**   | **yes**     | no         | no           |
| `sector`                            | no       | **yes**      | no         | **yes**  | **yes**   | **yes**     | no         | no           |
| `cross_section`                     | no       | **yes**      | no         | per wall | no        | no          | no         | no           |
| taper                               | **yes**  | **yes**      | no         | **yes**  | no        | profile     | **yes**    | no           |
| `align="keep"`                      | no       | no           | no         | no       | no        | **yes**     | **yes**    | no           |
| default `align`                     | `"xyz"`  | `"z"`        | `""`       | `"z"`    | `""`      | `"z"`       | `"keep"`   | `"z"`        |

The tapers: `cubepp` by `size_top` or `size_bottom`, `cylinderpp` and `tubepp` by `[bottom, top]` radii or diameters, `prismpp` by `scale` or `draft`, `revolvepp` by its profile. On `revolvepp`, a positive value on a concave edge fills it.

## 2D shapes

The 2D shapes follow the same conventions as the solids, in the plane: `align` and `center` place them (with the letters `x`, `X`, `y`, `Y` only), and `mod_list` modifies their corners. `squarepp` and `circlepp` are the counterparts of `square` and `circle`; `polygonpp` (a polygon with modifiable corners) and `ringpp` (the 2D `tubepp`) are new.

```openscad
squarepp(size, align, center, mod_list, flare_in_align)
polygonpp(points, align, center, mod_list, flare_in_align)
circlepp(size|r|d, align, center, fn, polygon, sector, cross_section)
ringpp(t, r|d, R|D, align, center, outer_fn, inner_fn, outer_polygon, inner_polygon,
       sector, outer_cross_section, inner_cross_section)
```

| ![2D shapes](docs/img/shapes2d.png)                                             |
|:-------------------------------------------------------------------------------:|
| *squarepp, squarepp with feet, polygonpp, a teardrop circlepp, a ringpp sector* |

```openscad
squarepp([18, 12], mod_list=[fillet(3, "Y"), chamfer([4, 2], "xy")]);
squarepp([14, 12], mod_list=[flare(3, "y")]);
polygonpp([[0, 0], [16, 0], [16, 6], [6, 6], [6, 14], [0, 14]], mod_list=[fillet(1.5)]);
circlepp(d=14, cross_section=teardrop());
ringpp(d=4, D=14, inner_polygon="polyhole", sector=[0, 270]);
```

### `squarepp` and `polygonpp`

`squarepp(size, ...)` takes a number or `[x, y]` (default 1).

`polygonpp(points, ...)` takes a list of points `[x, y]` or `[x, y, "tag"]`:

- the outline is closed automatically (do not repeat the first point),
- it may be concave, but it must not intersect itself; its orientation does not matter,
- points collinear with their neighbours are not corners (they cannot be modified).

The modifiers work on the corners as they do on the edges of a solid: the sides are the faces, and a corner is named by its two sides.

| shape       | sides                  | corners                        | values                          |
|-------------|------------------------|--------------------------------|---------------------------------|
| `squarepp`  | `y`, `X`, `Y`, `x`     | `"xy"`, `"Xy"`, `"XY"`, `"xY"` | a number or `[dx, dy]`          |
| `polygonpp` | `s0`, `s1`, ... + tags | `"s0s1"`, ...                  | a number (legs along the sides) |

- The sides of `squarepp` are named as the faces of `cubepp`: `x` / `X` left / right, `y` / `Y` bottom / top.
- The sides of `polygonpp` are numbered as for `prismpp`: side `k` runs from point `k` to point `k+1`. A tag adds a name to the side that starts at its point, e.g. `[16, 0, "g"]` names the side from that point to the next one `g`; `t`, `b`, `s` and `x X y Y z Z` are reserved.
- A selector picks corners as on a solid: one side selects its two corners (`"Y"`, `"s2"`, `"g"`), two sides one corner (`"xy"`, `"s0s1"`), `"all"` every corner.
- `bevel` / `chamfer` and `rounding` / `fillet` are supported, `bevel_corners` is not (a 2D shape has no corners of three sides).
- On `polygonpp`, a positive value on a concave corner fills it (as on `revolvepp`).
- The rules of [Order and layering](#order-and-layering) hold: a bevel can be rounded afterwards, a rounded corner is final.

#### Flares in 2D

A negative value (or `flare`) adds material: one side of the corner is extended beyond the corner, and a fillet or a chamfer joins it to the other side, e.g. feet under a profile. In 2D there is no base plane, so the selector says which side is the base: the first name of the selector is the base side, the other names pick the corner.

- `flare(3, "y")` puts feet on both ends of the bottom side `y`,
- `flare(3, "yX")` only on its right end,
- `flare(3, "Xy")` extends the right side `X` downwards instead.

A flare needs a base side, so `"all"` is an error, and so is a corner flared from both of its sides by one modifier. `flare_in_align=true` aligns the bounding box including the flares, by default it is not part of the aligning.

### `circlepp` and `ringpp`

`circlepp` takes `size`, `r` or `d` (one of them, default `d=1`): a number, or `[x, y]` for an ellipse. `ringpp` is defined by exactly two of `t` (the width of the ring), `r|d` (the hole) and `R|D` (the outside), as `tubepp`; the hole must fit inside the outer outline.

Both take the arguments of the round solids (see [Additional Arguments for Round Solids](#additional-arguments-for-round-solids)), `ringpp` per circle as `tubepp`:

- `fn` and `polygon` (`"corners"`, `"flats"`, `"polyhole"`),
- `sector`: counter-clockwise from +x; on `ringpp` it cuts the whole ring,
- `cross_section`: `teardrop()` and `serration()`; in 2D the teardrop `up` is `"x"`, `"X"`, `"y"` or `"Y"` (default `"Y"`, the tip points to +y).

`polygon` modes other than `"corners"`, `sector` and `cross_section` work for circles only, not for ellipses. The bounding box is always the one of the full circle. There are no modifiers (`mod_list`): a circle has no corners.

### Alignment and modifier support of 2D shapes

| feature               | `squarepp` | `polygonpp` | `circlepp` | `ringpp`   |
|-----------------------|------------|-------------|------------|------------|
| `bevel` / `chamfer`   | **yes**    | **yes**     | no         | no         |
| `rounding` / `fillet` | **yes**    | **yes**     | no         | no         |
| `[dx, dy]` values     | **yes**    | no          | no         | no         |
| flares                | **yes**    | **yes**     | no         | no         |
| `flare_in_align`      | **yes**    | **yes**     | no         | no         |
| `fn`, `polygon`       | no         | no          | **yes**    | **yes** (per circle) |
| `sector`              | no         | no          | **yes**    | **yes**    |
| `cross_section`       | no         | no          | **yes**    | **yes** (per circle) |
| `align="keep"`        | no         | **yes**     | no         | no         |
| default `align`       | `"xy"`     | `"keep"`    | `""`       | `""`       |

`squarepp` keeps the alignment of `square` (`"xy"`, the corner at the origin), `polygonpp` keeps the points as given (as `polygon`), `circlepp` and `ringpp` are centered (as `circle`).

## Transforms

All transforms keep the behaviour of their OpenSCAD originals by default.

| transform                                                     | what it adds                                                                             |
|---------------------------------------------------------------|------------------------------------------------------------------------------------------|
| `mirrorpp(v, copy=false, point)`                              | keeps the original, several axes, the mirror plane through a point                       |
| `hull_if`, `minkowski_if`, `difference_if`, `intersection_if` | the operation only if `condition` is true, otherwise `otherwise` picks the kept children |
| `replicate_at(pos, rot, x, y, z)`                             | copies at positions or on a grid, `$idx`, `$pos`, `$rot`                                 |
| `replicate_around(n, r, angle, start, zet, orient, point)`    | copies in a circle or an arc, `$idx`, `$angle`                                           |
| `pairwise_hull(closed=false)`                                 | hulls of consecutive children, `closed` also the last with the first                     |
| `linear_extrudepp(height, ..., zet)`                          | negative height, twist compensation, `zet`                                               |
| `rotate_extrudepp(zet, sector, fn)`                           | `zet` and the `sector` convention of the solids                                          |
| `projectpp(point, normal, cut)`                               | projection onto any plane                                                                |
| `cut(sector, zet, size, point)`                               | removes a wedge (cut-away views)                                                         |
| `transform_to_spp(size, align, pos, x, y, z, orient)`         | moves to a point of a bounding box, turns z out of a face                                |

### `mirrorpp`

| ![mirrorpp](docs/img/mirrorpp.png)                                   |
|:--------------------------------------------------------------------:|
| *four corner holes, eight mirrored copies, a mirror plane at x = 70* |

```openscad
// one hole, four corners
difference()
{
    cubepp([40, 30, 4], center=true, mod_list=[fillet(4, "z-edges")]);
    mirrorpp("xy", copy=true) translate([15, 10, 0]) cylinderpp(d=3.4, h=10, center=true);
}
mirrorpp("xyz", copy=true) translate([4, 4, 4]) spherepp(3);            // all 8 combinations
mirrorpp([1, 0, 0], point=[70, 0, 0], copy=true) translate([62, -5, -2]) cubepp([5, 10, 4]);
```

- `v` is a vector (a single mirror, as `mirror`) or axis letters (the case does not matter). The letters make every combination of their mirrors: `"xy"` gives the copies mirrored in x, in y and in both.
- `copy=true` keeps the original as well; `copy=false` (default, as `mirror`) makes only the mirrored copies: one for a vector, three for `"xy"`.
- `point` moves the mirror plane(s) through that point (default the origin).

### Conditional operations

`hull_if`, `minkowski_if`, `difference_if` and `intersection_if` take the arguments `(condition, otherwise)` and apply their operation to the children only if `condition` is true. Otherwise, `otherwise` selects what is kept:

| `otherwise`         | kept                                                   |
|---------------------|--------------------------------------------------------|
| `"first"` (default) | `children(0)`, e.g. the body without the holes         |
| `"rest"`            | `children(1)`, `children(2)`, ..., e.g. only the holes |
| `"all"`             | all children                                           |
| `"none"`            | nothing                                                |
| a number or a list  | these children                                         |

A typical use is one source for two exports: the part, and a support blocker for the slicer (a volume where the slicer must not add supports), e.g. in holes that bridge well without them.

| ![support blocker](docs/img/support_blocker.png)   |
|:--------------------------------------------------:|
| *the part and its support blocker from one source* |

```openscad
module part(holes=true)
    difference_if(holes, otherwise="rest")
    {
        cubepp([30, 20, 10], center=true);
        mirrorpp("x", copy=true) translate([9, 0, 0]) cylinderpp(d=5, h=30, zet="y", center=true);
    }
part(true);     // the part
part(false);    // the support blocker: only the holes
```

### Replication

`replicate_at(pos, rot, x, y, z)` places copies of the children at the given positions:

- `pos` is a list of positions `[[x, y, z], ...]`,
- `rot` is a list of rotations `[[ax, ay, az], ...]`, each applied before its translation; with `pos` (or a grid) they pair up by index, so the lists must have the same length; alone, the rotated copies stay at the origin,
- `x`, `y`, `z` (each a number or a list) make a grid of all their combinations instead of `pos`; a missing axis is 0, and the copies are ordered by x, then y, then z,
- the children see `$idx` (the number of the copy, from 0), `$pos` (its position) and `$rot` (its rotation).

`replicate_around(n, r=0, angle=360, start=0, zet, orient=true, point)` places `n` copies around an axis:

- `r` is the distance of the copies from the axis,
- with `angle=360` the copies are spread evenly around; otherwise the first copy is at `start` and the last at `start + angle`,
- `start` is the angle of the first copy; the angles go around `zet` as for `sector` (0 at +x for `zet="z"`),
- `zet` is the axis (default `"z"`), `point` a point it passes through (`[x, y, z]`, default the origin),
- `orient=true` (default) turns every copy by its angle (spokes keep pointing outwards), `orient=false` only moves it (e.g. upright text),
- the children see `$idx` (the number of the copy, from 0) and `$angle` (its angle).

| ![replicate](docs/img/replicate.png)      |
|:-----------------------------------------:|
| *a bolt circle, a grid with $idx, spokes* |

```openscad
difference()                                                        // a bolt circle
{
    tubepp(d=12, D=40, h=5, mod_list=[chamfer(0.8, "to")]);
    replicate_around(6, r=15) cylinderpp(d=3.4, h=12, center=true);
}
replicate_at(x=[0, 10, 20], y=[0, 10]) cylinderpp(d=3 + $idx, h=4 + 2*$idx);   // $idx: per copy
replicate_around(5, r=12, angle=180) cubepp([8, 2, 2], center=true);         // spokes
```

### Extrusions, projections, cuts and placement

`linear_extrudepp(height=5, center, convexity, twist, slices, scale, compensate_rotation=true, zet)` works as `linear_extrude` with two additions. A negative `height` extrudes downwards, so the 2D children become the top face; with a `twist`, the solid is then turned so that this face still matches the children (`compensate_rotation=false` turns this off). `zet` extrudes along x or y; the children are turned like every solidpp solid.

`rotate_extrudepp(zet, sector, fn, convexity)` revolves the 2D children (in x >= 0, x being the distance from the axis and y the position along it) around `zet`, with `sector` as for the solids and `fn` sides. OpenSCAD cannot measure children, so there is no alignment; use `revolvepp` for a profile given by points.

`projectpp(point=[0, 0, 0], normal=[0, 0, 1], cut=false)` projects onto any plane: the plane through `point` with the `normal` (a vector or a face letter such as `"X"`) is moved to z = 0 and `projection(cut)` is applied. The result is seen from the side the normal points to; for `"Z"` (the default) x and y stay as they are.

`cut(sector, zet, size, point)` removes a wedge around the axis `zet` through `point`, e.g. for cut-away views. The `sector` of the wedge follows the convention of the solids: a positive angle `a` is `[0, a]`, a negative one `[a, 0]`, and a pair `[from, to]` goes counter-clockwise, wrapping around when `to < from` (`[90, -90]` removes 90 to 270). The largest value of `size` is the radius and the height of the wedge (default 1000).

`transform_to_spp(size, align, pos, x, y, z, orient=false)` moves the children to a point of a bounding box with the given `size` and `align` (an align string; `"keep"` describes no box and is an error):

- `pos` uses the letters of `align`: `"xyz"` a corner, `"Z"` the center of the top, `"XZ"` the middle of an edge, `""` the center,
- `x`, `y`, `z` in [0, 1] interpolate along an axis and take priority over `pos` (`pos="yZ", x=0.25` is a quarter along the front top edge),
- `orient=true` also turns the children so that their z points out of that face (or along the diagonal of an edge or a corner), with y up where possible, so text reads from outside.

`get_translation_to_spp(...)` and `get_orientation_to_spp(pos)` return the numbers. `CUBEPP_DEF_ALIGN`, `CYLINDERPP_DEF_ALIGN` and `SPHEREPP_DEF_ALIGN` hold the default alignments, e.g. `transform_to_spp(size, CUBEPP_DEF_ALIGN, "Z")` for a `cubepp` with the default `align`.

| ![transforms](docs/img/transforms_misc.png)                               |
|:-------------------------------------------------------------------------:|
| *holes drilled into faces, a cut-away, a section, a closed pairwise hull* |

```openscad
// drilling into faces: orient=true turns the children's z out of the face
difference()
{
    cubepp(20, center=true, mod_list=[chamfer(1)]);
    for (f = ["X", "y", "Z", "XZ"])
        transform_to_spp(20, "", f, orient=true) cylinderpp(d=4, h=8, align="Z");
}
cut([0, 90]) { tubepp(d=8, D=16, h=20, center=true); cylinderpp(d=7.6, h=24, center=true); }
projectpp(point=[0, 0, 4], cut=true) cylinderpp(d=18, h=10, mod_list=[fillet(6, "t")]);
pairwise_hull(closed=true) { spherepp(3); translate([20, 0, 0]) spherepp(3); translate([10, 18, 0]) spherepp(3); }
```

## Migration from older versions

Old code keeps working: deprecated modules and arguments echo a message with the exact replacement, so the console tells you what to change.

**Old modifiers.** The old modifier functions are translated to the new ones with a `DEPRECATED` echo showing the new call:

| old                                           | new (examples of the echoed replacement)                                 |
|-----------------------------------------------|--------------------------------------------------------------------------|
| `round_corners(r=1)`                          | `rounding(1)`                                                            |
| `round_edges(r=1, axes="xy")`                 | `rounding(1, "z-edges")` (the edges of the plane `axes`)                 |
| `bevel_edges(bevel=1, axes="xyz")`            | `bevel(1)`                                                               |
| `round_bases(r=1)`                            | `rounding(1, ["b", "t"])`                                                |
| `bevel_bases(bevel_top=0.5)`                  | `bevel(0.5, "t")`                                                        |
| `bevel_corners(bevel=1)`                      | `bevel_corners(d=1)`                                                     |
| `tubepp(inner_mod_list=[round_bases(r=0.5)])` | `mod_list=[rounding(-0.5, ["bi", "ti"])]` (old inner values were flares) |

**Deprecated modules and arguments:**

| old                                       | replacement                                                       |
|-------------------------------------------|-------------------------------------------------------------------|
| `trapezoid(base, top, h)`                 | `cubepp(size, size_top)`                                          |
| `prism(points, h)`, `prism(points3D, n)`  | `prismpp(points, h=...)`, `linear_extrude`, `multmatrix` (echoed) |
| `hull_if(..., ommit_children=true/false)` | `otherwise="first"` / `otherwise="all"`                           |
| `cut(..., align, center)`                 | remove them (they never had an effect), `point`                   |

**Removed:** `tetrahedron(points)` (`tetrahedronpp` for a regular one), elliptical cylinders,
the `children()` profile of `cylinderpp` (`revolvepp`).

**Changed behaviour:**

- `cut(..., zet="y")` measures its angles like the `sector` of the solids (from +z, around +y);
  the old version started at +x and turned the other way.
- `spherepp` and `circlepp` take their resolution from the largest diameter (vertices on the
  sphere/circle as in OpenSCAD).
- `toruspp` needs a positive inner radius (`r = 0` touched the axis in a single point, which
  is not a valid solid).
- `prism(points2D, h)` produced nothing before; it now builds the prism.

## Tests, galleries and images

- `tests/test_*.scad`: assert-based tests of the data layer; run e.g.
  `openscad -o /tmp/out.echo tests/test_cubepp.scad`, the last line must be
  `ECHO: "ALL TESTS PASSED"`.
- `tests/gallery_*.scad`: visual smoke tests; render them (F6) to check that every
  combination gives a valid manifold.
- `docs/examples/*.scad` are the examples of this README; `docs/render_examples.sh` renders
  them to `docs/img/` with the OpenSCAD command line (`--render` for the full render, `--force`
  to render everything again, `OPENSCAD=...` for another binary); with ImageMagick installed
  the images are cropped to their content and limited to `MAX_WIDTH` pixels (default 720).
- [DESIGN.md](DESIGN.md) describes the internals: the profile and ring engines, the selector
  grammar, the stages of the box modifiers, and the roadmap.
