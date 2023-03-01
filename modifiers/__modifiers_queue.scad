include<modifiers.scad>
include<../utils/solidpp_utils.scad>

__QUEUE_ID = "__MOD_QUEUE__";

// queue is a list of length 3
// idx 0 - contains the string __QUEUE_ID
// idx 1 - is the list of mods
// UNUSED idx 2 - is the list of 3D vectors defining the size
// returns whether argument is queue
function __solidpp__is_queue(queue) = 
    is_list(queue) &&
    len(queue) == 2 &&
    // is idx 0 string
    is_string(queue[0]) &&
    queue[0] == __QUEUE_ID &&
    // is idx 1 list of valid modifiers
    __solidpp__is_valid_modifier_list(queue[1]);


// returns the length of the 
function __solidpp__queue_size(queue) =
    __solidpp__is_queue(queue) ?
        len(queue[1]) :
        undef;

// recursive implementation of construction of compensated queue
function __spp__queue__construct_compensated_queue_rec(old_list, new_list, old_r, idx) = 
    idx == -1 ?
        new_list :
        let(
                _old_mod = old_list[idx],
                _new_mod = __solidpp__compensate_for_rounding(_old_mod, old_r),
                _cur_r = __solidpp__is_valid_round_corners_modifier(_old_mod) ?
                            _old_mod[1] :
                            [0,0,0],
                _new_r = add_vecs(old_r, _cur_r),
                _new_list = [_new_mod, each new_list]
            )
        echo(idx, _new_mod)
        __spp__queue__construct_compensated_queue_rec(old_list, _new_list, _new_r, idx-1);


// creates queue from mod list with the modified properties
function __spp__queue__construct_compensated_queue(mod_list) =
    __spp__queue__construct_compensated_queue_rec(mod_list, [], [0,0,0], len(mod_list)-1);

// returns queue if possible, [undef, "msg"] otherwise
function __solidpp__new_queue(mod_list) = 
    // check list
    !__solidpp__is_valid_modifier_list(mod_list) ? 
        [undef, "provided argument is not a list of modifiers"] :
        [
            __QUEUE_ID,
            __spp__queue__construct_compensated_queue(mod_list)
        ];

// returns modification and the new queue
function __solidpp__pop(queue) = 
    let(
        queue_size = __solidpp__queue_size(queue),
        mods = queue[1])
    !__solidpp__is_queue(queue) || queue_size <= 0 ?
        undef :
        [
            mods[0],
            [
                __QUEUE_ID,
                queue_size > 0 ?
                    [for(i=[1:len(mods)-1]) mods[i]] :
                    []
            ]

        ];