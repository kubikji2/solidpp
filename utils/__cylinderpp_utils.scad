include<solidpp_utils.scad>

// '_h' idx
__CYLINDERPP_UTILS__h_idx = 0;
// '_size' idx
__CYLINDERPP_UTILS__size_idx = 1;
// '_d1' idx
__CYLINDERPP_UTILS__d1_idx = 2;
// '_d2' idx
__CYLINDERPP_UTILS__d2_idx = 3;
// '_d_max' idx
__CYLINDERPP_UTILS__d_max_idx = 4;
// '__d1' idx
__CYLINDERPP_UTILS___d1_idx = 5;
// '__d2' idx
__CYLINDERPP_UTILS___d2_idx = 6;
// '_non_uniform' idx
__CYLINDERPP_UTILS__is_non_uniform_idx = 7;
// '_fn' idx
__CYLINDERPP_UTILS__fn_idx = 8;


function __solidpp__cylinderpp__check_params(module_name, size, r, d, h, r1, r2, d1, d2, zet, fn, def_h=1, def_d=1, def_size=[1,1,1]) = 
    
    // pre processing the size
    let(
            // create bounding box from size
            __size = __solidpp__get_argument_as_3Dlist(size, undef),
            
            // define whether the non-uniform scaling has been used
            _extracted_data = __solidpp__get_a_b_h_from_size_and_zet(__size),
            _is_non_uniform = !is_undef(__size) && _extracted_data[0] != _extracted_data[1]
        )
    
    // {h, r|d} and size is illegal
    assert( is_undef(size) || (is_undef(r) && is_undef(d) && is_undef(h)) ,
            str("[", module_name, "] defining both 'size' and ('r'|'d'),'h' is not permited!"))

    // check h
    assert( is_undef(h) || is_num(h),
            str("[", module_name, "] argument 'h' is not a number!"))
    
    // process heigh
    let (
        
        _h = !is_undef(h) || (!is_undef(size) && _is_non_uniform) ?
                h :
                !is_undef(size) ? 
                    _extracted_data[2] :
                    def_h
        )

    // check r and d
    assert( is_undef(r) || is_num(r) || is_vector_2D(r),
            str("[", module_name, "] argument 'r' is neither a number nor vector 2D!"))
    assert( is_undef(d) || is_num(d) || is_vector_2d(d), 
            str("[", module_name, "] argument 'd' is neither a number nor vector 2D!"))
    assert( is_undef(r) || is_undef(d),
            str("[", module_name, "] defining both 'd' and 'r' is not permitted!"))
    // process r and d
    let(
        _d = !is_undef(d) ?
                d :  
                !is_undef(r) ?
                    is_num(r) ?  // this is not necessary in recent openscad releases
                        2*r :
                        scale_vector(2,r) :
                    _is_non_uniform ?
                        def_d :
                        is_undef(_extracted_data[0]) ?
                            def_d :
                           _extracted_data[0]
    )

    // d1,d2 and r1,r2 must be defined in pairs
    assert( is_undef(d1)==is_undef(d2),
            str("[", module_name, "] either none or both arguments 'd1','d2' must be defined!"))
    assert( is_undef(r1)==is_undef(r2),
            str("[", module_name, "] either none or both arguments 'r1','r2' must be defined!"))

    // d1, d2, r1, r2 are either undefined or numbers
    assert( is_undef(r1) || is_num(r1),
            str("[", module_name, "] argument 'r1' is not a number!"))
    assert( is_undef(d1) || is_num(d1), 
            str("[", module_name, "] argument 'd1' is not a number!"))
    assert( is_undef(r2) || is_num(r2),
            str("[", module_name, "] argument 'r2' is not a number!"))
    assert( is_undef(d2) || is_num(d2),
            str("[", module_name, "] argument 'd2' is not a number!"))

    // both r1,r2 and d1,d2 pairs cannod be defined at the same time
    assert( is_undef(r1) || is_undef(d1),
            str("[", module_name, "] you cannot define both 'r1' and 'd1' at the same time!"))
    assert( is_undef(r2) || is_undef(d2),
            str("[", module_name, "] you cannot define both 'r2' and 'd2' at the same time!"))
    
    let(
        // process r1,r2 or d1,d2 or _d to absolute diameters __d1,__d2
        __d1 = !is_undef(d1) ?
                d1 :
                !is_undef(r1) ?
                    2*r1 :
                    is_vector_2D(_d) ?
                        _d[0] :
                        _d,
        
        __d2 = !is_undef(d2) ?
                d2 :
                !is_undef(r2) ?
                    2*r2 :
                    is_vector_2D(_d) ?
                        _d[1] :
                        _d,
        
        // get maximum of the the diameters __d1,__d2
        _d_max = !is_undef(__d1) && ! is_undef(__d2) ?
                    max(__d1,__d2) :
                    undef,

        // d1 and d2 are either 1, or relative to each other
        _d1 = !is_undef(__d1) && !is_undef(_d_max) ?
                __d1/_d_max :
                1,
        
        _d2 = !is_undef(__d2) && !is_undef(_d_max) ?
                __d2/_d_max :
                1,
    
        // create bounding box, possibly using cylinder-specific arguments
        _size = !is_undef(__size) ?
                    __size :
                    !is_undef(_d_max) && !is_undef(_h) ?
                        __solidpp__construct_cylinderpp_size(_d_max, _h, zet) :
                        def_size
    )

    // check fn
    assert ( is_undef(fn) || (is_num(fn) && fn > 2),
            str("[", module_name, "] argument 'fn' is not a number greater then 2!"))

    // handling the fn
    let(
        _fn = !is_undef(fn) ?
                fn :
                !is_undef($fn) ?
                    $fn : 32
    )
    
    [_h, _size, _d1, _d2, _d_max, __d1, __d2, _is_non_uniform, _fn];


// __protected__ module creating the default cylinder plane
module __solidpp__cylinderpp__get_def_plane(d1, d2, h)
{
    _h2 = h/2;
    _pts = [    [    0, -_h2],
                [ d1/2, -_h2],
                [ d2/2,  _h2],
                [    0,  _h2]];
    polygon(_pts);
}