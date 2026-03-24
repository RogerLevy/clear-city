@tool
extends EditorPlugin

var menu_button: Button

func _enter_tree():
	menu_button = Button.new()
	menu_button.text = "Make Unique"
	menu_button.tooltip_text = "Make all animations in this AnimationPlayer unique"
	menu_button.pressed.connect(_on_make_unique_pressed)
	menu_button.visible = false
	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, menu_button)

func _exit_tree():
	if menu_button:
		remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, menu_button)
		menu_button.queue_free()

func _handles(object: Object) -> bool:
	return object is AnimationPlayer

func _edit(object: Object):
	menu_button.visible = object is AnimationPlayer

func _make_visible(visible: bool):
	menu_button.visible = visible

func _on_make_unique_pressed():
	var selection = get_editor_interface().get_selection()
	var selected = selection.get_selected_nodes()

	for node in selected:
		if node is AnimationPlayer:
			_make_unique(node)

func _make_unique(player: AnimationPlayer):
	var lib_names = player.get_animation_library_list()
	for lib_name in lib_names:
		var old_lib = player.get_animation_library(lib_name)
		var new_lib = AnimationLibrary.new()

		for anim_name in old_lib.get_animation_list():
			var old_anim = old_lib.get_animation(anim_name)
			var new_anim = old_anim.duplicate()
			new_lib.add_animation(anim_name, new_anim)

		player.remove_animation_library(lib_name)
		player.add_animation_library(lib_name, new_lib)

	print("Made animations unique: ", player.name)
