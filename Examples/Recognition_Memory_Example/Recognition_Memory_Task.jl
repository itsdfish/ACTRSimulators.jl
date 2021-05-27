"""
** Task **

- `n_trials`: number of trials
- `trial`: current trial
- `width`: screen width
- `height`: screen height
- `scheduler`: event scheduler
- `screen`: visual objects on screen
- `canvas`: GTK canvas
- `window`: GTK window
- `visible`: GUI visible
- `speed`: real time speed
- `study_words`: words presented in study phase
- `test_words`: words presented in study phase

Function Signature 

````julia
Task(;n_trials=10, trial=1, lb=2.0, ub=10.0, width=600.0, height=600.0, scheduler=nothing, 
    screen=Vector{VisualObject}(), window=nothing, canvas=nothing, visible=false, speed=1.0)
````
"""
@concrete mutable struct Task <: AbstractTask 
    study_trial::Int
    test_trial::Int 
    width::Float64
    hight::Float64
    scheduler
    screen::Vector{VisualObject}
    canvas
    window
    visible::Bool
    realtime::Bool
    speed::Float64
    press_key!
    start!
    study_words
    test_words
    data
end

function Task(;
    study_trial = 1, 
    test_trial = 1, 
    width = 600.0, 
    height = 600.0, 
    scheduler = nothing, 
    screen = Vector{VisualObject}(), 
    window = nothing, 
    canvas = nothing, 
    visible = false, 
    realtime = false,
    speed = 1.0,
    press_key = press_key!,
    start! = start!,
    study_words = String[],
    test_words = String[],
    data= nothing
    )
    visible ? ((canvas,window) = setup_window(width)) : nothing
    visible ? Gtk.showall(window) : nothing
    return Task(study_trial, test_trial, width, height, scheduler, screen, canvas, window, visible,
        realtime, speed, press_key!, start!, study_words, test_words, data)
end

function setup_window(width)
	canvas = @GtkCanvas()
    window = GtkWindow(canvas, "Experiment", width, width)
    Gtk.visible(window, true)
    @guarded draw(canvas) do widget
        ctx = getgc(canvas)
        rectangle(ctx, 0.0, 0.0, width, width)
        set_source_rgb(ctx, .8, .8, .8)
        fill(ctx)
    end
	return canvas,window
end

function draw_object!(task, word)
    c = task.canvas
    w = task.width
	x = w/2
	y = w/2
    @guarded draw(c) do widget
        ctx = getgc(c)
        select_font_face(ctx, "Arial", Cairo.FONT_SLANT_NORMAL,
             Cairo.FONT_WEIGHT_BOLD);
        set_font_size(ctx, 36)
        set_source_rgb(ctx, 0, 0, 0)
        extents = text_extents(ctx, word)
        x′ = x - (extents[3]/2 + extents[1])
        y′ = y - (extents[4]/2 + extents[2])
        move_to(ctx, x′, y′)
        show_text(ctx, word)
    end
    Gtk.showall(c)
    return nothing
end

function clear!(task)
    c = task.canvas
    w = task.width
    @guarded draw(c) do widget
        ctx = getgc(c)
        rectangle(ctx, 0, 0, w, w)
        set_source_rgb(ctx, .8, .8, .8)
        fill(ctx)
    end
    Gtk.showall(c)
    return nothing
end

function start!(task::Task, actr)
    sort!(task.study_words)
    sort!(task.test_words)
    study_trial!(task, actr)
end

function present_stimulus(task, actr, word)
    vo = VisualObject(;text=word)
    add_to_visicon!(actr, vo; stuff=true)
    push!(task.screen, vo)
    task.visible ? draw_object!(task, word) : nothing
    register!(task, clear!, after, 1.0, task)
    register!(task, update_task!, after, 1.0, task, actr)
end

function study_trial!(task, actr)
    @unpack study_words,study_trial = task
    isi = .5
    description = "present stimulus"
    word = study_words[study_trial].word
    register!(task, present_stimulus, after, isi, task, actr, word;
        description)
end

function update_task!(task, actr)
    if task.study_trial < length(task.study_words)
        task.study_trial += 1
        study_trial!(task, actr)
    elseif task.test_trial < length(task.test_words)
        task.test_trial += 1


        stop!(task.scheduler)

        
    else
        stop!(task.scheduler)
    end
end

function press_key!(task::Task, actr, key)
    empty!(task.screen)
    task.visible ? clear!(task) : nothing
    update_task!(task, actr)
end

function populate_lists()
    study_words = [
        (word="chair",type="target"),
        (word="duck",type="target"),
        (word="book",type="target"),
        (word="pan",type="target"),
        (word="phone",type="target"),
        (word="shirt",type="target"),
        (word="tree",type="target")
    ]
    test_words = [
        (word="chair",type="target"),
        (word="duck",type="target"),
        (word="book",type="target"),
        (word="pan",type="target"),
        (word="phone",type="target"),
        (word="shirt",type="target"),
        (word="tree",type="target"),

        (word="rug",type="target"),
        (word="car",type="target"),
        (word="pool",type="target"),
        (word="lump",type="target"),
        (word="hair",type="target"),
        (word="face",type="target"),
        (word="ape",type="target")
    ]
    stimuli = (study_words=study_words, test_words=test_words)
    return stimuli
end