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
    c4(actr) = actr.visual.buffer[1].slots.text != "start test"
    c5(actr) = actr.goal.buffer[1].slots.goal != :test
    return all_match(actr, (c1,c2,c3,c4,c5))
end

function can_start(actr)
    c1(actr) = !actr.visual.state.empty
    c2(actr) = actr.visual.buffer[1].slots.text == "start test"
    return all_match(actr, (c1,c2))
end

function can_retrieve(actr)
    c1(actr) = !actr.declarative.state.busy
    c2(actr) = !actr.visual.state.empty
    c3(actr) = actr.goal.buffer[1].slots.goal == :test
    return all_match(actr, (c1,c2,c3))
end

function can_respond_yes(actr)
    c1(actr) = !actr.declarative.state.empty
    c2(actr) = !actr.motor.state.busy
    return all_match(actr, (c1,c2))
end

function can_respond_no(actr)
    c1(actr) = actr.declarative.state.error
    c2(actr) = !actr.motor.state.busy
    return all_match(actr, (c1,c2))
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

function start_action(actr, task)
    clear_buffer!(actr.visual)
    actr.goal.buffer[1].slots = (goal=:test,)
    register!(actr, ()->(), now; description="start test phase")
    return nothing
end

function retrieve_word(actr, task)
    word = actr.visual.buffer[1].slots.text
    clear_buffer!(actr.visual)
    retrieving!(actr; word)
end

function respond_yes(actr, task)
    clear_buffer!(actr.declarative)
    key = "y"
    responding!(actr, task, key)
    return nothing
end

function respond_no(actr, task)
    clear_buffer!(actr.declarative)
    key = "n"
    responding!(actr, task, key)
    return nothing
end