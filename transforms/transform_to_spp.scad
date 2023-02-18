include<../utils/solidpp_utils.scad>
include<../utils/vector_operations.scad>

// produce the offset
// '-> given input string 's' for axis defined by 'c' and 'C' of length 'l' 
function __solidpp__transforms__process_size_char(l, s, c, C) = 
    __solidpp__is_c_in_s(c,s) ?
        echo(true)
        -0.5*l :
        __solidpp__is_c_in_s(C,s) ?
        echo(false)
            0.5*l :
            echo("def")
            0;

// produce the offset including possible interpolation
function __solidpp__transforms__process_size_el(l, s, c, C, int) = 
    is_undef(int) ?
        echo(str(l," ",s," ",c," ",C," ",int))
        __solidpp__transforms__process_size_char(l=l,s=s,c=c,C=C) :
        (int-0.5)*l;


function get_translation_to_spp(size, align, pos, x=undef, y=undef, z=undef) =
    add_vs
    (
        [
            __solidpp__transforms__process_size_el(l=size.x, s=pos, c="x", C="X", int=x),
            __solidpp__transforms__process_size_el(l=size.y, s=pos, c="y", C="Y", int=y),
            __solidpp__transforms__process_size_el(l=size.z, s=pos, c="z", C="Z", int=z)
        ],
        __solidpp__get_alignment_offset(size=size,align=align)
    );

function get_translations_to_spp(size, align, pos, x=undef, y=undef, z=undef) =
    0;

module translate_to_spp(size, align, pos, x=undef, y=undef, z=undef) 
{
    // TODO check
 
    __off = get_translation_to_spp(size=size, align=align, pos=pos, x=x, y=y, z=z);

    translate(__off)
    {
        children();
    }

}
