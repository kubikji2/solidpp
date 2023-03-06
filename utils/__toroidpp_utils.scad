include<solidpp_utils.scad>

// __protected__ function to processing and parsing the toruspp and tubepp argument
// returns [_r, _R, _t, _h]
function __solidpp__toroidpp__check_parameters(module_name, r, d, R, D, t, h, def_r=0.5, def_R=1) =
    // raw argument mutex group
    let(
        _raw_mutex = [  t, 
                            is_undef(r) ? d : r,
                            is_undef(R) ? D : R
                        ],
        _raw_undef = __solidpp__count_undef_in_list(_raw_mutex),

        // first parameter processing
        __t = t,
        __r = _raw_undef == 3 ?
                0.5 :
                !is_undef(d) ?
                    d/2 :
                    r,
        __R = _raw_undef == 3 ?
                1 :
                !is_undef(D) ?
                    D/2 :
                    R,

        // computing user-defined parameters
        _mutex_group = [__t, __r, __R],
        _n_undef = __solidpp__count_undef_in_list(_mutex_group)
    )

    // check the new mutex group
    assert(_n_undef == 1,
            str("[", module_name, "] exactly two arguments {'r|d', 'R|D', 't'} must be defined!"))
    assert(is_undef(r) || is_undef(d),
            str("[", module_name, "] cannot define both 'r' and 'd'!"))
    assert(is_undef(R) || is_undef(D),
            str("[", module_name, "] cannot define both 'R' and 'D'!"))
    
    let(
        _r = !is_undef(__t) && !is_undef(__R) ? __R-__t : __r,
        _R = !is_undef(__t) && !is_undef(__r) ? __r+__t : __R,
        _t = !is_undef(__R) && !is_undef(__r) ? __R-__r : __t,

        _h = is_undef(h) ?
            _t :
            h
    )
    
    [_r, _R, _t, _h];
