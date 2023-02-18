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
function __solidpp__get_agument_as_3Dlist(arg, default_value=undef) =
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