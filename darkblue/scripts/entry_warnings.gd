class_name EntryWarnings
extends Node2D

const CLUSTER_DISTANCE := 32.0
const EntryArrowScene = preload("res://darkblue/effects/entry_arrow.tscn")
static var edge_offset := 11.0  ## Distance from screen edge to arrow

var _arrows: Array[EntryArrow] = []
var _entry_data: Array[Dictionary] = []  # { vessel, position, edge }

func _ready():
    var parent = get_parent()
    if parent is Sequence:
        parent.sequence_started.connect(_on_sequence_started)

func _on_sequence_started():
    _scan_for_entries()
    _spawn_arrows()

func _scan_for_entries():
    _entry_data.clear()
    var parent = get_parent()

    # Find all enemies in this sequence's descendants
    for vessel in _find_enemies(parent):
        var entry = _detect_entry_point(vessel)
        if not entry.is_empty():
            entry["vessel"] = vessel
            _entry_data.append(entry)

    # Find BurstSequences that spawn enemies from off-screen
    for burst in _find_burst_sequences(parent):
        var entry = _detect_burst_entry(burst)
        if not entry.is_empty():
            entry["vessel"] = burst
            _entry_data.append(entry)

func _find_enemies(node: Node) -> Array[Node]:
    var result: Array[Node] = []
    for child in node.get_children():
        if child.is_in_group("enemies"):
            result.append(child)
        result.append_array(_find_enemies(child))
    return result

func _detect_entry_point(vessel: Node2D) -> Dictionary:
    # Try path-based detection first
    var path_entry = _find_path_entry(vessel)
    if not path_entry.is_empty():
        return path_entry

    # Fall back to direct position detection
    return _find_direct_entry(vessel)

func _find_path_entry(vessel: Node2D) -> Dictionary:
    var parent = get_parent()

    # Check for PathMotion targeting this vessel
    for pm in _find_path_motions(parent):
        if pm.target == vessel:
            var path: Path2D = null
            for child in pm.get_children():
                if child is Path2D:
                    path = child
                    break
            if path and path.curve and path.curve.point_count >= 2:
                var global_pos = path.to_global(path.curve.sample_baked(0))
                var screen = Vector2(get_tree().root.content_scale_size)
                if global_pos.x < 0 or global_pos.x > screen.x or global_pos.y < 0 or global_pos.y > screen.y:
                    return { "position": _clamp_to_edge(global_pos), "edge": _pos_to_edge(global_pos) }

    # Fallback: Search for RemoteTransform2D + PathFollow2D
    for rt in _find_remote_transforms(parent):
        if rt.remote_path.is_empty():
            continue
        var target = rt.get_node_or_null(rt.remote_path)
        if target == vessel:
            var path_follow = rt.get_parent() as PathFollow2D
            if path_follow:
                var global_pos = path_follow.global_position
                var screen = Vector2(get_tree().root.content_scale_size)
                if global_pos.x < 0 or global_pos.x > screen.x or global_pos.y < 0 or global_pos.y > screen.y:
                    return { "position": _clamp_to_edge(global_pos), "edge": _pos_to_edge(global_pos) }
    return {}

func _clamp_to_edge(pos: Vector2) -> Vector2:
    var screen = Vector2(get_tree().root.content_scale_size)
    return Vector2(clampf(pos.x, 0, screen.x), clampf(pos.y, 0, screen.y))

func _find_remote_transforms(node: Node) -> Array[RemoteTransform2D]:
    var result: Array[RemoteTransform2D] = []
    for child in node.get_children():
        if child is RemoteTransform2D:
            result.append(child)
        result.append_array(_find_remote_transforms(child))
    return result

func _find_path_motions(node: Node) -> Array[PathMotion]:
    var result: Array[PathMotion] = []
    for child in node.get_children():
        if child is PathMotion:
            result.append(child)
        result.append_array(_find_path_motions(child))
    return result

func _find_burst_sequences(node: Node) -> Array[BurstSequence]:
    var result: Array[BurstSequence] = []
    for child in node.get_children():
        if child is BurstSequence:
            # Skip bursts that are children of enemies (they move with the enemy)
            if not _has_enemy_ancestor(child):
                # Check if it spawns enemies
                if _burst_spawns_enemies(child):
                    result.append(child)
        result.append_array(_find_burst_sequences(child))
    return result

func _has_enemy_ancestor(node: Node) -> bool:
    var parent = node.get_parent()
    while parent:
        if parent.is_in_group("enemies") or parent is Vessel2D:
            return true
        if parent is Sequence:
            return false  # Stop at sequence boundary
        parent = parent.get_parent()
    return false

func _burst_spawns_enemies(burst: BurstSequence) -> bool:
    if not burst.scene:
        return false
    # Instantiate temporarily to check if it's an enemy
    var instance = burst.scene.instantiate()
    var is_enemy = instance.is_in_group("enemies") or instance is Vessel2D
    instance.free()
    return is_enemy

