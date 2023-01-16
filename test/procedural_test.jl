@safetestset "microlapse " begin 
    using ACTRSimulators, Test, ACTRModels, Random, DataFrames
    import ACTRSimulators: start!, press_key!
    using ACTRSimulators: get_rule_set, select_rule, match
    Random.seed!(8985)
    include("task.jl")
    
    parms = (u0=0.5, τu=1.0, u0Δ=.90, τuΔ=.90)
    
    scheduler = ACTRScheduler(;model_trace=true, store=true)
    task = SimpleTask(;scheduler)
    procedural = Procedural()
    T = vo_to_chunk() |> typeof
    visual_location = VisualLocation(buffer=T[])
    visual = Visual(buffer=T[])
    visicon = VisualObject[]
    motor = Motor()
    memory = [Chunk(;animal=:dog), Chunk(;animal=:cat)]
    declarative = Declarative(;memory)
    actr = ACTR(;scheduler, 
                procedural, 
                visual_location, 
                visual, 
                motor, 
                declarative, 
                visicon,
                parms...)
    
    function can_attend(actr)
        c1(actr) = !isempty(actr.visual_location.buffer)
        c2(actr) = !actr.visual.state.busy
        return c1, c2
    end  
    
    function can_encode(actr)
        c1(actr) = !isempty(actr.visual.buffer)
        c2(actr) = !actr.imaginal.state.busy
        return c1, c2
    end    
    
    function can_respond(actr)
        c1(actr) = !isempty(actr.imaginal.buffer)
        c2(actr) = !actr.motor.state.busy
        return c1, c2
    end   
    
    function attend_action(actr, task)
        buffer = actr.visual_location.buffer
        chunk = deepcopy(buffer[1])
        clear_buffer!(actr.visual_location)
        attending!(actr, chunk)
        return nothing
    end
    
    function encode_action(actr, task)
        buffer = actr.visual.buffer
        chunk = deepcopy(buffer[1])
        clear_buffer!(actr.visual)
        encoding!(actr, chunk)
        return nothing
    end
    
    function motor_action(actr, task)
        buffer = actr.imaginal.buffer
        chunk = deepcopy(buffer[1])
        clear_buffer!(actr.imaginal)
        key = chunk.slots.text
        responding!(actr, task, key)
        return nothing
    end
    
    rule1 = Rule(;conditions=can_attend, action=attend_action, actr, task, name="Attend")
    push!(procedural.rules, rule1)
    
    rule2 = Rule(;conditions=can_encode, action=encode_action, actr, task, name="Encode")
    push!(procedural.rules, rule2)
    
    rule3 = Rule(;conditions=can_respond, action=motor_action, actr, task, name="Respond")
    push!(procedural.rules, rule3)
    
    present_stimulus(task, actr)
    
    rules = get_rule_set(actr)
    
    rule,state = select_rule(actr, rules)
    
    @test state == :microlapse

    @test actr.parms.utility_decrement == .90
    @test actr.parms.threshold_decrement == .90
end


