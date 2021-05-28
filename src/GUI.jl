
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
