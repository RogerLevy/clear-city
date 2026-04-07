@tool
extends EditorPlugin

var dock: Control
var tree: Tree
var up_button: Button
var down_button: Button
var selected_sequence: Node
var editor_selection: EditorSelection
var _ignoring_selection: bool = false

func _enter_tree():
    dock = preload("res://addons/sequence_editor/sequence_editor_dock.tscn").instantiate()
    tree = dock.get_node("Tree")
    tree.set_column_title(0, "Name")
    tree.set_column_title(1, "Dur")
    tree.set_column_title(2, "Start")
    tree.set_column_expand(0, true)
    tree.set_column_expand(1, false)
    tree.set_column_custom_minimum_width(1, 50)
    tree.set_column_expand(2, false)
    tree.set_column_custom_minimum_width(2, 50)
    tree.item_edited.connect(_on_item_edited)
    tree.item_selected.connect(_on_item_selected)
    tree.item_activated.connect(_on_item_activated)
    up_button = dock.get_node("Buttons/UpButton")
    down_button = dock.get_node("Buttons/DownButton")
    var base_control = get_editor_interface().get_base_control()
    up_button.icon = base_control.get_theme_icon("MoveUp", "EditorIcons")
    up_button.text = ""
    down_button.icon = base_control.get_theme_icon("MoveDown", "EditorIcons")
    down_button.text = ""
    up_button.pressed.connect(_on_up_pressed)
    down_button.pressed.connect(_on_down_pressed)
    add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)

    editor_selection = get_editor_interface().get_selection()
    editor_selection.selection_changed.connect(_on_selection_changed)

func _exit_tree():
    remove_control_from_docks(dock)
    dock.queue_free()

func _on_selection_changed():
    if _ignoring_selection:
        _ignoring_selection = false
        return
    var selected = editor_selection.get_selected_nodes()
    if selected.size() == 1 and selected[0].get_script():
        var node = selected[0]
        # Check if it's a Sequence (by class name or script)
        if _is_sequence(node):
            selected_sequence = node
            _rebuild_tree()
            return
    selected_sequence = null
    _rebuild_tree()

func _is_sequence(node: Node) -> bool:
    if not node:
        return false
    var script = node.get_script()
    if not script:
        return false
    # Walk up the inheritance chain
    while script:
        if script.get_global_name() == "Sequence":
            return true
        script = script.get_base_script()
    return false

func _rebuild_tree():
    tree.clear()
    if not selected_sequence:
        return

    var root = tree.create_item()
    _setup_sequence_item(root, selected_sequence)

    for child in selected_sequence.get_children():
        if _is_sequence(child):
            var item = tree.create_item(root)
            _setup_sequence_item(item, child)

func _setup_sequence_item(item: TreeItem, node: Node):
    item.set_text(0, node.name)
    item.set_editable(0, false)
    item.set_metadata(0, node)

    # Duration column - editable
    var duration = node.get("duration") if node.get("duration") != null else -1
    var duration_text = str(duration) if duration >= 0 else "-1"
    item.set_text(1, duration_text)
    item.set_editable(1, true)

    # Start mode - show as short text
    var start_mode = node.get("start_mode") if node.get("start_mode") != null else 0
    var mode_labels = ["", "IMM", "PAR", "NOD", "SIG"]
    item.set_text(2, mode_labels[start_mode] if start_mode < mode_labels.size() else "")
    item.set_editable(2, false)

func _on_item_edited():
    var item = tree.get_edited()
    var column = tree.get_edited_column()
    var node = item.get_metadata(0) as Node
    if not node:
        return

    if column == 1:  # Duration
        var new_duration = float(item.get_text(1))
        node.set("duration", new_duration)
        get_editor_interface().mark_scene_as_unsaved()

func _on_up_pressed():
    if not selected_sequence:
        return
    var parent = selected_sequence.get_parent()
    if parent and _is_sequence(parent):
        selected_sequence = parent
        _ignoring_selection = true
        editor_selection.clear()
        editor_selection.add_node(parent)
        _rebuild_tree()

func _on_down_pressed():
    var item = tree.get_selected()
    if not item:
        return
    var node = item.get_metadata(0)
    if node and node != selected_sequence and _is_sequence(node):
        selected_sequence = node
        _ignoring_selection = true
        editor_selection.clear()
        editor_selection.add_node(node)
        _rebuild_tree()

func _on_item_selected():
    var item = tree.get_selected()
    if item:
        var node = item.get_metadata(0)
        if node and node != selected_sequence:
            _ignoring_selection = true
            editor_selection.clear()
            editor_selection.add_node(node)

func _on_item_activated():
    var item = tree.get_selected()
    if not item:
        return
    var node = item.get_metadata(0)
    if node and _is_sequence(node):
        selected_sequence = node
        _ignoring_selection = true
        editor_selection.clear()
        editor_selection.add_node(node)
        _rebuild_tree()
