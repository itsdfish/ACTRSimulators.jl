module GtkExt

#https://developer.gnome.org/pygtk/stable/class-gtkwidget.html#method-gtkwidget--get-allocation
#https://github.com/JuliaGraphics/Gtk.jl/blob/543a4f13eabf6b62edb0c11c51a715219be37629/src/base.jl
using ACTRSimulators
using Cairo
using Gtk

import ACTRSimulators: clear! 
import ACTRSimulators: draw_attention!
import ACTRSimulators: draw_object!
import ACTRSimulators: repaint!
import ACTRSimulators: setup_window

"""
    clear!(task::AbstractTask)   

Clears all stimuli from window. 

# Arguments

- `task::AbstractTask`: a task object
"""
function clear!(task::AbstractTask)
    c = task.canvas
    w = task.width
    @guarded draw(c) do widget
        ctx = getgc(c)
        rectangle(ctx, 0, 0, w, w)
        set_source_rgb(ctx, 0.8, 0.8, 0.8)
        fill(ctx)
    end
    Gtk.showall(c)
    return nothing
end

setup_window(width::Float64, name = "") = setup_window(width, width, name)

"""
    setup_window(width::Float64, height::Float64, name="")

Generate a blank window.

# Arguments

- `width`: width of window 
- `height`: height of window
- `name=""`: name of window to appear on upper tab
"""
function setup_window(width::Float64, height::Float64, name = "")
    canvas = @GtkCanvas()
    window = GtkWindow(canvas, name, width, height)
    Gtk.visible(window, true)
    @guarded draw(canvas) do widget
        ctx = getgc(canvas)
        rectangle(ctx, 0.0, 0.0, width, width)
        set_source_rgb(ctx, 0.8, 0.8, 0.8)
        fill(ctx)
    end
    return canvas, window
end

"""
    draw_attention!(task, actr) 

Draws a yellow circle to represent visual attention

# Arguments

- `task`: a task object <: AbstractTask
- `model`: an ACT-R model object
"""
function draw_attention!(task, actr)
    focus = actr.visual.focus
    draw_attention!(task, focus...)
end

"""
    draw_attention!(task, actr) 

Draws a yellow circle to represent visual attention

# Arguments

- `task`: a task object <: AbstractTask
- `x`: x coordinate of visual attention
- `y`: y coordinate of visual attention
"""
function draw_attention!(task, x, y)
    c = task.canvas
    @guarded draw(c) do widget
        ctx = getgc(c)
        arc(ctx, x, y, 20, 0, 2π)
        set_source_rgba(ctx, 0.933, 0.956, 0.443, 0.6)
        fill(ctx)
    end
    Gtk.showall(c)
    return nothing
end

"""
    draw_object!(task, object, x, y) 

Draws an object in the window specified at `task.canvas`. The 
coordinates of the object are the upper left point of the object

# Arguments

- `task`: a task object <: AbstractTask
- `object`: object to be drawn
- `x`: x coordinate of visual attention
- `y`: y coordinate of visual attention
"""
function draw_object!(task, object, x, y)
    c = task.canvas
    @guarded draw(c) do widget
        ctx = getgc(c)
        select_font_face(ctx, "Arial", Cairo.FONT_SLANT_NORMAL,
            Cairo.FONT_WEIGHT_BOLD);
        set_font_size(ctx, 36)
        set_source_rgb(ctx, 0, 0, 0)
        extents = text_extents(ctx, object)
        x′ = x - (extents[3]/2 + extents[1])
        y′ = y - (extents[4]/2 + extents[2])
        move_to(ctx, x′, y′)
        show_text(ctx, object)
    end
    Gtk.showall(c)
    return nothing
end

function repaint!(task::AbstractTask, actr)
    draw_attention!(task, actr)
end
end
