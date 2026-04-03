class_name StageConfig
extends Node

@export var enemy_stats: GDScript
@export var starting_energy: int = 20

func _ready():
    g.energy = starting_energy
    if enemy_stats:
        enemies.active_stats = enemy_stats.new()
