include<transform_to_spp.scad>

// replicate children on each of the given `position` and for each of the copies apply the `hull`
// - argument `positions` is a list of of 3D positions at which the children are copied
// - optional argument `rotations` is a list of 3D rotation defining the rotation of individual children
//   '-> must be of the same length as the `position`
//   '-> if kept undefined, no rotations are applied
// - optional argument `aligns` is a list of children alignments
//   '-> if used, argument `children_align` and `children_size` must also be defined so the `transform_to_spp` can be applied
// - if number of children matches the number of positions, the individual children are used for each position
module hull_for_each_pair(positions, rotations=undef, aligns=undef, children_align="", children_size=[0,0,0])
{
    assert is_undef(rotations) || (is_list(rotations) && is_list(rotations[0]) && len(positions)==len(rotations)), "[solidpp-hull_for] argument rotations is either kept undefined or has the same length as the positions."
    
    assert is_undef(aligns) || (is_list(aligns) && len(positions)==len(aligns)), "[solidpp-hull_for] argument aligns is either kept undefined or has the same length as the positions."

    

    _n_geometries = len(positions);
    for (i=[0:_n_geometries-2])
    {

        hull()
        {
            translate(positions[i])
                rotate(is_undef(rotations) ? [0,0,0] : rotations[i])
                    transform_to_spp(   size=children_size,
                                        align=children_align,
                                        pos=is_undef(aligns) ? "" : aligns[i])
                        if (len(positions) == $children) {
                            children(i);
                        } else {
                            children();
                        }

            translate(position[i+1])
                rotate(is_undef[rotations] ? [0,0,0] : rotations[i+1])
                    transform_to_spp(   size=children_size,
                                        align=children_align,
                                        pos=is_undef(aligns) ? "" : aligns[i+1])
                        if (len(positions) == $children) {
                            children(i+1);
                        } else {
                            children();
                        }
        }
    }
}

