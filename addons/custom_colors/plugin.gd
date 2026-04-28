@tool
extends EditorPlugin

func _enter_tree():
	call_deferred("_apply_custom_colors")

func _apply_custom_colors():
	var theme = EditorInterface.get_editor_theme()
	# Color used for inherited/editable children nodes in scene tree
	theme.set_color("warning_color", "Editor", Color.CYAN)
