// this __private__ function returns true if 'c' is in the 's'
function __solidpp__is_c_in_s(c,s) =
    len(search(c,s)) > 0;

// this __private__ fucntion provides offset in a single axis
function __solidpp__get_axis_offset(c,C,s,c_len) =
    is_undef(s) ?
        0 :
        __solidpp__is_c_in_s(c,s) ?
            c_len/2 :
            __solidpp__is_c_in_s(C, s) ?
                -c_len/2 :
                0;

// this __private__ function produce translation offset assuming bounding box center=true
function __solidpp__get_alignment_offset(size, align) = 
    [
        __solidpp__get_axis_offset("x", "X", align, size.x),
        __solidpp__get_axis_offset("y", "Y", align, size.y),
        __solidpp__get_axis_offset("z", "Z", align, size.z)
    ];

// this __private__ function ensures that valid 'arg' are unpacked to the 3D list,
// for invalid values, the 'default_value' is used
function __solidpp__get_argument_as_3Dlist(arg, default_value=undef) =
    is_undef(arg) ?
        default_value :
        is_list(arg) ?
            arg :
            [arg,arg,arg];

// this __private__ check validity of the 'var'
// '-> valid types are:
//     - 'undef',
//     - a list of size 3 containing only numbers,
//     - a single number
// if the assert fails, formatted yet generic message is shown
module __solidpp__assert_size_like(var, var_name, module_name)
{
    check =
        is_undef(var) ||        // - undef,
        (   is_list(var) &&     // - list ...
            len(var) == 3 &&    //   ... of size 3 ...
            is_num(var[0]) &&   //   ... containing ...
            is_num(var[1]) &&   //   ... only ... 
            is_num(var[2])      //   ... numbers,
        ) || 
        (is_num(var));          // - or a single value
    assert(
        check,
        str("[",module_name,"] argument '",var_name,"' can be either 'undef', list of size 3 containing only numbers, or a single number!")
    );
}

// this __protected__ function ensures that valid 'arg' are unpacked to the 2D list,
// for 'undef' values, the 'default_value' is used
function __solidpp__get_argument_as_2Dlist(arg, default_value=undef) = 
    is_undef(arg) ?
        default_value :
        is_list(arg) ?
            arg :
            [arg, arg];

// this __protected__ check validity of the 'var'
// '-> valid types are:
//     - 'undef',
//     - a list of size 2 containing only numbers,
//     - a single number
// if the assert fails, formatted yet generic message is shown
module __solidpp__assert_2D_vector_like(var, var_name, module_name)
{
    check =
        is_undef(var) ||        // - undef,
        (   is_list(var) &&     // - list ...
            len(var) == 2 &&    //   ... of size 2 ...
            is_num(var[0]) &&   //   ... containing ...
            is_num(var[1])      //   ... only numbers,
        ) || 
        (is_num(var));          // - or a single value
    assert(
        check,
        str("[",module_name,"] argument '",var_name,"' can be either 'undef', list of size 2 containing only numbers, or a single number!")
    );
}


// creates offset vector 3D denoting translation from the centered bounding box into desired alignment
// '-> argument '_size' is the bounding box size (processed size/r/d/whatever as vector 3D)
// '-> argument 'align' is the raw 'align' solidpp argument
// '-> argument 'center' is the raw 'center' solidpp argument
// '-> argument 'solidpp_name' is the name of the modul calling this function
// '-> argument 'def_align' is the string denoting the default alignment
// NOTE: arguments 'align' and 'center' are checked within this function
function __solidpp__produce_offset_from_align_and_center(_size, align, center, solidpp_name, def_align) =
    
    // check align,
    // '-> it is string or undef
    assert(
            is_undef(align) || is_string(align),
            str("[", solidpp_name ,"] arguments 'align' must be eithter 'undef' or a string!")
            )

    // parse alignment
    // '-> if undef, use default
    let (_align = is_undef(align) ? def_align : align)
    
    // check center
    // '-> it is just a bool
    assert(
            is_bool(center),
            str("[", solidpp_name ,"] argument 'center' must be bool!")
            )
    
    // return valid offset
    center ?
        [0,0,0] :
        __solidpp__get_alignment_offset(_size, _align);


// translate argument 'zet' to the rotation keeping the expected orientation
function __solidpp__get_rotation_from_zet(zet, default_value=[0,0,0]) = 
    is_undef(zet) ?
        default_value :
        zet == "x" || zet == "X" ?
            [0,90,0] :
            zet == "y" || zet == "Y" ?
                [-90,0,0] :
                zet == "z" || zet == "Z" ?
                    [0,0,0] :
                    default_value;


// __private__ recursive implementation of the umbers within list checker
function __spp__is_list_of_numbers_rec(l, idx, res) = 
    idx == len(l) ? 
        res :
        __spp__is_list_of_numbers_rec(l, idx+1, res && is_num(l[idx]));


// __protected__ checks the list and returns true if the list contain numbers only
// '-> morever, if 'dim' is defined, the length of the list is checked
function __solidpp__is_list_of_numbers(l, dim=undef) =
    is_list(l) &&
    (is_undef(dim) || len(l) == dim) &&
    __spp__is_list_of_numbers_rec(l, 0, true);


// __private__ recursive implementation of list of vectors checker
function __spp__check_list_of_vectors_rec(l, idx, res, dim=undef) = 
    idx == len(l) ?
        res :
        __spp__check_list_of_vectors_rec(l, idx+1, res && __solidpp__is_list_of_numbers(l[idx], dim), dim);


// __protected__ checks the list and returns true if the list contains only list of numbers (vectors)
// '-> morever, if 'dim' is defined, the length of each list is checked
function __solidpp__check_list_of_vectors(l, dim=undef) =
    is_list(l) &&
    __spp__check_list_of_vectors_rec(l, 0, true, dim);
