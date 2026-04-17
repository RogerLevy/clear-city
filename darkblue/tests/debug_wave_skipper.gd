extends Node

func _physics_process(_delta: float) -> void:
    if OS.has_feature("editor") and Input.is_action_just_pressed("skip_wave"):
        for arrow in get_tree().get_nodes_in_group("entry_arrows"):
            arrow.queue_free()
        %WaveSequence.skip()
