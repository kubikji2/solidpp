# Solid++ design: modifiers and the profile engine

Status: agreed design for the modifier refactor. Implemented: the engine,
`bevel()`/`rounding()`/`bevel_corners()`, `cylinderpp`, `tubepp`, `cubepp`, the
translation of the old modifiers and the sections `teardrop()`/`serration()`
(see Roadmap for the rest).

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

`where` is a string or a list of strings (tokens). One rule for all solids:

> Faces have names. An edge is named by its two faces, a corner by its three.
> A token selects every element whose faces include all faces of the token.

- A face name is a letter optionally followed by digits: `t`, `o`, `g`, `g12`.
- A token is a concatenation of face names: `"to"`, `"ti"`, `"xY"`, `"og1"`.
- A bare letter matches its whole family: `"g"` matches `g`, `g1`, `g2`, ...;
  a numbered name matches only itself (`"g1"` does not match `g2` or `g`).
- The order of the names in a token does not matter (`"it"` = `"ti"`).
- `"all"` selects every edge; letters are case-sensitive.
- Every token must match at least one edge, otherwise it is an error.
- `t`/`b` are the faces perpendicular to `zet` (top/bottom) on every solid.
- Vertices that are not edges (on the axis, collinear points) cannot be selected.

Revolved solids (`cylinderpp`, `tubepp`, `revolvepp`):

| letter | meaning                                 |
|--------|-----------------------------------------|
| `t`    | top base (high end of the `zet` axis)   |
| `b`    | bottom base (low end of the `zet` axis) |
| `o`    | outer wall                              |
| `i`    | inner wall (hole of `tubepp`)           |

`revolvepp` derives these names from the profile and adds the names of user tags,
see section 4.6.

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

`prismpp`: faces `t`, `b` and sides `s0`, `s1`, ... (plus tag names), e.g.
`"s"` all sides, `"ts2"` one top edge, `"s1s2"` one vertical edge, see section 5.4.

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
- On a concave edge (only in `revolvepp` profiles), `bevel` and `rounding` with a
  positive value fill the corner (add material); a flare (negative value) is an
  error there.
