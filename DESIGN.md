# Solid++ design: modifiers and the profile engine

Status: agreed design for the modifier refactor. Implemented: the engine,
`bevel()`/`rounding()`/`bevel_corners()`, `cylinderpp`, `tubepp`, `cubepp` and the
translation of the old modifiers (see Roadmap for the rest).

## 1. Principles

1. **Modifiers are data.** A modifier constructor (`bevel()`, `rounding()`) only
   validates and stores its arguments. Solids interpret them.
2. **Geometry is described as data and materialised once.** Every solid builds a
   description of its shape (a tagged 2D profile, later a stack of cross-section
   rings), applies the modifiers to that description, and only then emits geometry
   (`rotate_extrude(polygon(...))`, `hull()` of rings, ...). No CSG per modifier.
3. **Same maths as OpenSCAD.** Arcs use OpenSCAD's own fragment formula
   (`$fn`, `$fa`, `$fs`), so a rounded edge has the same facets as `circle()` or
   `offset(r=)` would.
4. **`mod_list` is applied in reading order.** `mod_list=[A, B]` means "A first,
   then B on the result".
5. **Modifiers keep the bounding box.** `size`, `align` and `center` describe the
   body. Flares (negative modifiers) grow outside of it unless asked otherwise
   (see 3.4).
6. **Errors are explicit.** A modifier that does not fit (bevel wider than the
   wall, selector that matches nothing, ...) fails with an `assert` that says why.
7. Minimal supported OpenSCAD version is **2021.01**. Recent nightlies (Manifold)
   are welcome and make the remaining boolean operations cheap.

## 2. Terminology

| term          | meaning                                                                   |
|---------------|---------------------------------------------------------------------------|
| body          | the solid itself, without flares                                          |
| profile       | 2D half-section of a revolved solid in the (radius, axis) plane           |
| cross-section | 2D slice perpendicular to the `zet` axis (box family)                     |
| ring          | one cross-section at a given height; the box body is a stack of rings     |
| edge tag      | name of an edge of the solid, e.g. `"to"` = top outer edge                |
| flare         | material added by a negative modifier, blending an edge into a base plane |
| `across`      | modifier dimension measured in the base plane (radially for revolved)     |
| `along`       | modifier dimension measured along the `zet` axis                          |

## 3. Modifiers

### 3.1 Constructors

```openscad
bevel(d, where="all")           // chamfer
rounding(r, where="all")        // fillet / round-over
bevel_corners(d, where="all")   // plane cut of corners (cubepp only)
```

`rounding` is not called `round` on purpose: `round()` is an OpenSCAD built-in
function and shadowing it would break user code.

### 3.2 Value

| value            | `bevel`                                     | `rounding`                                |
|------------------|---------------------------------------------|-------------------------------------------|
| `v` (number)     | same as `[v, v]`                            | circle of radius `v`                      |
| `[across,along]` | legs projected to the base plane / the axis | ellipse with semi-axes `across`, `along`  |
| `[x, y, z]`      | `cubepp` only: extents along parent axes    | `cubepp` only: ellipse semi-axes per axis |
| positive         | removes material (chamfer, round-over)      | removes material                          |
| negative         | adds a flare into the base plane            | adds a concave fillet into the base plane |
| zero             | no-op                                       | no-op                                     |

All components must have the same sign and be all zero or all non-zero.

For `cubepp`, every edge takes the two components of the axes perpendicular to it:
`[across, along]` is `[across, across, along]` in the local frame (`along` is the
`zet` axis), `[x, y, z]` are the extents along the axes of the parent frame
(e.g. `rounding([1, 2, 3])` is the old ellipsoidal `round_corners(r=[1, 2, 3])`).

Bevel legs: of the two faces meeting at the edge, the one closer to horizontal
takes `across` (the leg measured as its projection to the base plane), the other
one takes `along` (projection to the axis). For a 90° edge this is the usual
chamfer; for a cone the legs stay `across`/`along` no matter the wall angle.

Rounding: the circle/ellipse is tangent to both adjacent faces, for any corner
angle (cones, previously bevelled edges, ...).

Negative values (flares) are only allowed on base edges, i.e. edges where one of
the adjacent faces lies in a base plane; the flare extends that plane. Used on a
cutter (a solid used in `difference()`), a negative bevel gives a countersink.

### 3.3 Selecting edges: `where`

`where` is a string or a list of strings (tokens). A token selects every edge
whose tag contains **all** letters of the token. `"all"` selects every edge.
Letters are case-sensitive.

Revolved solids (`cylinderpp`, `tubepp`):

| letter | meaning                                 |
|--------|-----------------------------------------|
| `t`    | top base (high end of the `zet` axis)   |
| `b`    | bottom base (low end of the `zet` axis) |
| `o`    | outer wall                              |
| `i`    | inner wall (hole of `tubepp`)           |

