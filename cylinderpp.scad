include<solidpp_utils.scad>


function __solidpp_construct_size(d,h,zet) =
    is_undef(zet) ?
        [d,d,h] :
        (zet == "x") || (zet == "X") ?
            [h,d,d] :
            (zet == "y") || (zet == "Y") ?
                [d,h,d] :
                [d,d,h];


module cylinderpp(size=undef, r=undef, d=undef, h=undef, align=undef, zet=undef, center=false, r1=undef, r2=undef, d1=undef, d2=undef)
{

    __module_name = "CYLINDERPP";

    // h, d|r and size is illegal
    assert(is_undef(size) || (is_undef(r) && is_undef(d) && is_undef(h)) , "[CYLINDERPP] defining both 'size' and ('r'|'d'),'h' is not permited!");

    // check h
    assert(is_undef(h) || is_num(h), "[CYLINDERPP] argument 'h' is either undefined or scalar value!");
    // process heigh
    _h = !is_undef(h) ? h : 1;

    // check r and d
    assert(is_undef(r) || is_num(r), "[CYLINDERPP] argument 'r' is either undefined or scalar value!");
    assert(is_undef(d) || is_num(d), "[CYLINDERPP] argument 'd' is either undefined or scalar value!");
    assert(!is_undef(r) || !is_num(d), "[CYLINDERPP] defining both 'd' and 'r' is not permitted!");
    // process r and d
    _d = !is_undef(d) ?
            d :  
            !is_undef(r) ?
                2*r :
                undef;

    // d1,d2 and r1,r2 must be defined in pairs
    assert(is_undef(d1)==is_undef(d2), "[CYLINDERPP] either none or both arguments 'd1','d2' must be defined!");
    assert(is_undef(r1)==is_undef(r2), "[CYLINDERPP] either none or both arguments 'r1','r2' must be defined!");
    // d1, d2, r1, r2 are either undefined or numbers
    assert(is_undef(r1) || is_num(r1), "[CYLINDERPP] argument 'r1' is either undefined or scalar value!");
    assert(is_undef(d1) || is_num(d1), "[CYLINDERPP] argument 'd1' is either undefined or scalar value!");
    assert(is_undef(r2) || is_num(r2), "[CYLINDERPP] argument 'r2' is either undefined or scalar value!");
    assert(is_undef(d2) || is_num(d2), "[CYLINDERPP] argument 'd2' is either undefined or scalar value!");
    // both r1,r2 and d1,d2 pairs cannod be defined at the same time
    assert(!((!is_undef(d1) && !is_undef(d2)) && (!is_undef(r1) && !is_undef(r2))), "[CYLINDERPP] you cannot define both 'r1','r2' and 'd1','d2'!");
    
    // process r1,r2 or d1,d2 or _d to absolute diameters __d1,__d2
    __d1 = !is_undef(d1) ?
            d1 :
            !is_undef(r1) ?
                2*r1 :
                _d;
    
    __d2 = !is_undef(d2) ?
            d2 :
            !is_undef(r2) ?
                2*r2 :
                _d;
    
    // get maximum of the the diameters __d1,__d2
    _d_max = !is_undef(__d1) && ! is_undef(__d2) ?
                max(__d1,__d2) :
                undef;

    // d1 and d2 are either 1, or relative to each other
    _d1 = !is_undef(__d1) && !is_undef(_d_max) ?
            __d1/_d_max :
            1;
    
    _d2 = !is_undef(__d2) && !is_undef(_d_max) ?
            __d2/_d_max :
            1;

    // check zet
    // '-> it is string or undef
    assert(is_undef(zet) || is_string(zet), "[CYLINDERPP] arguments 'zet' is eithter 'undef' or a string!");
    // construct rotation
    _r = is_undef(zet) ?
            [0,0,0] :
            zet == "x" || zet == "X" ?
                [0,90,0] :
                zet == "y" || zet == "Y" ?
                    [-90,0,0] :
                    [0,0,0];


    // check size
    __solidpp_assert_size_like(size, "size", __module_name);
    
    // create bounding box from size
    __size = __solidpp_get_agument_as_3Dlist(size, undef);
    // create bounding box, possibly using cylinder-specific arguments
    _size = !is_undef(__size) ?
                __size :
                !is_undef(__size) ?
                    __size :
                    !is_undef(_d_max) && !is_undef(_h) ?
                        __solidpp_construct_size(_d_max, _h, zet) :
                        [1,1,1];

    // check align
    // '-> it is string or undef
    assert(is_undef(align) || is_string(align), "[SPHEREPP] arguments 'align' is eithter 'undef' or a string!");

    // parse alignment
    // '-> if undef, use default
    _align = is_undef(align) ? "c" : align;

    // check center
    // '-> it is just a bool
    assert(is_bool(center), "[SPHEREPP] argument 'center' must be bool!");
    
    // create offset
    _o = center ? [0,0,0] : __solidpp_get_offsets(_size, _align);
    
    // construct the solid
    translate(_o)
        resize(_size)
            rotate(_r)
                cylinder(d1=_d1,d2=_d2,h=1, center=true);
}
