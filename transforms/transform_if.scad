// apply 'hull' on the children
// iff the argument 'condition' is met,
// otherwise union is applied
module hull_if(condition)
{
    assert(is_bool(condition), "[hull_if] argument 'condition' must be a boolean!");

    if (condition)
    {
        hull()
            children();
    }
    else
    {
        children();
    }

}

// apply 'minkowski' on the children
// iff the argument 'condition' is met,
// otherwise union is applied
module minkowski_if(condition)
{
    assert(is_bool(condition), "[minkowski_if] argument 'condition' must be a boolean!");

    if (condition)
    {
        minkowski()
            children();
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

    assert(is_bool(condition), "[difference_if] argument 'condition' must be a boolean!");
    assert(is_bool(ommit_children), "[difference_if] argument 'ommit_children' must be a boolean!");

    if (condition)
    {
        difference()
            children();
    }
    else if(ommit_children)
    {
        children(1);
    }
    else
    {
        children();
    }

}