| token          | `cylinderpp`      | `tubepp`                            |
|----------------|-------------------|-------------------------------------|
| `"all"`        | `bo`, `to`        | `bi`, `bo`, `to`, `ti`              |
| `"t"` / `"b"`  | top / bottom edge | both edges of the top / bottom base |
| `"o"`          | both edges        | both outer edges                    |
| `"i"`          | error (no hole)   | both hole edges                     |
| `"ti"`, `"bo"` | single edge       | single edge (`"it"` works too)      |

Box family (`cubepp`): `x X y Y z Z` are the faces in the parent frame (lowercase
= low side, as in `align`), `t`/`b` are aliases of the top/bottom base, i.e. the
faces perpendicular to `zet` (with `zet="z"`, `t` is `Z`).

| token                    | edges                          | corners (`bevel_corners`) |
|--------------------------|--------------------------------|---------------------------|
| `"all"`                  | all 12                         | all 8                     |
| `"t"`, `"b"`             | 4 edges of the top/bottom base | 4 top/bottom corners      |
| `"X"`                    | 4 edges of the right face      | 4 right corners           |
| `"xY"`, `"tX"`           | that single edge               | 2 corners of that edge    |
| `"txY"`, `"xYZ"`         | error (matches nothing)        | that single corner        |
| `"x-edges"`, `"z-edges"` | 4 edges parallel to that axis  | error                     |

Every token must match at least one edge, otherwise it is an error.

### 3.4 Flares and the bounding box

| argument         | default | meaning                                                      |
|------------------|---------|--------------------------------------------------------------|
| `flare_in_align` | `false` | `true`: alignment uses the bounding box including flares     |
| `flare_in_size`  | `false` | `true`: the given diameter includes flares, the body shrinks |

Flares never change the extent along the `zet` axis (they lie in base planes).

### 3.5 Layering and order

An operation acts on the *sharp* corners of the selected edges:

- `bevel` replaces a sharp corner with two new sharp corners, so a following
  `rounding` on the same edge rounds both of them (bevel-then-round).
- `rounding` replaces a corner with a smooth arc; selecting an already rounded
  edge again is an error.
- A flare needs an untouched base edge.

`cubepp` adds a rule for edges parallel to `zet` ("vertical" edges) because they
are corners of the cross-section, see section 5.

## 4. Revolved family

### 4.1 How it is built

1. The solid builds its **material profile**: a closed polygon in the
   (radius, axis) plane whose vertices carry edge tags. Cylinder:
   `ba(0,-h/2) bo(R1,-h/2) to(R2,h/2) ta(0,h/2)` (`ba`/`ta` lie on the axis and
   cannot be selected). Tube: `bi bo to ti`.
2. Modifiers are applied in order; each replaces tagged corners by runs of new
   vertices (chamfer points, arc points, flare points).
3. Geometry:
   - `cylinderpp`: `rotate_extrude(polygon(profile))`.
   - `tubepp`: the profile is split into the **outer chain** (`bo`, `to` runs) and
     the **inner chain** (`ti`, `bi` runs). The tube is
     `difference(outer body, hole cutter)`, each made by its own
     `rotate_extrude`. That is what allows a different polygon for the outer
     wall and for the hole.

### 4.2 Polygonal walls

| argument (`cylinderpp`) | argument (`tubepp`)              | default     | meaning                                         |
|-------------------------|----------------------------------|-------------|-------------------------------------------------|
| `fn`                    | `outer_fn`, `inner_fn`           | `undef`     | number of sides; `undef` uses `$fn`/`$fa`/`$fs` |
| `polygon`               | `outer_polygon`, `inner_polygon` | `"corners"` | `"corners"`: vertices on the circle (OpenSCAD)  |
|                         |                                  |             | `"flats"`: flats on the circle (nut traps)      |

`fn` only sets the number of sides of the revolution. Arcs of `rounding` keep
using `$fn`/`$fa`/`$fs`, so an octagonal standoff still gets smooth fillets.
With `"flats"` the whole profile is measured at the flats, i.e.
`inner_fn=6, inner_polygon="flats", d=5.5` is an M3 nut trap.

### 4.3 Arguments

`cylinderpp(size, r|d, h, r1|d1, r2|d2, align, zet, center, mod_list, fn, polygon,
flare_in_align, flare_in_size)`

- `size`: number or `[d, d, h]` in the parent frame (respects `zet`). The two
  base dimensions must be equal: **elliptical cylinders are not supported**.
  Exclusive with `r|d` and `h`; can be combined with `r1|d1, r2|d2`, in which case
  the larger base is scaled to `size`.
