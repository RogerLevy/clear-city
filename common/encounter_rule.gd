@tool
extends Sequence
class_name EncounterRule

func _init():
    open_ended = true  # Completion controlled by condition, not duration

## Condition
enum Condition { ALL_KILLED, NUMBER_KILLED }
@export var condition: Condition = Condition.ALL_KILLED
@export var target_class: Script  # Optional: filter by script type
@export var kill_count: int = 1  # For NUMBER_KILLED condition

## Action
enum Action { DO_NOTHING, LAST_DROPS }
@export var action: Action = Action.DO_NOTHING
@export var drop_scene: PackedScene  # Required for LAST_DROPS

var _last_pos: Vector2
var _initial_count: int = 0
var _killed_count: int = 0
var _started: bool = false
var _parent: Node

func start():
    if _started:
        return
    _started = true
    _parent = get_parent()
    # For ALL_KILLED, count initial targets BEFORE connecting signal
    if condition == Condition.ALL_KILLED:
        _count_initial_targets()
    g.enemy_died.connect(_on_enemy_died)
    super.start()

func _count_initial_targets():
    for node in get_tree().get_nodes_in_group("enemies"):
        if node.process_mode == ProcessMode.PROCESS_MODE_DISABLED:
            continue
        if not _is_descendant_of(node, _parent):
            continue
        if _matches_filter(node):
            _initial_count += 1

func _is_descendant_of(node: Node, ancestor: Node) -> bool:
    var current = node.get_parent()
    while current:
        if current == ancestor:
            return true
        current = current.get_parent()
    return false

func _matches_filter(node: Node) -> bool:
    if target_class and not node.get_script() == target_class:
        return false
    return true

func _on_enemy_died(enemy: Node, pos: Vector2):
    if not running:
        return
    if condition == Condition.ALL_KILLED:
        if not _is_descendant_of(enemy, _parent):
            return
    if not _matches_filter(enemy):
        return
    _last_pos = pos
    _killed_count += 1
    _check_condition()

func _check_condition():
    match condition:
        Condition.ALL_KILLED:
            if _killed_count >= _initial_count and _initial_count > 0:
                _trigger_action()
        Condition.NUMBER_KILLED:
            if _killed_count >= kill_count:
                _trigger_action()

func _trigger_action():
    match action:
        Action.LAST_DROPS:
            if drop_scene:
                var instance = drop_scene.instantiate()
                instance.position = _last_pos
                g.playfield.add_child.call_deferred(instance)
    g.enemy_died.disconnect(_on_enemy_died)
    complete()
