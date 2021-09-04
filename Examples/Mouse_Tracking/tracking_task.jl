import ACTRSimulators: draw_object!
"""
** Tracking **

- `width`: screen width
- `height`: screen height
- `scheduler`: event scheduler
- `screen`: visual objects on screen
- `canvas`: GTK canvas
- `window`: GTK window
- `visible`: GUI visible
- `speed`: real time speed

Function Signature 

````julia
PVT(;n_trials=10, trial=1, lb=2.0, ub=10.0, width=600.0, height=600.0, scheduler=nothing, 
    screen=Vector{VisualObject}(), window=nothing, canvas=nothing, visible=false, speed=1.0)
````
"""
@concrete mutable struct Tracking <: AbstractTask 
    width::Float64
    height::Float64
    scheduler
    screen::Vector{VisualObject}
    canvas
    window
    dot
    cursor
    visible::Bool
    realtime::Bool
    speed::Float64
    Δθ::Float64
    λθ::Float64
    press_key!
    start!
    repaint!
end

function Tracking(;
    width = 600.0, 
    height = 600.0, 
    scheduler = nothing, 
    screen = Vector{VisualObject}(), 
    window = nothing, 
    canvas = nothing, 
    dot = Dot(;width, height),
    cursor = Cursor(),
    visible = false, 
    realtime = false,
    speed = 1.0,
    press_key = press_key!,
    start! = start!,
    repaint! = repaint!,
    λθ = .01,
    revs_per_sec = 10,
    Δθ = (2 * π) * λθ * (1 / revs_per_sec)
    )
    visible ? ((canvas,window) = setup_window(width)) : nothing
    visible ? Gtk.showall(window) : nothing
    return Tracking(
        width,
        height,
        scheduler,
        screen,
        canvas,
        window,
        dot,
        cursor,
        visible,
        realtime, 
        speed, 
        Δθ,
        λθ,
        press_key!, 
        start!,
        repaint!
    )
end

mutable struct Dot
    x::Float64
    y::Float64
    c_x::Float64
    c_y::Float64
    r::Float64
    θ::Float64
end

function Dot(;
    width,
    height,
    r = (width + height) / 8,
    θ = rand(Uniform(0, 2 * π))
    )
    c_x = width / 2
    c_y = height / 2
    x,y = compute_position(c_x, c_y, r, θ)
    Dot(x, y, c_x, c_y, r, θ)
end

function compute_position!(dot)
    x,y = compute_position(dot.c_x, dot.c_y, dot.r, dot.θ)
    dot.x = x
    dot.y = y
end

compute_position(dot) = compute_position(dot.c_x, dot.c_y, dot.r, dot.θ)

function compute_position(c_x, c_y, r, θ)
    x = c_x + r * cos(θ)
    y = c_y + r * sin(θ)
    return x, y
end

function get_position(dot)
    return dot.x, dot.y 
end

function update_angle!(dot, Δθ)
    dot.θ = mod(dot.θ + Δθ, 2 * π)
end

function update_dot!(task, actr)
    update_angle!(task.dot, task.Δθ)
    compute_position!(task.dot)
end

function update_vo!(actr, task)
    x,y = get_position(task.dot)
    move_vo!(actr, x, y)
end

function move_dot!(actr, task)
    update_dot!(task, actr)
    update_vo!(actr, task)
    repaint!(task, actr)
end

mutable struct Cursor
    x::Float64
    y::Float64
end

Cursor(;x=0.0, y=0.0) = Cursor(x, y)

function draw_object!(task, dot::Dot)
    draw_object!(task, "O", dot.x, dot.y)
end

function start!(task::Tracking, actr)
    x,y = compute_position(task.dot)
    present_stimulus(task, actr, task.dot)
    run_trial!(task, actr)
end

function present_stimulus(task, actr, dot)
    vo = VisualObject(;x = dot.x, y = dot.y)
    add_to_visicon!(actr, vo; stuff=true)
    push!(task.screen, vo)
    task.visible ? task.repaint!(task, actr) : nothing
end

function run_trial!(task, actr)
    λ = task.λθ
    register!(task, move_dot!, every, λ, actr, task)
end

function press_key!(task::Tracking, actr, key)
    println("press_key not implimented")
end

function repaint!(task::Tracking, actr)
    clear!(task)
    draw_object!(task, task.dot)
    draw_attention!(task, actr) 
end