- `r|d`: number, or `[bottom, top]`.
- `r1|d1`, `r2|d2`: per-base radius/diameter; both bases must be defined.
- default: `d=1, h=1`, `align="z"`.

`tubepp(size, t, r|d, R|D, h, align, zet, center, mod_list, outer_fn, inner_fn,
outer_polygon, inner_polygon, flare_in_align, flare_in_size)`

- exactly two of `t`, `r|d` (hole), `R|D` (outer) are required; `size` counts
  as `R|D` plus `h`. Each can be a number or `[bottom, top]`.
- default: `r=0.5, R=1, h=1`, `align="z"`.

### 4.4 Planned

- `revolvepp(profile, ...)`: user profile (point list), same modifiers if tags are
  supplied; replaces the old `children()` profile of `cylinderpp`.
- `projectpp(plane=[point, normal])`: moves the plane to z=0 and runs
  `projection(cut=true)`.
- `sector(angle)` modifier for revolved solids (just `rotate_extrude(angle=)`).

## 5. Box family (`cubepp`)

### 5.1 How it is built

The box is built centered in a local frame whose third axis is `zet` and then
rotated; selectors and `[x, y, z]` values are mapped from the parent frame.

1. Every modifier is split into its vertical-edge part (edges parallel to `zet`)
   and its base-edge part, in this order. The parts go to stages:

| stage | what                               | effect                                                |
|-------|------------------------------------|-------------------------------------------------------|
| A     | vertical part before any base part | rounds/chamfers the corners of the cross-section      |
| B     | base parts                         | profile of every side face (same engine as cylinders) |
| C     | vertical part after a base part    | straight cut through the whole height                 |
| D     | `bevel_corners`                    | plane cuts of the corners, applied last               |

   A base part after a stage C cut is an error (reorder `mod_list`).
2. The profile of a side face (stage B) gives its inset at every height
   (negative = flare). The heights of all profile points are the **ring levels**.
3. A ring is the cross-section (stage A) with every edge shifted inward by the
   inset of its side, then clipped by the stage C cuts. Edges between two sides
   (arcs, chamfers) take a blend of both insets, weighted by the squared
   components of their normal; equal insets give an exact concentric offset.
   Outward offsets (flares) are mitered at sharp corners and follow the arcs of
   rounded vertical edges.
4. Geometry: without flares the body is convex and is a single `hull()` of all
   rings; with flares it is a union of hulls of adjacent rings. Stage D subtracts
   one tetrahedron per corner. A box without modifiers is a plain `cube()`.

Consequences:

- `rounding(r)` (all edges) gives spherical corners, the same solid as the old
  `round_corners` (Minkowski sum with a sphere).
- `[bevel(1, "z-edges"), rounding(2, "t")]`: the round-over follows the chamfered
  corners (swept). `[rounding(2, "t"), bevel(1, "z-edges")]`: the chamfer is a
  straight cut through the rounded top.
- `[rounding(2, "z-edges"), rounding(-2, "b")]`: a fillet foot that follows the
  rounded corners.

### 5.2 Limitations

- Rings must be convex. A non-convex ring (future `prismpp` with an L-shaped base,
  negative rounding of a vertical edge) needs stitching of rings into a
  `polyhedron`; out of scope.
- A stage C cut after a flare also cuts the flare near that corner.
- Different base modifiers on two neighbouring sides meet in a blended corner when
  the vertical edge between them is rounded or chamfered (point 3 above).
- `rounding([x, y, z])` with different values is a swept ellipse, very close to,
  but not exactly, an ellipsoid at the corners.

### 5.3 Arguments

`cubepp(size, align, zet, center, mod_list, flare_in_align, flare_in_size)`

- `zet` (default `"z"`) selects the base axis of the modifiers.
- With `flare_in_size`, each side shrinks by its own flare, so the box may be
  off-center in its bounding box; alignment always uses the chosen bounding box.

## 6. Dropped / changed

| old                                        | new                                         |
|--------------------------------------------|---------------------------------------------|
| elliptical `cylinderpp([a,b,h])`, `a != b` | error                                       |
| `cylinderpp` resized unit cylinder         | `rotate_extrude` of the real profile        |
| `cylinderpp` `children()` profile          | `revolvepp` (planned)                       |
| `round_bases`, `bevel_bases` (cyl/tube)    | `rounding(r, "t"/"b")`, `bevel(d, "t"/"b")` |
| `round_corners` (cyl/tube)                 | `rounding(r)` (`where="all"`)               |
| `r_both`, `rounding_r`, `__mod_queue`, ... | removed                                     |
| `inner_mod_list`, `outer_mod_list` (tube)  | `where` with `i` / `o`                      |
| `bevel <= 0` silently ignored              | negative = flare, zero = no-op              |
| first modifier applied last                | reading order                               |
| `cubepp` `zet` ignored                     | base axis of the modifiers                  |
| `bevel_bases(axis=)` on `cubepp`           | selectors of faces, or `zet`                |

