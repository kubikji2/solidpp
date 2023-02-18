
// recursively checks whether each element of the list is number
function __spp__is_vector_rec(l,idx,res) = 
    idx == len(l) ?
        res :
        __spp__is_vector_rec(l,idx+1,res && is_num(l[idx]));

// checks whether argument is list containing only numbers
function is_vector(l) =
    is_list(l) &&
    __spp__is_vector_rec(l,0,true);


