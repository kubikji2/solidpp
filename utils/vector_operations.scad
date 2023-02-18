
// recursively checks whether each element of the list is number
function __spp__is_vector_rec(l,idx,res) = 
    idx == len(l) ?
        res :
        __spp__is_vector_rec(l,idx+1,res && is_num(l[idx]));

// checks whether argument is list containing only numbers
function is_vector(l) =
    is_list(l) &&
    __spp__is_vector_rec(l,0,true);


// check whether arguments are compatible
// '-> both are vectors
// '-> have same length
function are_vectors_compatible(v1,v2) = 
    is_vector(v1) &&
    is_vector(v2) &&
    len(v1) == len(v2);

// add two vectors
// '-> if compatible return the vector sum
// '-> 'undef' otherwise
function add_vectors(v1,v2) = 
    are_vectors_compatible(v1,v2) ?
        [for (i=[0:len(v1)-1]) v1[i]+v2[i]] :
        echo(str("[VECTOR] addition not defined for provided arguments ",v1," and ",v2," !"))
        undef;

// shorter wrapper
function add_vs(v1,v2) = add_vectors(v1,v2);
