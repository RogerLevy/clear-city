extends Sequence
class_name EncounterRule

## Condition
enum Condition { ALL_KILLED }
@export var condition: Condition = Condition.ALL_KILLED
@export var target_class: Script  # Optional: filter by script type

## Action
enum Action { LAST_DROPS }
@export var action: Action = Action.LAST_DROPS
@export var drop_scene: PackedScene  # Required for LAST_DROPS

var _tracked: Array = []
var _last_pos: Vector2
var _initial_count: int = 0
var _started: bool = false

func start():
    if _started:
        return
    _started = true
    open_ended = true
    super.start()
    _find_targets()
    _initial_count = _tracked.size()
    for target in _tracked:
        target.died.connect(_on_target_died.bind(target))

func _find_targets():
    for node in get_tree().get_nodes_in_group("enemies"):
        if _matches_filter(node):
            _tracked.append(node)

func _matches_filter(node: Node) -> bool:
    if target_class and not node.get_script() == target_class:
        return false
    return true

func _on_target_died(target: Node):
    _last_pos = target.global_position
    _tracked.erase(target)
    _check_condition()

func _check_condition():
    match condition:
        Condition.ALL_KILLED:
            if _tracked.is_empty() and _initial_count > 0:
                _trigger_action()

func _trigger_action():
    match action:
        Action.LAST_DROPS:
            if drop_scene:
                var instance = drop_scene.instantiate()
                instance.position = _last_pos
                g.playfield.add_child.call_deferred(instance)
    complete()
