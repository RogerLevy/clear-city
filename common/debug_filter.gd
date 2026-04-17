extends Node

func _enter_tree() -> void:    
    get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
    if node == self: return

    var should_kill: bool = false

    if OS.has_feature("editor"):
        # If we are in the editor, we ONLY kill export_only nodes.
        should_kill = node.is_in_group("export_only")
    else:
        # If we are in a final export, we ONLY kill editor_only nodes.
        should_kill = node.is_in_group("editor_only")

    # Kill debug_only nodes if not in a debug build    
    if not OS.is_debug_build() and node.is_in_group("debug_only"):
        should_kill = true

    if should_kill:
        _vaporize(node)

func _vaporize(node: Node) -> void:
    # Use call_deferred for the print to ensure we see it clearly in the logs
    print("CLEANER: Nuked node [", node.name, "]")
    
    node.set_script(null)
    node.process_mode = PROCESS_MODE_DISABLED
    node.queue_free()
