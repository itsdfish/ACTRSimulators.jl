
#https://developer.gnome.org/pygtk/stable/class-gtkwidget.html#method-gtkwidget--get-allocation
#https://github.com/JuliaGraphics/Gtk.jl/blob/543a4f13eabf6b62edb0c11c51a715219be37629/src/base.jl

@reexport using Gtk, Cairo
"""
    clear!(task)   

Clears all stimuli from window. 
"""
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

setup_window(width::Float64, name="") = setup_window(width, width, name)

"""
    setup_window(width::Float64, height::Float64, name="")

Generate a blank window.
"""
function setup_window(width::Float64, height::Float64, name="")
    canvas = @GtkCanvas()
    window = GtkWindow(canvas, name, width, height)
    Gtk.visible(window, true)
    @guarded draw(canvas) do widget
        ctx = getgc(canvas)
        rectangle(ctx, 0.0, 0.0, width, width)
        set_source_rgb(ctx, .8, .8, .8)
        fill(ctx)
    end
    return canvas,window
end

function draw_attention!(task, actr) 
    focus = actr.visual.focus
    draw_attention!(task, focus...)
end

function draw_attention!(task, x, y)
    c = task.canvas
    @guarded draw(c) do widget
        ctx = getgc(c)
        arc(ctx, x, y, 20, 0, 2π)
        set_source_rgba(ctx, .933, .956, .443, .6)
        fill(ctx)
    end
    Gtk.showall(c)
    return nothing
end

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