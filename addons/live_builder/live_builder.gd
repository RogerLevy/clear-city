@tool
extends EditorPlugin

var panel

func _enter_tree():
    print("Live Builder enabled")
    panel = preload("res://addons/live_builder/live_builder_control.tscn").instantiate()
    add_control_to_bottom_panel(panel, "Live Builder")

func _exit_tree():
    if panel:
        remove_control_from_bottom_panel(panel)
        panel.queue_free()
