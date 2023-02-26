

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