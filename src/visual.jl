"""
    add_to_visicon!(actr, vo; stuff=false)

Adds a visual object to the visicon. If `stuff` is set to true, the visual object
is added to the visual location buffer. 

# Arguments 

- `actr`: an ACT-R model object
- `vo`: visual object 
- `stuff`: buffer stuffing if true 
"""
function add_to_visicon!(actr::AbstractACTR, vo; stuff=false) 
    push!(actr.visicon, deepcopy(vo))
    if stuff 
       chunk = vo_to_chunk(actr, vo)
       add_to_buffer!(actr.visual_location, chunk)
    end
    return nothing 
end

function add_to_visicon!(models, vo; stuff=false) 
    for model in models 
        add_to_visicon!(model, vo; stuff)
    end
    return nothing 
end

"""
    clear_visicon!(actr)

Clear all visual objects in visicon
"""
function clear_visicon!(visicon)
    empty!(visicon)
end

clear_visicon!(actr::AbstractACTR) = clear_visicon!(actr.visicon)

"""
    remove_visual_object!(actr::AbstractACTR, vo)

Removes object from visicon. 

# Arguments 

- `actr`: an ACT-R model object 
- `vo`: a visual object 
"""
remove_visual_object!(actr::AbstractACTR, vo) = remove_visual_object!(actr.visual_location.visicon, vo)

"""
    remove_visual_object!(visicon, vo)

Removes object from visicon. 

# Arguments 

- `visicon`: a vector of visual objects
- `vo`: a visual object 
"""
function remove_visual_object!(visicon, vo)
    filter!(x->x != vo, visicon)
end

"""
    vo_to_chunk(vo=VisualObject())

# Arguments 

Converts visible object to a chunk with color and text slots.
"""
function vo_to_chunk(vo=VisualObject())
     return Chunk(;color=vo.color, text=vo.text, x=vo.x, y=vo.y)
end

"""
    vo_to_chunk(actr, vo)

Converts visible object to a chunk with color and text slots, and sets time created to current time.

# Arguments 

- `actr`: an ACT-R model object
- `vo`: visual object
"""
function vo_to_chunk(actr, vo)
    time_created = get_time(actr)
    return Chunk(;time_created, color=vo.color, text=vo.text, x=vo.x, y=vo.y)
end

function move_vo!(actr, x, y)
    vo = actr.visicon[1]
    vo.x = x
    vo.y = y
end

"""
    attending!(actr, chunk, args...; kwargs...)

Sets visual module as busy and registers a new event to attend to a `chunk`
created by a visual object

# Arguments 

- `actr`: an ACT-R model object 
- `chunk`: a memory chunk
"""
function attending!(actr, chunk)
    actr.visual.state.busy = true
    description = "Attend"
    type = "model"
    id = get_name(actr)
    tΔ = rnd_time(.085)
    register!(actr, attend!, after, tΔ , actr, chunk; id, description, type)
end

function attending!(actr, chunk, task)
    actr.visual.state.busy = true
    description = "Attend"
    type = "model"
    id = get_name(actr)
    tΔ = rnd_time(.085)
    register!(actr, attend!, after, tΔ , actr, chunk, task; id, description, type)
end

"""
    attend!(actr, chunk, args...; kwargs...)

Completes an attention shift by adding a `chunk` to the visual buffer and setting
states to busy = false and empty = false.

# Arguments 

- `actr`: an ACT-R model object 
- `chunk`: a memory chunk 
"""
function attend!(actr, chunk)
    slots = chunk.slots
    actr.visual.focus = [slots.x,slots.y]
    actr.visual.state.busy = false
    actr.visual.state.empty = false
    add_to_buffer!(actr.visual, chunk)
    return nothing 
end

function attend!(actr, chunk, task)
    slots = chunk.slots
    actr.visual.focus = [slots.x,slots.y]
    actr.visual.state.busy = false
    actr.visual.state.empty = false
    add_to_buffer!(actr.visual, chunk)
    task.visible ? repaint!(task, actr) : nothing
    return nothing 
end