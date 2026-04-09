extends Node

func _physics_process(_delta: float) -> void:
    if OS.has_feature("editor") and Input.is_action_just_pressed("skip_wave"):
        %WaveSequence.skip()
