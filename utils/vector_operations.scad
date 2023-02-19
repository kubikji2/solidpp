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

// shorter addition wrappers
function add_vecs(v1,v2) = add_vectors(v1,v2);
function add_vs(v1,v2) = add_vectors(v1,v2);

// subtract two vectors
// '-> if compatible return the vector difference
// '-> 'undef' otherwise
function subtract_vectors(v1,v2) = 
    are_vectors_compatible(v1,v2) ?
        [for (i=[0:len(v1)-1]) v1[i]-v2[i]] :
        echo(str("[VECTOR] subtraction not defined for provided arguments ",v1," and ",v2," !"))
        undef;

// shorter subtraction wrappers
function sub_vectors(v1,v2) = subtract_vectors(v1,v2);
function sub_vecs(v1,v2) = subtract_vectors(v1,v2);
function sub_vs(v1,v2) = subtract_vectors(v1,v2);

// multiply vector 'v' by scalar value 's'
// '-> order does not matter
function scale_vector(s,v) = 
    is_vector(v) && is_num(s) ?
        [for (i=[0:len(v)-1]) s*v[i]] :
        is_vector(s) && is_num(v) ?
            [for (i=[0:len(s)-1]) v*s[i]] :
            undef;

// shorter scaling wrapper
function scale_vec(s,v) = scale_vector(s,v);
function s_vec(s,v) = scale_vector(s,v);

// return 'true' if 'v' is a vector of size 'l'
function is_vector_of_size(v,l) = 
    is_vector(v) && len(v) == l;

// checks 3D and 2D vector
function is_vector_3D(v) = is_vector_of_size(v,3);
function is_vector_2D(v) = is_vector_of_size(v,2);

// recursively checks whether all vector elements are non negative
function __spp__is_vector_non_negative_rec(v, idx,res) = 
    idx == len(v) ?
        res :
        __spp__is_vector_non_negative_rec(v, idx+1, res && (v[idx] >= 0));

// checks whether all vector elements are non-negative
// '-> returns 'true' if so
// '-> returns 'false' if any element is negative
// '-> returns 'undef' if provided argument 'v' is not a vector
function is_vector_non_negative(v) =
    is_vector(v) ?
        __spp__is_vector_non_negative_rec(v,0,true):
        undef;

