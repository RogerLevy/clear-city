@tool
extends EditorPlugin

func _enter_tree() -> void:
    # Connect to the build signal which triggers when you press Play
    # In Godot 4, you can also use build() virtual function
    pass

# This function is called by the editor when the game starts building/running
func _build() -> bool:
    #var settings = get_editor_interface().get_editor_settings()
    # 0 = disabled, 1 = embedded, 2 = floating
    #if settings.get_setting("run/window_placement/play_window_pip_mode") != 0:
    hide_bottom_panel()
    return true
