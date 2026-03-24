@tool
extends EditorPlugin

var panel: Control

func _enter_tree():
	panel = preload("res://addons/actor_factory/factory_panel.tscn").instantiate()
	panel.editor_interface = get_editor_interface()
	add_control_to_dock(DOCK_SLOT_LEFT_BR, panel)

func _exit_tree():
	remove_control_from_docks(panel)
	panel.queue_free()
