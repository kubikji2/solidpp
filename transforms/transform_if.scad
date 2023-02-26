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
