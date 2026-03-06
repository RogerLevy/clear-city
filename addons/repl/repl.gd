@tool
extends EditorPlugin

var panel
var output: TextEdit
var input: LineEdit
var editor_interface

func _enter_tree():
    editor_interface = get_editor_interface()
    
    panel = VBoxContainer.new()
    
    output = TextEdit.new()
    output.editable = false
    output.custom_minimum_size = Vector2(400, 300)
    panel.add_child(output)
    
    input = LineEdit.new()
    input.placeholder_text = "Enter GDScript expression..."
    input.text_submitted.connect(_on_command)
    panel.add_child(input)
    
    add_control_to_bottom_panel(panel, "REPL")
    _print("REPL ready...")

func _exit_tree():
    if panel:
        remove_control_from_bottom_panel(panel)
        panel.queue_free()

func _on_command(text: String):
    _print("> " + text)
    
    var parts = text.split(" ", false)
    if parts.size() == 0:
        return
    
    var cmd = parts[0]
    var result
    
    match cmd:
        "list":
            result = _list_nodes(editor_interface.get_edited_scene_root())
        "spawn":
            if parts.size() < 2:
                _print("Usage: spawn scene/path.tscn")
                return
            result = _spawn_scene(parts[1])
        "attach":
            if parts.size() < 3:
                _print("Usage: attach destination/node scene/path.tscn")
                return
            result = _attach_scene(parts[1], parts[2])
        "debug":
            var root = editor_interface.get_edited_scene_root()
            _print("Root: " + root.name)
            _print("Child count: " + str(root.get_child_count()))
            for i in root.get_child_count():
                _print("  Child " + str(i) + ": " + root.get_child(i).name)
            return null			
        _:
            result = _eval(text)
    
    if result != null:
        _print(str(result))
    
    input.clear()

func _eval(code: String):
    var expr = Expression.new()
    var error = expr.parse(code, ["root", "ei", "spawn", "attach"])
    if error != OK:
        _print("Parse error: " + expr.get_error_text())
        return null
    
    var root = editor_interface.get_edited_scene_root()
    var result = expr.execute([
        root, 
        editor_interface, 
        Callable(self, "_spawn_scene"),
        Callable(self, "_attach_scene")
    ], self)
    if expr.has_execute_failed():
        _print("Execute failed!")
        _print("Error text: " + expr.get_error_text())
        return null
    return result

func _attach_scene(node_path: String, scene_path: String):
    if not scene_path.begins_with("res://"):
        scene_path = "res://" + scene_path
    
    var root = editor_interface.get_edited_scene_root()
    _print("Root: " + str(root))
    _print("Looking for: " + node_path)
    
    var parent = root.get_node_or_null(node_path)
    if not parent:
        return "Node not found: " + node_path
    
    _print("Found parent: " + str(parent))
    
    var scene = load(scene_path)
    if not scene:
        return "Failed to load: " + scene_path
    
    var instance = scene.instantiate()
    parent.add_child(instance)
    instance.owner = root
    return "Attached to " + node_path + ": " + scene_path

func _spawn_scene(path: String):
    if not path.begins_with("res://"):
        path = "res://" + path
    
    var scene = load(path)
    if not scene:
        return "Failed to load: " + path
    var instance = scene.instantiate()
    var root = editor_interface.get_edited_scene_root()
    if root:
        root.add_child(instance)
        instance.owner = root
        return "Spawned: " + path
    return "No root scene"

func _print(text: String):
    output.text += text + "\n"
    output.scroll_vertical = output.get_line_count()

func _list_nodes(node: Node, indent: String = ""):
    _print(indent + node.name + " (" + node.get_class() + ")")
    for child in node.get_children():
        _list_nodes(child, indent + "  ")
    return null
