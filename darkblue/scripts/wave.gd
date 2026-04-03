extends Node
class_name Wave

## Base class for scripted wave orchestration.
## Subclass and override run() to define wave behavior.

signal wave_completed

var _running := false

func _ready():
    if get_parent() == get_tree().root:
        # Auto-run if scene root
        call_deferred("run")

## Override this in subclasses to define wave behavior
func run():
    pass

## Start/activate a node - tries start(), play(), show+enable in that order
func start(node: Node):
    if node.has_method("start"):
        node.start()
    elif node.has_method("play"):
        node.play()
    elif node is CanvasItem:
        node.visible = true
        node.process_mode = Node.PROCESS_MODE_INHERIT
    elif node is Node:
        node.process_mode = Node.PROCESS_MODE_INHERIT

## Stop/deactivate a node
func stop(node: Node):
    if node.has_method("stop"):
        node.stop()
    elif node is CanvasItem:
        node.visible = false
        node.process_mode = Node.PROCESS_MODE_DISABLED
    elif node is Node:
        node.process_mode = Node.PROCESS_MODE_DISABLED

## Wait for a number of beats
func beats(count: float):
    await beat.wait(count)

## Wait for a number of seconds
func secs(time: float):
    await get_tree().create_timer(time).timeout

## Wait for a number of frames
func frames(count: int = 1):
    for i in count:
        await get_tree().physics_frame

## Convert beats to seconds
func beats_to_secs(count: float) -> float:
    return count * beat.scale

## Convert seconds to beats
func secs_to_beats(time: float) -> float:
    return time / beat.scale

## Signal wave progression
func set_wave():
    _running = true

func next_wave():
    _running = false
    wave_completed.emit()

### Wait until all enemies in a group are killed
#func await_all_killed(group: String = "enemies"):
    #while get_tree().get_nodes_in_group(group).size() > 0:
        #await get_tree().physics_frame
#
### Wait until a specific number of enemies are killed
#func await_kills(count: int):
    #var killed := 0
    #var on_kill = func(_enemy, _pos):
        #killed += 1
    #g.enemy_died.connect(on_kill)
    #while killed < count:
        #await get_tree().physics_frame
    #g.enemy_died.disconnect(on_kill)

enum Easing { NONE, EASE }

## Move a node to a target position over duration seconds
## Target can be a Vector2 or a Node2D (uses its position)
func move_to(node: Node2D, target, duration: float, easing: Easing = Easing.NONE) -> Tween:
    var target_pos: Vector2
    if target is Vector2:
        target_pos = target
    elif target is Node2D:
        target_pos = target.global_position
    else:
        return null

    var tween = create_tween()
    if easing == Easing.EASE:
        tween.set_ease(Tween.EASE_IN_OUT)
        tween.set_trans(Tween.TRANS_CUBIC)
    tween.tween_property(node, "global_position", target_pos, duration)
    return tween
