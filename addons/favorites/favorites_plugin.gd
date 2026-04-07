@tool
extends EditorPlugin

const FAVORITE_META = "_favorite"

var dock: Control
var favorites_list: ItemList
var selection: EditorSelection

func _enter_tree():
    dock = preload("res://addons/favorites/favorites_dock.tscn").instantiate()
    add_control_to_dock(DOCK_SLOT_LEFT_BR, dock)

    favorites_list = dock.get_node("VBox/ItemList")
    favorites_list.item_selected.connect(_on_item_selected)

    dock.get_node("VBox/HBox/ToggleButton").pressed.connect(_toggle_favorite)
    dock.get_node("VBox/HBox/RefreshButton").pressed.connect(_scan_favorites)

    selection = get_editor_interface().get_selection()
    selection.selection_changed.connect(_on_selection_changed)

    get_editor_interface().get_resource_filesystem().filesystem_changed.connect(_scan_favorites)
    scene_changed.connect(_on_scene_changed)

    call_deferred("_scan_favorites")

func _exit_tree():
    if dock:
        remove_control_from_docks(dock)
        dock.queue_free()

func _on_scene_changed(_root: Node):
    _scan_favorites()

func _on_selection_changed():
    _update_toggle_button()

func _update_toggle_button():
    var btn = dock.get_node("VBox/HBox/ToggleButton")
    var selected = selection.get_selected_nodes()
    if selected.is_empty():
        btn.text = "Toggle Favorite"
        btn.disabled = true
    else:
        var node = selected[0]
        var is_fav = node.has_meta(FAVORITE_META)
        btn.text = "Unfavorite" if is_fav else "Favorite"
        btn.disabled = false

func _toggle_favorite():
    var selected = selection.get_selected_nodes()
    if selected.is_empty():
        return

    var node = selected[0]
    if node.has_meta(FAVORITE_META):
        node.remove_meta(FAVORITE_META)
    else:
        node.set_meta(FAVORITE_META, true)

    _mark_scene_modified()
    _scan_favorites()
    _update_toggle_button()

func _mark_scene_modified():
    var root = get_editor_interface().get_edited_scene_root()
    if root:
        # Mark scene as modified so it prompts to save
        get_editor_interface().mark_scene_as_unsaved()

func _scan_favorites():
    favorites_list.clear()
    var root = get_editor_interface().get_edited_scene_root()
    if not root:
        return
    _scan_recursive(root, root)

func _scan_recursive(node: Node, root: Node):
    if node.has_meta(FAVORITE_META):
        var path = root.get_path_to(node)
        var icon = _get_node_icon(node)
        favorites_list.add_item(node.name, icon)
        favorites_list.set_item_metadata(favorites_list.item_count - 1, path)
        favorites_list.set_item_tooltip(favorites_list.item_count - 1, str(path))
    for child in node.get_children():
        _scan_recursive(child, root)

func _get_node_icon(node: Node) -> Texture2D:
    var base = get_editor_interface().get_base_control()
    # Try script's custom icon first, then class icon
    var script = node.get_script()
    if script and script.get_class() == "GDScript":
        var icon_path = script.get_instance_base_type()
        if icon_path:
            return base.get_theme_icon(icon_path, "EditorIcons")
    # Fall back to node's class
    var node_class = node.get_class()
    return base.get_theme_icon(node_class, "EditorIcons")

func _on_item_selected(index: int):
    var path: NodePath = favorites_list.get_item_metadata(index)
    var root = get_editor_interface().get_edited_scene_root()
    if not root:
        return
    var node = root.get_node_or_null(path)
    if node:
        selection.clear()
        selection.add_node(node)
