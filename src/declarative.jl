"""
    retrieving!(actr, chunk, args...; kwargs...)

Sets the declarative memory module as busy and Submits a request for a chunk and registers 
a new event for the retrieval

# Arguments 

- `actr`: an ACT-R model object 
- `request...`: a variable list of slot-value pairs
"""
function retrieving!(actr; request...)
    actr.declarative.state.busy = true
    description = "Retrieve"
    type = "model"
    id = get_name(actr)
    cur_time = get_time(actr)
    chunk = retrieve(actr, cur_time; request...)
    tΔ = compute_RT(actr, chunk)
    register!(actr, retrieve!, after, tΔ, actr, chunk; id, description, type)
    return tΔ
end

"""
    retrieve!(actr, chunk, args...; kwargs...)

Completes a memory retrieval by adding chunk to declarative memory buffer and setting
busy = false and empty = false. Error is set to true if retrieval failure occurs.

# Arguments 

- `actr`: an ACT-R model object 
- `request...`: a variable list of slot-value pairs
"""
function retrieve!(actr, chunk)
    actr.declarative.state.busy = false
    if isempty(chunk)
        actr.declarative.state.error = true
    else
        actr.declarative.state.empty = false
        add_to_buffer!(actr.declarative, chunk[1])
    end
    return nothing
end