### 6.1 Old modifiers (backward compatibility)

The old constructors keep their signatures and still work. They return a legacy
record that the solid translates to the new modifiers, printing an echo such as

```
ECHO: "[CUBEPP] DEPRECATED: round_edges(r=2, axes="xy") -> use rounding(2, "z-edges")"
```

| old                                       | `cubepp`                                  | `cylinderpp`, `tubepp`      |
|-------------------------------------------|-------------------------------------------|-----------------------------|
| `round_corners(r)`                        | `rounding(r)`                             | `rounding(r)`               |
| `round_edges(r, axes="xy")`               | `rounding(r, "z-edges")`                  | error                       |
| `round_edges(r, axes="x")`                | `rounding(r, ["x", "X"])`                 | error                       |
| `bevel_edges(b, axes="xyz")`              | `bevel(b)`                                | error                       |
| `bevel_bases(b, axis="z")`                | `bevel(b, ["z", "Z"])`                    | `bevel(b, ["b", "t"])`      |
| `round_bases(r_bottom=r)`                 | `rounding(r, "z")`                        | `rounding(r, "b")`          |
| `bevel_corners(bevel=b)`                  | `bevel_corners(b)` (argument renamed `d`) | error                       |
| `tubepp(inner_mod_list=[bevel_bases(b)])` | -                                         | `bevel(-b, ["bi", "ti"])`   |
| `tubepp(outer_mod_list=[m])`              | -                                         | `m` restricted to `o` edges |

- A `mod_list` made only of old modifiers is reversed (old modifiers were applied
  from the last to the first); a mixed list keeps reading order.
- Old 2D values `[a, h]` of `*_bases` become `[x, y, z]` along `axis`; old 3D values
  of `cylinderpp` become `[x, z]`.
- Non-positive old bevels (silently ignored before) are skipped with an echo.
- `inner_mod_list` modified the cylinder cut out of the tube, so its modifiers
  become negative modifiers (flares into the hole) of the inner edges.

## 7. Implementation notes

- Files:

| file                              | content                                                  |
|-----------------------------------|----------------------------------------------------------|
| `modifiers/edge_modifiers.scad`   | `bevel()`, `rounding()`, `bevel_corners()`, validation   |
| `modifiers/legacy_modifiers.scad` | old constructors, translation, `mod_list` resolution     |
| `engine/profile.scad`             | tagged polygons, corner operations, fragments, checks    |
| `engine/revolved.scad`            | cylinder/tube profiles, chain split, argument parsing    |
| `engine/box.scad`                 | frames, selectors, stages, rings, offsets, hull geometry |
| `cubepp.scad`                     | thin module over the engine                              |
| `cylinderpp.scad`                 | thin module over the engine                              |
| `other_solidspp/tubepp.scad`      | thin module over the engine                              |
| `tests/test_revolved.scad`        | `assert`-based tests of the data layer (no geometry)     |
| `tests/test_cubepp.scad`          | `assert`-based tests of the box data and legacy layer    |
| `tests/gallery_revolved.scad`     | visual smoke test of all combinations                    |
| `tests/gallery_cubepp.scad`       | visual smoke test of all combinations                    |

- Vertex format: `[x, y, tag, sharp]`. `sharp=false` marks arc points.
- Modifier format: `["__SPP_EDGE_MOD__", kind, value, [tokens]]`,
  `["__SPP_CORNER_MOD__", "bevel_corners", [x, y, z], [tokens]]`,
  `["__SPP_LEGACY_MOD__", name, data, call description]`.
- Box rings are hulled from a `polyhedron` with one face per ring (only its
  points matter to `hull()`).
- Corner fit check: on every profile edge, the legs taken by the corners at both
  ends must not exceed the edge length; points must stay at `x >= 0`.
- Modules contain no logic beyond calling the data functions and emitting
  geometry, so almost everything is testable with plain `assert`s.

## 8. Open items / roadmap

- [ ] Check in OpenSCAD: phase of `rotate_extrude` vs `cylinder()` for odd `fn`
      (a full-revolution `rotate_extrude` may start at 180°, `cylinder()`
      starts at 0°; irrelevant for even `fn` such as hex nuts).
- [x] Port `cubepp` to rings (section 5) and remove the old modifier internals.
- [ ] Check render times of `cubepp` with fine `$fa`/`$fs` (function evaluation
      of the rings) on 2021.01 and on a nightly.
- [ ] `revolvepp`, `projectpp`, `sector`.
- [ ] `spherepp` and `circlepp` still use `resize` of a unit primitive
      (resolution does not scale with size).
- [ ] Update README for the new modifiers.
- [ ] Separate task: review `transforms/`.
