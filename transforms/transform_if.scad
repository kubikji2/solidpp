// apply 'hull' on the children
// iff the argument 'condition' is met,
// otherwise if 'ommit_children' is
// true, only first children is kept
// otherwise union is applied
module hull_if(condition, ommit_children=true)
{
    // checking condition
    assert(is_bool(condition), "[minkowski_if] argument 'condition' must be a boolean!");
    
    // checking ommit_children
    assert(is_bool(ommit_children), "[minkowski_if] argument 'ommit_children' must be a boolean!");

    if (condition)
    {
        hull()
            children();
    }
    else if(ommit_children)
    {
        children(0);
    }
    else
    {
        children();
    }
}

module __spp__minkowski_rec(cnt=0)
{
    echo($children);
    if ($children > 1 && cnt < 10)
    {
        minkowski()
        {
            children(0);
            __spp__minkowski_rec(cnt+1)
                children([1:$children-1]);
        }
    }
}


// apply 'minkowski' on the children
// iff the argument 'condition' is met,
// otherwise if 'ommit_children' is
// true, only first children is kept
// otherwise union is applied
module minkowski_if(condition, ommit_children=true)
{
    assert($children <= 2, "[minkowski_if] unfortunately, minkowski_if support only 2 children! TIP: apply minkowski to children([1:]) outside of the module.");

    // checking condition
    assert(is_bool(condition), "[minkowski_if] argument 'condition' must be a boolean!");
    
    // checking ommit_children
    assert(is_bool(ommit_children), "[minkowski_if] argument 'ommit_children' must be a boolean!");

    if (condition)
    {
        minkowski()
        {
            children(0);
            children(1);   
        }            
    }
    else if(ommit_children)
    {
        children(0);
    }
    else
    {
        children();
    }

}

// apply 'difference' on the children
// iff the argument 'condition' is met,
// otherwise if 'ommit_children' is
// true, only first children is kept
// otherwise union is applied
module difference_if(condition, ommit_children=true)
{

    // checking condition
    assert(is_bool(condition), "[difference_if] argument 'condition' must be a boolean!");
    
    // checking ommit_children
    assert(is_bool(ommit_children), "[difference_if] argument 'ommit_children' must be a boolean!");

    if (condition)
    {
        difference()
        {
            children(0);
            for(i=[1:$children-1])
            {
                children(i);
            }
        }
    }
    else if(ommit_children)
    {
        children(0);
    }
    else
    {
        children();
    }

}