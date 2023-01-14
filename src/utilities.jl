
function register!(actr::AbstractACTR, fun, when::Now, args...; id="", type="", description="", kwargs...)
    scheduler = actr.scheduler
    register!(scheduler, fun, scheduler.time, args...; id, type, description, kwargs...)
end

function register!(actr::AbstractACTR, fun, when::At, t, args...; id="", type="", description="", kwargs...)
    scheduler = actr.scheduler
    register!(scheduler, fun, t, args...; id, type, description, kwargs...)
end

function register!(actr::AbstractACTR, fun, when::After, t, args...; id="", type="", description="", kwargs...)
    scheduler = actr.scheduler
    register!(scheduler, fun, scheduler.time + t, args...; id, type, description, kwargs...)
end

function register!(actr::AbstractACTR, fun, when::Every, t, args...; id="", type="", description="", kwargs...)
    scheduler = actr.scheduler
    function f(args...; kwargs...) 
        fun1 = () -> fun(args...; kwargs...)
        fun1()
        register!(scheduler, fun, every, t, args...; id, type, description, kwargs...)
    end
    register!(scheduler, f, after, t, args...; id, type, description, kwargs...)
end

function register!(task::AbstractTask, fun, when::Now, args...; id="", type="", description="", kwargs...)
    scheduler = task.scheduler
    register!(scheduler, fun, scheduler.time, args...; id, type, description, kwargs...)
end

function register!(task::AbstractTask, fun, when::At, t, args...; id="", type="", description="", kwargs...)
    scheduler = task.scheduler
    register!(scheduler, fun, t, args...; id, type, description, kwargs...)
end

function register!(task::AbstractTask, fun, when::After, t, args...; id="", type="", description="", kwargs...)
    scheduler = task.scheduler
    register!(scheduler, fun, scheduler.time + t, args...; id, type, description, kwargs...)
end

function register!(task::AbstractTask, fun, when::Every, t, args...; id="", type="", description="", kwargs...)
    scheduler = task.scheduler
    function f(args...; kwargs...) 
        fun1 = () -> fun(args...; kwargs...)
        fun1()
        register!(scheduler, fun, every, t, args...; id, type, description, kwargs...)
    end
    register!(scheduler, f, after, t, args...; id, type, description, kwargs...)
end

function import_gui()
    path = pathof(ACTRSimulators) |> dirname |> x->joinpath(x, "")
    include(path * "GUI.jl")
end

function press_key!(task, actr, key)
    @error "A method must be defined for press_key! in the form of 
    press_key!(task, actr, key)"
end

function start!(task, actr)
    @error "A method must be defined for start! in the form of 
    start!(task, actr)" 
end

"""
    why_not(actr, rule)

Prints each condition of a production rule and whether it matches the state of the 
architecture. 

# Arguments

- `actr`: an ACT-R model object 
- `rule`: a production rule object 
"""
function why_not(actr, rule)
    str = rule.name * "\n"
    for c in rule.conditions
         str *= @code_string c(actr) 
         str *= string(" ", c(actr))
         str *= "\n"
    end
    println(str)
    return nothing
end

"""
    why_not(actr)

Prints each condition of all production rules and whether the condition matche the state of the 
architecture. 

# Arguments

- `actr`: an ACT-R model object 
"""
function why_not(actr)
    return why_not.(actr, get_rules(actr))
end