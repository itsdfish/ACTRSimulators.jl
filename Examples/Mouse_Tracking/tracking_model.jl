###################################################################################################
#                                        Production Conditions
###################################################################################################
function can_wait(actr)
    c1(actr) = isempty(actr.visual_location.buffer)
    c2(actr) = isempty(actr.visual.buffer)
    c3(actr) = !actr.visual.state.busy
    c4(actr) = !actr.motor.state.busy
    return all_match(actr, c1, c2, c3, c4)
end

function can_find(actr)
    c1(actr) = isempty(actr.visual_location.buffer)
    c2(actr) = !actr.visual.state.busy
    all_match(actr, c1, c2)
end

function can_attend(actr)
    c1(actr) = !isempty(actr.visual_location.buffer)
    c2(actr) = !actr.visual.state.busy
    return all_match(actr, c1, c2)
end
###################################################################################################
#                                        Production Actions
###################################################################################################
function find_action(actr, args...)
    vo = actr.visicon[1]
    chunk = vo_to_chunk(actr, vo)
    add_to_buffer!(actr.visual_location, chunk)
    return nothing
end

function attend_action(actr, task, args...)
    buffer = actr.visual_location.buffer
    chunk = deepcopy(buffer[1])
    clear_buffer!(actr.visual_location)
    attending!(actr, chunk, task)
    return nothing
end

function respond_action(actr, task)
    clear_buffer!(actr.visual)
    key = "sb"
    responding!(actr, task, key)
    return nothing
end