@safetestset "production rule selected " begin 
    using ACTRSimulators, Test, ACTRModels, Random, DataFrames
    import ACTRSimulators: start!, press_key!
    using ACTRSimulators: get_rule_set, select_rule, match
    Random.seed!(8985)
    include("task.jl")
    
    parms = (u0=0.0,τu=-1.0)
    
    scheduler = ACTRScheduler(;model_trace=true, store=true)
    task = SimpleTask(;scheduler)
    procedural = Procedural()
    T = vo_to_chunk() |> typeof
    visual_location = VisualLocation(buffer=T[])
    visual = Visual(buffer=T[])
    visicon = VisualObject[]
    motor = Motor()
    memory = [Chunk(;animal=:dog), Chunk(;animal=:cat)]
    declarative = Declarative(;memory)
    actr = ACTR(;scheduler, 
                procedural, 
                visual_location, 
                visual, 
                motor, 
                declarative, 
                visicon,
                parms...)
    
    function can_attend(actr)
        c1(actr) = !isempty(actr.visual_location.buffer)
        c2(actr) = !actr.visual.state.busy
        return c1, c2
    end  
    
    function can_encode(actr)
        c1(actr) = !isempty(actr.visual.buffer)
        c2(actr) = !actr.imaginal.state.busy
        return c1, c2
    end    
    
    function can_respond(actr)
        c1(actr) = !isempty(actr.imaginal.buffer)
        c2(actr) = !actr.motor.state.busy
        return c1, c2
    end   
    
    function attend_action(actr, task)
        buffer = actr.visual_location.buffer
        chunk = deepcopy(buffer[1])
        clear_buffer!(actr.visual_location)
        attending!(actr, chunk)
        return nothing
    end
    
    function encode_action(actr, task)
        buffer = actr.visual.buffer
        chunk = deepcopy(buffer[1])
        clear_buffer!(actr.visual)
        encoding!(actr, chunk)
        return nothing
    end
    
    function motor_action(actr, task)
        buffer = actr.imaginal.buffer
        chunk = deepcopy(buffer[1])
        clear_buffer!(actr.imaginal)
        key = chunk.slots.text
        responding!(actr, task, key)
        return nothing
    end
    
    rule1 = Rule(;conditions=can_attend, action=attend_action, actr, task, name="Attend")
    push!(procedural.rules, rule1)
    
    rule2 = Rule(;conditions=can_encode, action=encode_action, actr, task, name="Encode")
    push!(procedural.rules, rule2)
    
    rule3 = Rule(;conditions=can_respond, action=motor_action, actr, task, name="Respond")
    push!(procedural.rules, rule3)
    
    present_stimulus(task, actr)
    
    rules = get_rule_set(actr)
    
    rule,state = select_rule(actr, rules)
    
    @test state == :match
    @test rule[1] == rule1

    @test actr.parms.utility_decrement == 1.0
    @test actr.parms.threshold_decrement == 1.0
end

@safetestset "no matching production rules" begin 
    using ACTRSimulators, Test, ACTRModels, Random, DataFrames
    import ACTRSimulators: start!, press_key!
    using ACTRSimulators: get_rule_set, select_rule, match
    Random.seed!(8985)
    include("task.jl")
    
    parms = (u0=0.0,τu=-1.0)
    
    scheduler = ACTRScheduler(;model_trace=true, store=true)
    task = SimpleTask(;scheduler)
    procedural = Procedural()
    T = vo_to_chunk() |> typeof
    visual_location = VisualLocation(buffer=T[])
    visual = Visual(buffer=T[])
    visicon = VisualObject[]
    motor = Motor()
    memory = [Chunk(;animal=:dog), Chunk(;animal=:cat)]
    declarative = Declarative(;memory)
    actr = ACTR(;scheduler, 
                procedural, 
                visual_location, 
                visual, 
                motor, 
                declarative, 
                visicon,
                parms...)
    
    function can_attend(actr)
        c1(actr) = !isempty(actr.visual_location.buffer)
        c2(actr) = !actr.visual.state.busy
        return c1, c2
    end  
    
    function can_encode(actr)
        c1(actr) = !isempty(actr.visual.buffer)
        c2(actr) = !actr.imaginal.state.busy
        return c1, c2
    end    
    
    function can_respond(actr)
        c1(actr) = !isempty(actr.imaginal.buffer)
        c2(actr) = !actr.motor.state.busy
        return c1, c2
    end   
    
    function attend_action(actr, task)
        buffer = actr.visual_location.buffer
        chunk = deepcopy(buffer[1])
        clear_buffer!(actr.visual_location)
        attending!(actr, chunk)
        return nothing
    end
    
    function encode_action(actr, task)
        buffer = actr.visual.buffer
        chunk = deepcopy(buffer[1])
        clear_buffer!(actr.visual)
        encoding!(actr, chunk)
        return nothing
    end
    
    function motor_action(actr, task)
        buffer = actr.imaginal.buffer
        chunk = deepcopy(buffer[1])
        clear_buffer!(actr.imaginal)
        key = chunk.slots.text
        responding!(actr, task, key)
        return nothing
    end
    
    rule2 = Rule(;conditions=can_encode, action=encode_action, actr, task, name="Encode")
    push!(procedural.rules, rule2)
    
    rule3 = Rule(;conditions=can_respond, action=motor_action, actr, task, name="Respond")
    push!(procedural.rules, rule3)
    
    present_stimulus(task, actr)
    
    rules = get_rule_set(actr)
    
    rule,state = select_rule(actr, rules)
    
    @test state == :no_matches
    @test isempty(rule)

    @test actr.parms.utility_decrement == 1.0
    @test actr.parms.threshold_decrement == 1.0
end