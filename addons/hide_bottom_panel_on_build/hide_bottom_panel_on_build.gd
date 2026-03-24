@tool
extends EditorPlugin

func _enter_tree() -> void:
    # Connect to the build signal which triggers when you press Play
    # In Godot 4, you can also use build() virtual function
    pass

# This function is called by the editor when the game starts building/running
func _build() -> bool:
    var settings = get_editor_interface().get_editor_settings()
    # 0 = disabled, 1 = embedded, 2 = floating
    var pip_mode = settings.get_setting("run/window_placement/play_window_pip_mode")
    # Check if project window mode would prevent embedding (fullscreen modes)
    var window_mode = ProjectSettings.get_setting("display/window/size/mode")
    # 0 = windowed, 1 = minimized, 2 = maximized, 3 = fullscreen, 4 = exclusive fullscreen
    var is_fullscreen = window_mode >= 3
    if pip_mode != 0 and not is_fullscreen:
        hide_bottom_panel()
    return true