func _detect_burst_entry(burst: BurstSequence) -> Dictionary:
    var pos = burst.global_position
    var screen = Vector2(get_tree().root.content_scale_size)
    # Check if burst position is off-screen
    if pos.x < 0:
        return { "position": Vector2(0, clampf(pos.y, 0, screen.y)), "edge": EntryArrow.Edge.LEFT }
    if pos.x > screen.x:
        return { "position": Vector2(screen.x, clampf(pos.y, 0, screen.y)), "edge": EntryArrow.Edge.RIGHT }
    if pos.y < 0:
        return { "position": Vector2(clampf(pos.x, 0, screen.x), 0), "edge": EntryArrow.Edge.TOP }
    if pos.y > screen.y:
        return { "position": Vector2(clampf(pos.x, 0, screen.x), screen.y), "edge": EntryArrow.Edge.BOTTOM }
    return {}  # Burst is on-screen, no warning needed

func _find_direct_entry(vessel: Node2D) -> Dictionary:
    var pos = vessel.global_position
    var screen = Vector2(get_tree().root.content_scale_size)
    if pos.x < 0:
        return { "position": Vector2(0, clampf(pos.y, 0, screen.y)), "edge": EntryArrow.Edge.LEFT }
    if pos.x > screen.x:
        return { "position": Vector2(screen.x, clampf(pos.y, 0, screen.y)), "edge": EntryArrow.Edge.RIGHT }
    if pos.y < 0:
        return { "position": Vector2(clampf(pos.x, 0, screen.x), 0), "edge": EntryArrow.Edge.TOP }
    if pos.y > screen.y:
        return { "position": Vector2(clampf(pos.x, 0, screen.x), screen.y), "edge": EntryArrow.Edge.BOTTOM }
    return {}  # Already on screen

func _pos_to_edge(pos: Vector2) -> EntryArrow.Edge:
    var screen = Vector2(get_tree().root.content_scale_size)
    var center = screen / 2
    var offset = pos - center
    if abs(offset.x) > abs(offset.y):
        return EntryArrow.Edge.LEFT if offset.x < 0 else EntryArrow.Edge.RIGHT
    else:
        return EntryArrow.Edge.TOP if offset.y < 0 else EntryArrow.Edge.BOTTOM

func _spawn_arrows():
    if _entry_data.is_empty():
        return

    # Cluster entries by edge and proximity
    var clusters: Array[Array] = []
    for entry in _entry_data:
        var added = false
        for cluster in clusters:
            if cluster[0].edge == entry.edge:
                var dist = _edge_distance(cluster[0], entry)
                if dist < CLUSTER_DISTANCE:
                    cluster.append(entry)
                    added = true
                    break
        if not added:
            clusters.append([entry])

    # Spawn one arrow per cluster
    for cluster in clusters:
        var avg_pos = Vector2.ZERO
        var vessels: Array[Node] = []
        for entry in cluster:
            avg_pos += entry.position
            vessels.append(entry.vessel)
        avg_pos /= cluster.size()

        # Clamp to screen edge
        var screen = Vector2(get_tree().root.content_scale_size)
        var edge: EntryArrow.Edge = cluster[0].edge
        var corner = edge_offset * 2
        match edge:
            EntryArrow.Edge.LEFT:
                avg_pos = Vector2(edge_offset, clampf(avg_pos.y, corner, screen.y - corner))
            EntryArrow.Edge.RIGHT:
                avg_pos = Vector2(screen.x - edge_offset, clampf(avg_pos.y, corner, screen.y - corner))
            EntryArrow.Edge.TOP:
                avg_pos = Vector2(clampf(avg_pos.x, corner, screen.x - corner), edge_offset)
            EntryArrow.Edge.BOTTOM:
                avg_pos = Vector2(clampf(avg_pos.x, corner, screen.x - corner), screen.y - edge_offset)

        var arrow: EntryArrow = EntryArrowScene.instantiate()
        arrow.position = avg_pos
        arrow.edge = edge
        arrow.vessels = vessels
        arrow.z_index = 4095  # Same as Reticule, above pixelated viewport
        arrow.add_to_group("entry_arrows")
        get_tree().current_scene.add_child(arrow)
        _arrows.append(arrow)

func _edge_distance(a: Dictionary, b: Dictionary) -> float:
    if a.edge in [EntryArrow.Edge.LEFT, EntryArrow.Edge.RIGHT]:
        return abs(a.position.y - b.position.y)
    else:
        return abs(a.position.x - b.position.x)

func _physics_process(_delta):
    var i = _arrows.size() - 1
    while i >= 0:
        var arrow = _arrows[i]
        if not is_instance_valid(arrow) or arrow.should_remove():
            if is_instance_valid(arrow):
                arrow.queue_free()
            _arrows.remove_at(i)
        i -= 1
