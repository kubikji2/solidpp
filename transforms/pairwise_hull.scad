include<transform_to_spp.scad>


module pairwise_hull()
{
    assert($children >=2, "[SOLIDEPP-pairwise_hull] at least 2 children are required for pairwise_hull!");
    for (i=[0:$children-2])
    {

        hull()
        {
            children(i);
            children(i+1);
        }
    }
}

