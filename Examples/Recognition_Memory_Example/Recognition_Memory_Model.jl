###################################################################################################
#                                        Production Conditions
###################################################################################################
function can_attend(actr)
    c1(actr) = !isempty(actr.visual_location.buffer)
    c2(actr) = !actr.visual.state.busy
    return all_match(actr, (c1,c2))
end

function can_encode(actr)
    c1(actr) = !actr.visual.state.empty
    c2(actr) = !actr.imaginal.state.busy
    c3(actr) = actr.imaginal.state.empty
    return all_match(actr, (c1,c2,c3))
end

function can_respond(actr)
    c1(actr) = !isempty(actr.visual.buffer)
    c2(actr) = !actr.motor.state.busy
    c3(actr) = actr.goal.buffer[1].slots.goal == :test
    return all_match(actr, (c1,c2,c3))
end

###################################################################################################
#                                        Production Actions
###################################################################################################
function encode_action(actr, task)
    buffer = actr.visual.buffer
    word = buffer[1].slots.text
    chunk = Chunk(;word)
    clear_buffer!(actr.visual)
    # modify chunk
    tΔ =  encoding!(actr, chunk)
    register!(actr, clear_buffer!, after, tΔ , actr, actr.imaginal)
    return nothing
end

function attend_action(actr, args...)
    buffer = actr.visual_location.buffer
    chunk = deepcopy(buffer[1])
    clear_buffer!(actr.visual_location)
    attending!(actr, chunk)
    return nothing
end

function respond_action(actr, task)
    clear_buffer!(actr.visual)
    key = "sb"
    responding!(actr, task, key)
    return nothing
end