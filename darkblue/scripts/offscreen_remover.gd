class_name OffscreenRemover
extends Node

@export var margin: float = 16.0

func _process(_delta):
	var parent = get_parent()
	if not parent or not parent is Node2D:
		return

	var pos = parent.global_position
	var rect = get_viewport().get_visible_rect()

	if pos.x < rect.position.x - margin or \
	   pos.x > rect.end.x + margin or \
	   pos.y < rect.position.y - margin or \
	   pos.y > rect.end.y + margin:
		parent.queue_free()
