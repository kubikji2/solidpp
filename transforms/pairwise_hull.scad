include<transform_to_spp.scad>

// hull of every pair of consecutive children: children(0) + children(1), children(1) + children(2), ...
// - argument 'closed' if true, also the last child with the first one (a loop, a frame)
module pairwise_hull(closed=false)
{
    assert($children >= 2, "[PAIRWISE_HULL] at least 2 children are required for pairwise_hull!");
    assert(is_bool(closed), str("[PAIRWISE_HULL] argument 'closed' must be a boolean, got ", closed));
    for (i = [0:1:$children-2])
        hull()
        {
            children(i);
            children(i+1);
        }
    if (closed && $children > 2)
        hull()
        {
            children($children-1);
            children(0);
        }
}
