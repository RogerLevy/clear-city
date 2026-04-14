@tool
extends Sequence
class_name LoopSequence

@export var times: int = 1  ## Number of loops (0 = infinite)

var _current_loop: int = 0

func _ready():
    super._ready()
    if Engine.is_editor_hint(): return
    # Force children to stick around if looping more than once
    if times != 1:
        for seq in _sequence_list:
            seq.stick_around = true

func start():
    _current_loop = 0
    super.start()

func next():
    if frozen: return
    if _seeking:
        _seek_next_count += 1
        return

    _current_index += 1
    if _current_index >= _sequence_list.size():
        _current_loop += 1
        if times > 0 and _current_loop >= times:
            if not _duration_override and not open_ended:
                _complete()
            return
        _restart_loop()
        return

    var seq = _sequence_list[_current_index]
    if is_instance_valid(seq):
        launch_sequence(seq)

func _restart_loop():
    _current_index = -1
    for seq in _sequence_list:
        seq.running = false
        seq.visible = false
        seq.process_mode = Node.PROCESS_MODE_DISABLED
    next()