- A broad token also matches refined edges: with a top face tagged `"t1"`,
  `rounding(r, "to")` rounds that edge too. Put the specific modifier first
  (a bevel can still be rounded) or use specific tokens.

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
|                         |                                  |             | `"polyhole"`: flats on the circle, sides chosen |
|                         |                                  |             | automatically (nophead's polyholes)             |

`fn` only sets the number of sides of the revolution. Arcs of `rounding` keep
using `$fn`/`$fa`/`$fs`, so an octagonal standoff still gets smooth fillets.
With `"flats"` the whole profile is measured at the flats, i.e.
`inner_fn=6, inner_polygon="flats", d=5.5` is an M3 nut trap.

`"polyhole"` is `"flats"` with max(round(2*d), 3) sides, `d` being the nominal
diameter of the wall in mm (the larger base of a cone, the hole itself rather
than its chamfered end). Few, long flats are printed faithfully and touch the
nominal circle, so small printed holes keep their size. The number of sides is
chosen automatically, setting `fn` of that wall is an error; it works with
`serration()`, not with `teardrop()` (as `"flats"`). Unlike nophead's module the
polygon is not rotated by 180 degrees (it only changes the phase of odd counts).

### 4.3 Arguments

`cylinderpp(size, r|d, h, r1|d1, r2|d2, align, zet, center, mod_list, fn, polygon,
flare_in_align, flare_in_size, section)`

- `size`: number or `[d, d, h]` in the parent frame (respects `zet`). The two
  base dimensions must be equal: **elliptical cylinders are not supported**.
  Exclusive with `r|d` and `h`; can be combined with `r1|d1, r2|d2`, in which case
  the larger base is scaled to `size`.
- `r|d`: number, or `[bottom, top]`.
- `r1|d1`, `r2|d2`: per-base radius/diameter; both bases must be defined.
- default: `d=1, h=1`, `align="z"`.

`tubepp(size, t, r|d, R|D, h, align, zet, center, mod_list, outer_fn, inner_fn,
outer_polygon, inner_polygon, flare_in_align, flare_in_size, outer_section,
inner_section)`

- exactly two of `t`, `r|d` (hole), `R|D` (outer) are required; `size` counts
  as `R|D` plus `h`. Each can be a number or `[bottom, top]`.
- default: `r=0.5, R=1, h=1`, `align="z"`.

### 4.4 Sections: `teardrop()`, `serration()`

A section is the shape of a wall perpendicular to `zet`: `section` of `cylinderpp`,
`outer_section` and `inner_section` of `tubepp`. It is a separate argument, not a
modifier: every wall has exactly one, and it combines with `mod_list`.

```openscad
section=teardrop()                                     // base shape
section=serration(12, 0.4, "round")                    // circle with grooves
section=[teardrop(cap="bridge"), serration(12, 0.4)]   // base shape, then decoration
```

- At most one base shape (the circle by default, or `teardrop()`), optionally
  followed by `serration()`; anything else is an error.
- The bounding box (alignment, `size`) is always the one of the circle.

`teardrop(up, angle=45, cap="point")`

| argument | meaning                                                                        |
|----------|--------------------------------------------------------------------------------|
| `up`     | face letter the tip points to (`x X y Y z Z`, lowercase = low side), must be   |
|          | perpendicular to `zet`; default `"Z"` for `zet="x"`/`"y"`, `"x"` for `zet="z"` |
| `angle`  | angle of the tip faces from the horizontal (printing overhang), in (0, 90)     |
| `cap`    | `"point"`: classic teardrop; `"bridge"`: tip cut flat at the top of the circle |
|          | (the hole stays within its diameter, the flat is a short bridge)               |

`serration(n, depth, profile="triangle", width)`

| argument  | meaning                                                                   |
|-----------|---------------------------------------------------------------------------|
| `n`       | number of grooves along the axis                                          |
| `depth`   | depth of the grooves                                                      |
| `profile` | `"triangle"`: zig-zag of tips and roots (knurl); `"round"`: round grooves |
| `width`   | width of a round groove, default `2*depth` (a half circle)                |

- Serration removes material from the shape; `d` is measured at the tips. On a
  solid this gives grip (knurl), on a hole cut-out it leaves ribs in the hole
  (crush ribs for press fits, heat inserts).
- On a circle the grooves are evenly spaced along the whole perimeter. On a
  teardrop they are spread over the circular part only (between the tangent
  points, around the bottom): the tip faces and the cap do not touch the rod, and
  grooves there would spoil the printable overhang, so they stay plain.
- Serration runs only along the straight part of the wall. Modifiers of the bases
  set where it starts and ends; the modified ends (chamfers, roundings, flares)
  stay plain. On a hole this leaves a rib-free lead-in chamfer. If the modifiers
  leave no straight part, it is an error.
- The polygon modes (`polygon`, `outer_polygon`, `inner_polygon`) describe the
  circle; with `teardrop()` only `"corners"` is allowed. `fn` is the number of
  fragments of the circle in both cases.

How a wall with a section is built (`engine/section.scad`):

1. The nominal outline O at the nominal radius R (circle polygon or teardrop).
2. The wall chain from the modified profile, bottom to top: every point
   `[x, z]` gives a ring, O offset inward by `R - x`. For circles and teardrops
   this offset is exact (a teardrop offset is the teardrop of the smaller radius),
   so bevels and roundings follow the teardrop and cones work.
3. Without serration the rings are hulled (one hull for the convex part, pairs of
   rings where the outline leaves the original wall line, i.e. flares or widened
   hole ends; on a cone this is checked against the slanted line).
4. With serration the straight part is one stitched `polyhedron` between the
   serrated rings at its ends (the serration plan is computed once on O, so every
   ring has the same points); the ends are hulled rings; the pieces are united.
5. Beyond an unmodified end, the hole cut-out continues the wall line (straight
   part and conical holes stay exact); the protrusion is short.

A wall without a section keeps the `rotate_extrude` path.

### 4.5 Sector

`sector` is an argument of `cylinderpp` and `tubepp` (not a modifier: a solid has one
angular range).

- `sector=90` sweeps from 0 to 90 degrees, `sector=[-45, 45]` from -45 to 45;
  `0 < to - from <= 360`, a full turn is the plain solid.
- Angles follow the right-hand rule around `zet` and start at the next axis of
  the cycle x -> y -> z: +x for `zet="z"` (towards +y), +y for `zet="x"` (towards
  +z), +z for `zet="y"` (towards +x).
- The bounding box (alignment) is the one of the full cylinder/tube.
- `tubepp` cuts only the outer body (a C-shape); the hole stays a full
  revolution, so `inner_section` works.
- Built by `rotate_extrude(angle=)`; not combinable with a non-circular `section`
  or `outer_section` (those walls are not revolved). The flat end faces of the
  sector cannot be modified by `mod_list`.

### 4.6 `revolvepp`

```
revolvepp(points, align, zet, center, mod_list, fn, polygon, flare_in_align, sector)
```

The user draws the profile as a point list (x = distance from the axis, y =
position along `zet`), so the bounding box, alignment, validation and modifiers
work as for `cylinderpp`. A 2D child cannot be measured in OpenSCAD; revolving
2D children is left to a transform (`rotate_extrudepp`, planned).

Points: `[x, y]`, `[x, y, "tag"]` or `[x, y, "tag", "f"]`.

- The profile is closed, must not intersect itself and must lie in `x >= 0`;
  it may touch the axis only along segments (a single point on the axis would
  pinch the solid);
  its orientation does not matter (it is normalized to counter-clockwise).
- The segment from point `k` to point `k+1` is a face of the solid. A vertex is
  an edge named by the faces on both sides.
- Every segment gets an automatic name from its outward normal:

| segment                              | name      |
|--------------------------------------|-----------|
| on the axis (`x = 0` at both ends)   | none      |
| horizontal, facing up / down         | `t` / `b` |
| otherwise facing away from / to axis | `o` / `i` |

- A tag adds names to the segment starting at its point (several names may be
  concatenated, e.g. `"gh"`). Tags never remove the automatic name.
- Tag rules:

| tag                                                                         | result             |
|-----------------------------------------------------------------------------|--------------------|
| new letter, e.g. `"g"`, `"g1"`                                              | added              |
| default letter of the segment's own group, e.g. `"t"`, `"t1"` on a `t` face | added (refinement) |
| default letter of another group, e.g. `"t"` on an `o` face                  | error              |
| the same with the flag: `[x, y, "t", "f"]`                                  | added (forced)     |
| flag `"f"` without such a letter                                            | error              |
| letters `x X y Y z Z`                                                       | error (reserved)   |
| tag on a segment on the axis                                                | error (not a face) |

  A forced name is meant for faces that are not exactly horizontal/vertical but
  should be treated as such (a slanted printable shoulder joins `t`).
- Edge tags are canonical: default names in the order `t b o i`, then the others
  (`"to"`, `"tot1"`, `"og"`).
- Placement is by `align` as for `cylinderpp` (default `"z"`), the y offset of
  the points is dropped. `align="keep"` places the points as given (axis through
  the origin, y along `+zet`); `center=true` still overrides it. `polygon` modes are measured at the largest
  radius. Sections (`teardrop`, `serration`) are not supported (a general
  profile has no monotonic wall). Old modifiers are not supported.

### 4.7 `toruspp`

```
toruspp(t, r|d, R|D, h, align, zet, center, fn, polygon, sector)
```

Unchanged arguments and defaults (exactly two of `t`, `r|d`, `R|D`, default
`r=0.5, R=1`; `h` defaults to `t`; `align=""`, centered). The tube is an ellipse
`t x h` built like `circlepp` (vertices on the ellipse, fragments by
`$fn/$fa/$fs`) and revolved by the shared engine, so `fn` (sides of the
revolution), `polygon` (`"corners"`, `"flats"`) and `sector` work as for
`cylinderpp`. `r` must be positive: with `r = 0` the tube touches the axis in a
single point (a pinch, not a valid solid; CGAL reports "mesh is not closed").
A torus has no edges, so there is no `mod_list`.

### 4.8 Planned

- `rotate_extrudepp(zet, sector, fn)` in `transforms/`: 2D children, `zet` and
  the `sector` convention; alignment via `transform_to_spp`.
- `projectpp(plane=[point, normal])`: moves the plane to z=0 and runs
  `projection(cut=true)`.

## 5. Box family (`cubepp`, `prismpp`) and Platonic solids

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

`cubepp(size, align, zet, center, mod_list, flare_in_align, flare_in_size, size_bottom,
size_top)`

- `zet` (default `"z"`) selects the base axis of the modifiers.
- Taper (frustum) along `zet`: `size` gives the height and one base, `size_top`
  or `size_bottom` (only one of them) the other base. The base is `[a, b]` along
  the two parent axes perpendicular to `zet` in the order x, y, z, or a number for
  a square base:

| `zet` | base `[a, b]` | example                                          |
|-------|---------------|--------------------------------------------------|
| `"z"` | `[x, y]`      | `cubepp([20, 10, 6], size_top=[10, 10])`         |
| `"x"` | `[y, z]`      | `cubepp([6, 20, 10], size_top=[10, 4], zet="x")` |
| `"y"` | `[x, z]`      | `cubepp([20, 6, 10], size_bottom=8, zet="y")`    |

  Both bases at once, or a base without `size`, is an error.
  The bounding box (alignment) is the one of the larger base. The top stays
  centered over the bottom; use transforms for anything else.
- A taper is a slanted side profile, so base modifiers behave as on cones; the
  cross-section is built on the larger base and offset, i.e. rounded vertical
  edges get a smaller radius towards the smaller base (as a drafted extrusion).
  Stage C cuts stay parallel to `zet`; `bevel_corners` cuts along the slanted
  edges. A flare is detected against the slanted wall, not the larger base.
- With `flare_in_size`, each side shrinks by its own flare, so the box may be
  off-center in its bounding box; alignment always uses the chosen bounding box.

### 5.4 `prismpp`

```
prismpp(points, h, align, zet, center, mod_list, flare_in_align, scale, scale_center, draft)
```

A right prism over a strictly convex base, built by the box engine generalized
to n sides (`engine/prism.scad`).

- `points`: `[x, y]` or `[x, y, "tag"]`, drawn as for `zet="z"`; the solid is
  then turned like every solidpp solid (`zet="x"`: `rotate([0, 90, 0])`,
  `zet="y"`: `rotate([-90, 0, 0])`). Any orientation; collinear points, concave
  or self-intersecting bases are errors.
- `h`: height along `zet` (default 1).
- `align`: default `"keep"` (the points as given, base on the plane 0, top at
  `h`, as `linear_extrude`); any other value aligns the bounding box of the base
  polygon as for `cubepp`; `center=true` overrides both.
- No `size`, no `flare_in_size`, no `bevel_corners`, no `[x, y, z]` values (the
  sides are not axis-aligned). Old modifiers are not supported.
- Edges between the sides take a single number: the legs are measured along the
  sides (circular rounding), `[across, along]` applies to base edges only.

Taper (at most one of `scale` and `draft`; every side stays a flat face):

| argument              | top                                                                                          |
|-----------------------|----------------------------------------------------------------------------------------------|
| `scale=s`             | the base scaled by `s > 0` (same shape); `s > 1`: larger top (overhang)                      |
| `scale_center=[x, y]` | centre of the scaling (default: the centroid of the base); off-centre gives an oblique prism |
| `draft=α`             | every side leans inwards by `α` (outwards if negative), `-90 < α < 90`                       |
| `draft=[α0, α1, ...]` | one angle per side, in the user's order (`0` keeps a side vertical)                          |

- A non-uniform scale (as in `linear_extrude(scale=[sx, sy])`) would twist the
  sides, so it is an error. `scale=0` (a pyramid) is not supported by the ring
  engine (a later `pyramidpp`).
- A draft keeps the wall angle, not the shape: on an irregular base a strong
  draft can make a side of the top vanish, which is an error.
- As for `cubepp`: the side profiles are slanted (bottom and top distance of
  every side), the cross-section is built on the larger base of every side,
  straight cuts (stage C) are vertical, flares are detected against the slanted
  wall (a flare of radius `r` reaches `r/tan(φ/2)` along the base, φ the open
  angle between the base plane and the wall), the edges between the sides stay
  `"<zet>-edges"`. The bounding box includes the top.
- The side profiles measure the distance of each side from the centroid of the
  base; a side of an oblique taper may pass beyond it, its profile is then
  shifted (the corner operations do not depend on the origin).

Faces and edges:

| face                           | name                 |
|--------------------------------|----------------------|
| bases                          | `t`, `b`             |
| side from point k to point k+1 | `s<k>` (+ tag names) |

| token                                 | edges                               |
|---------------------------------------|-------------------------------------|
| `"all"`, `"s"`                        | all edges                           |
| `"t"`, `"b"`                          | edges of the top/bottom base        |
| `"s2"`                                | the 4 edges of side 2               |
| `"ts2"`                               | top edge of side 2                  |
| `"s1s2"`                              | vertical edge between sides 1 and 2 |
| `"g"` (tag on point k)                | the 4 edges of side k               |
| `"x-edges"`, `"y-edges"`, `"z-edges"` | edges parallel to that parent axis  |

- Side numbers follow the user's points also for clockwise input.
- Tags: a letter optionally followed by digits; `t b s x X y Y z Z` are
  reserved (no forcing: a prism has no slanted faces to classify).
- Stages A-C as for `cubepp` (vertical edges before base edges are swept, after
  them cut straight). At a modified vertical edge between sides k-1 and k, the
  ring is offset by a blend of the two side insets with the weights
  `sin²θ / (sin²θ + sin²(φ-θ))` (θ angle of the edge normal from side k-1, φ angle
  of the corner); for a right angle this is the `cos²`/`sin²` blend of `cubepp`,
  and equal insets give an exact offset.
- Flares are mitered at the vertices (as `cubepp`); with `flare_in_align` the
  bounding box includes them exactly.
- The old `prism(points, h, n)` (oblique prism by a normal) is deprecated, see 7.1.

### 5.5 `platonicpp` (dice)

```
platonicpp(n, a|d|D, align, zet, center, mod_list)
tetrahedronpp(...), hexahedronpp(...), octahedronpp(...), dodecahedronpp(...), icosahedronpp(...)
platonicpp_faces(n, a|d|D, align, zet, center, idx, numbering) children
platonicpp_vertices(n, a|d|D, align, zet, center, idx) children
```

The five Platonic solids (`n` = 4, 6, 8, 12, 20 faces), the wrappers fix `n`.

| size | meaning                                                                                                               |
|------|-----------------------------------------------------------------------------------------------------------------------|
| `a`  | edge length (default 1)                                                                                               |
| `d`  | diameter of the inscribed sphere (dice size: distance between opposite faces; for the tetrahedron half of its height) |
| `D`  | diameter of the circumscribed sphere (through the vertices)                                                           |

- Placement: one face down (outward normal `-zet`), one edge of that face
  parallel to x (for `zet="z"`), then turned by `zet` like every solidpp solid.
  `align` uses the bounding box of the nominal solid, default `"z"` (centered in
  x/y, on z = 0); `center=true` centers the bounding box (for the tetrahedron and
  the dodecahedron it is not the center of the solid).
- Engine (`engine/platonic.scad`): generated from vertex coordinates; the faces
  are the vertices with the largest dot product with the face normals (the
  vertex directions of the dual solid), so no face lists are written by hand.

Modifiers (all edges/corners are equivalent: `where="all"` only, single
positive numbers, each kind at most once, `rounding` last):

| modifier           | meaning                                                     | construction                                                                  |
|--------------------|-------------------------------------------------------------|-------------------------------------------------------------------------------|
| `bevel(d)`         | chamfer, leg `d` along both faces                           | intersection with the body of the edge planes                                 |
| `bevel_corners(d)` | corner cut at `d` along the edges (`a/2`: the edges vanish) | intersection with the body of the vertex planes (dual solid)                  |
| `rounding(r)`      | rounds every edge (also of the cuts)                        | solid shrunk by `r`, Minkowski with a sphere (only rounding: hull of spheres) |

- Each body of planes is a convex polyhedron with known vertices (the solid, the
  dual, the rhombic solid of the edges), the cut solid is their `intersection()`.
- All modifiers keep the face planes, so the alignment and the face helper do
  not depend on `mod_list`.
- Limits: `bevel` smaller than the face apothem, `bevel_corners` at most `a/2`,
  `rounding` smaller than the inscribed sphere after the cuts.

Face and vertex helpers (same size and placement arguments, so they always
match the solid):

- The children are placed in the frame of each face (origin in its center, z
  outward, y towards the up axis, x for the top/bottom faces, so `text()` reads
  from outside) or of each vertex (origin in the vertex, z from the center out).
- `idx`: undef (all), a number or a list of numbers.
- Special variables in the children: `$face`, `$face_vertices` (numbers of the
  corners, counter-clockwise), `$face_corners` (their 2D positions in the face
  frame), `$vertex`. They exist only inside the children.

| `numbering`            | order of `$face`                                                                                                                                    |
|------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------|
| `"opposite"` (default) | face `k` opposite to face `n-1-k` (labels `k+1`: opposite faces add up to `n+1`); tetrahedron: geometric order                                      |
| `"sequential"`         | consecutive faces share an edge, the last face is adjacent to the first (spindown dice, life counters); depth-first search with the Warnsdorff rule |

- Both orders start with the top face. Vertices are numbered from the top down,
  then counter-clockwise from +x.
- A d4 is labelled at the corners: on every face, `$face_vertices[k] + 1` near
  `$face_corners[k]` (see the gallery).

## 6. 2D shapes

```
squarepp(size, align, center, mod_list, flare_in_align)
polygonpp(points, align, center, mod_list, flare_in_align)
circlepp(size|r|d, align, center, fn, polygon, sector, section)
ringpp(t, r|d, R|D, align, center, outer_fn, inner_fn, outer_polygon, inner_polygon,
       sector, outer_section, inner_section)
```

### 6.1 Corner modifiers (`squarepp`, `polygonpp`)

`bevel()` and `rounding()` work on the corners of the outline, in reading order,
with the same rules as for solids (rounding is final, a bevel can be rounded).
A corner is named by its two sides:

| shape       | sides                                   | corners                        | values                                                     |
|-------------|-----------------------------------------|--------------------------------|------------------------------------------------------------|
| `squarepp`  | `y`, `X`, `Y`, `x` (bottom, right, ...) | `"xy"`, `"Xy"`, `"XY"`, `"xY"` | number or `[dx, dy]` (legs along x/y, elliptical rounding) |
| `polygonpp` | `s0`, `s1`, ... + tag names             | `"s0s1"`, ...                  | single number (legs along the sides, circular rounding)    |

- Positive values: a token selects the corners whose sides include all its
  names (order does not matter): `"x"` both corners of side x, `"xY"` one
  corner, `"all"` all corners. Concave corners (`polygonpp`) are filled.
- Negative values (flares): the **first name of a token is the base side**, it
  is extended beyond the corner and the flare fills the angle to the other side;
  the other names select which of its two corners:

| token (negative) | base side  | flared corners                |
|------------------|------------|-------------------------------|
| `"y"`            | the side y | both corners of y             |
| `"yX"`           | the side y | the corner of y shared with X |
| `"Xy"`           | the side X | the corner of X shared with y |
| `"s0"`, `"s0s1"` | side s0    | both / the one shared with s1 |
| `"all"`, `"s"`   | error      | (no single base side)         |

  A corner flared from both of its sides (e.g. `["y", "x"]`) is an error, a
  flare needs a convex corner.
- `flare_in_align` aligns the outline with the flares, otherwise the nominal
  rectangle/polygon.
- `polygonpp`: concave outlines allowed, must not intersect itself, any
  orientation (side numbers follow the user's points), tags as in `prismpp`
  (`t b s x X y Y z Z` reserved), points collinear with their neighbours are not
  corners. Default `align="keep"` (the points as given).
- `squarepp` keeps `align="xy"` (as `square()`); without modifiers it is a plain
  `square()`.

### 6.2 Circles (`circlepp`, `ringpp`)

- `fn`, `polygon` (`"corners"`, `"flats"`, `"polyhole"`), `sector` and `section`
  (`teardrop()`, `serration()`) as for `cylinderpp`; the 2D teardrop takes `up`
  from `"x"`, `"X"`, `"y"`, `"Y"` (default `"Y"`: the tip points to +y).
- `polygon` modes other than `"corners"`, `sector` and `section` work for
  circles only, not for ellipses; `sector` and `section` cannot be combined.
- Alignment uses the bounding box of the full circle.
- `ringpp` is the 2D `tubepp`: exactly two of `t`, `r|d`, `R|D` (default
  `r=0.5, R=1`), separate `fn`/`polygon`/`section` for the outer and inner
  circle, `sector` cuts the ring; the hole (with its polygon mode and section)
  must stay inside the outer outline.

### 6.3 Engine

- `engine/shape2d.scad`: outline validation, side names, selection with the
  base-side rule; the corner operations are those of `engine/profile.scad`.
- The corner engine has two metrics: `"projected"` (legs measured along x/y,
  for revolved profiles, boxes and `squarepp`) and `"along"` (legs measured along
  the sides, circular roundings, for `polygonpp` and the vertical edges of
  `prismpp`). Flares can name their base side explicitly.

## 7. Dropped / changed

| old                                         | new                                           |
|---------------------------------------------|-----------------------------------------------|
| elliptical `cylinderpp([a,b,h])`, `a != b`  | error                                         |
| `cylinderpp` resized unit cylinder          | `rotate_extrude` of the real profile          |
| `cylinderpp` `children()` profile           | `revolvepp`                                   |
| `round_bases`, `bevel_bases` (cyl/tube)     | `rounding(r, "t"/"b")`, `bevel(d, "t"/"b")`   |
| `round_corners` (cyl/tube)                  | `rounding(r)` (`where="all"`)                 |
| `r_both`, `rounding_r`, `__mod_queue`, ...  | removed                                       |
| `inner_mod_list`, `outer_mod_list` (tube)   | `where` with `i` / `o`                        |
| `bevel <= 0` silently ignored               | negative = flare, zero = no-op                |
| first modifier applied last                 | reading order                                 |
| `cubepp` `zet` ignored                      | base axis of the modifiers                    |
| `bevel_bases(axis=)` on `cubepp`            | selectors of faces, or `zet`                  |
| `trapezoid(base, top, h)`                   | `cubepp(size, size_top)` (deprecated wrapper) |
| `prism(points, h)`, `prism(points3D, n)`    | `prismpp` / `linear_extrude` (deprecated)     |
| `toruspp` via `circlepp` + `rotate_extrude` | revolved engine (`fn`, `polygon`, `sector`)   |
| `tetrahedron(points)`                       | removed (`platonicpp(4)` for a regular one)   |

### 7.1 Old modifiers (backward compatibility)

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
- `trapezoid(base=[a, b], top=[a, b], h)` becomes `cubepp(size=[...], size_top=[a', b'])`
  with the same geometry (`[a, b]` along the local x/y of the `zet` frame); with
  `zet="x"` and `a != b` the old alignment box did not match the geometry, the
  translation uses the geometry. A zero-size top (apex) is no longer supported.
- `prism(points, h|n)` still builds its polyhedron (the 2D path, which produced
  nothing before, is fixed) and echoes the replacement: `prismpp(points, h)` for a
  convex base, `linear_extrude(height=h) polygon(points)` for a concave one,
  `translate([0, 0, z]) multmatrix(shear) linear_extrude(...)` for an oblique prism
  with a horizontal base; other 3D bases have no direct replacement (`hull()`).

## 8. Implementation notes

- Files:

| file                               | content                                                  |
|------------------------------------|----------------------------------------------------------|
| `modifiers/edge_modifiers.scad`    | `bevel()`, `rounding()`, `bevel_corners()`, validation   |
| `modifiers/legacy_modifiers.scad`  | old constructors, translation, `mod_list` resolution     |
| `modifiers/section_modifiers.scad` | `teardrop()`, `serration()`                              |
| `engine/profile.scad`              | face names, selection, corner operations, fragments      |
| `engine/revolved.scad`             | cylinder/tube/torus/revolvepp profiles, argument parsing |
| `engine/box.scad`                  | frames, selectors, stages, rings, offsets, hull geometry |
| `engine/section.scad`              | sections: outlines, serration, wall chains, pieces       |
| `cubepp.scad`                      | thin module over the engine                              |
| `cylinderpp.scad`                  | thin module over the engine                              |
| `other_solidspp/tubepp.scad`       | thin module over the engine                              |
| `other_solidspp/revolvepp.scad`    | thin module over the engine                              |
| `other_solidspp/prismpp.scad`      | thin module over the engine                              |
| `other_solidspp/toruspp.scad`      | thin module over the engine                              |
| `other_solidspp/platonicpp.scad`   | platonicpp, wrappers, face and vertex helpers            |
| `engine/platonic.scad`             | solid data, numbering, modifier bodies, frames           |
| `engine/shape2d.scad`              | 2D outlines, side names, selection with base sides       |
| `shapespp/squarepp.scad`           | squarepp                                                 |
| `shapespp/polygonpp.scad`          | polygonpp                                                |
| `shapespp/circlepp.scad`           | circlepp                                                 |
| `shapespp/ringpp.scad`             | ringpp                                                   |
| `tests/test_shapes.scad`           | `assert`-based tests of the 2D shapes                    |
| `tests/gallery_shapes.scad`        | visual smoke test of the 2D shapes (extruded by 1)       |
| `tests/test_platonicpp.scad`       | `assert`-based tests of the platonic data layer          |
| `tests/gallery_platonicpp.scad`    | visual smoke test incl. engraved dice                    |
| `engine/prism.scad`                | base validation, side names, selectors, blended rings    |
| `tests/test_prismpp.scad`          | `assert`-based tests of the prism data layer             |
| `tests/gallery_prismpp.scad`       | visual smoke test of prismpp                             |
| `tests/test_revolved.scad`         | `assert`-based tests of the data layer (no geometry)     |
| `tests/test_cubepp.scad`           | `assert`-based tests of the box data and legacy layer    |
| `tests/test_sections.scad`         | `assert`-based tests of the sections                     |
| `tests/gallery_revolved.scad`      | visual smoke test of all combinations                    |
| `tests/gallery_cubepp.scad`        | visual smoke test of all combinations                    |
| `tests/gallery_sections.scad`      | visual smoke test of sections, holes in plates           |

- Vertex format: `[x, y, tag, sharp]`. `sharp=false` marks arc points; the tag
  `"_"` marks vertices that are not edges (axis, collinear points).
- Modifier format: `["__SPP_EDGE_MOD__", kind, value, [tokens]]`,
  `["__SPP_CORNER_MOD__", "bevel_corners", [x, y, z], [tokens]]`,
  `["__SPP_LEGACY_MOD__", name, data, call description]`.
- Box rings are hulled from a `polyhedron` with one face per ring (only its
  points matter to `hull()`).
- Corner fit check: on every profile edge, the legs taken by the corners at both
  ends must not exceed the edge length; points must stay at `x >= 0`.
- Modules contain no logic beyond calling the data functions and emitting
  geometry, so almost everything is testable with plain `assert`s.

## 9. Open items / roadmap

- [ ] Check in OpenSCAD: phase of `rotate_extrude` vs `cylinder()` for odd `fn`
      (a full-revolution `rotate_extrude` may start at 180°, `cylinder()`
      starts at 0°; irrelevant for even `fn` such as hex nuts).
- [x] Port `cubepp` to rings (section 5) and remove the old modifier internals.
- [ ] Check render times of `cubepp` with fine `$fa`/`$fs` (function evaluation
      of the rings) on 2021.01 and on a nightly.
- [x] Sections: `teardrop()` (point, bridge), `serration()` (triangle, round).
- [x] `sector` for revolved solids (bounding box of the full cylinder).
- [x] `polygon="polyhole"` (hole size compensation).
- [x] Taper of `cubepp` (`size_bottom`, `size_top`), `trapezoid` deprecated.
- [x] Unified face-name grammar (section 3.3), `revolvepp` (section 4.6).
- [x] `prismpp` (convex bases, points + `h`, faces `t`, `b`, `s0`..., section 5.4).
- [x] Taper of `prismpp` (`scale`, `scale_center`, `draft`, section 5.4).
- [x] `toruspp` on the revolved engine, `prism` deprecated.
- [x] `platonicpp` (dice) with face/vertex helpers, `tetrahedron` removed.
- [x] 2D shapes: `squarepp`, `polygonpp` with corner modifiers and flares,
  `circlepp` with `fn`/`polygon`/`sector`/`section`, `ringpp` (section 6).
- [ ] `rotate_extrudepp`, `projectpp`.
- [x] `spherepp` and `circlepp` are built at their largest diameter and scaled
      down for ellipsoids/ellipses (resolution scales with size, vertices on
      the sphere/circle as in OpenSCAD).
- [ ] Update README for the new modifiers.
- [ ] Separate task: review `transforms/`.
