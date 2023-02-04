function __solidpp_is_c_in_s(c,s) =
    len(search(c,s)) > 0;


function __solidpp_get_offset(c,C,s,c_len) =
    is_undef(s) ?
        0 :
        __solidpp_is_c_in_s(c,s) ?
            c_len/2 :
            __solidpp_is_c_in_s(C, s) ?
                -c_len/2 :
                0;


function __solidpp_get_offsets(size, align) = 
    [
        __solidpp_get_offset("x", "X", align, size.x),
        __solidpp_get_offset("y", "Y", align, size.y),
        __solidpp_get_offset("z", "Z", align, size.z)
    ];
    