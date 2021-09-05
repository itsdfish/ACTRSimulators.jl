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

function can_attend(actr)
    c1(actr) = !isempty(actr.visual_location.buffer)
    c2(actr) = !actr.visual.state.busy
    return all_match(actr, c1, c2)
end

function can_respond(actr)
    c1(actr) = !isempty(actr.visual.buffer)
    c2(actr) = !actr.motor.state.busy
    return all_match(actr, c1, c2)
end
###################################################################################################
#                                        Production Actions
###################################################################################################
function wait_action(actr, args...)
    description = "Wait"
    register!(actr, ()->(), now; description)
    return nothing
end

function attend_action(actr, task::PVT, args...)
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

function init_model(scheduler, task, id)
    name = string("model", id)
    procedural = Procedural()
    T = vo_to_chunk() |> typeof
    visual_location = VisualLocation(buffer=T[])
    visual = Visual(buffer=T[])
    visicon = VisualObject[]
    motor = Motor()
    actr = ACTR(;name, scheduler, procedural, visual_location, visual, motor, visicon)
    rule1 = Rule(;conditions=can_attend, action=attend_action, actr, task, name="Attend")
    push!(procedural.rules, rule1)
    rule2 = Rule(;conditions=can_wait, action=wait_action, actr, task, name="Wait")
    push!(procedural.rules, rule2)
    rule3 = Rule(;conditions=can_respond, action=respond_action, actr, task, name="Respond")
    push!(procedural.rules, rule3)
    return actr
end