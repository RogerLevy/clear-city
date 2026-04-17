class_name Encounter
extends Node2D

@export var starting_animation = "in-and-out1"

func _ready():
    if self == get_tree().current_scene:
        start()

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
    queue_free()

func start():
    #print_debug( self )
    $AnimationPlayer.play( starting_animation )
