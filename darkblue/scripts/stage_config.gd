class_name StageConfig
extends Node

@export var enemy_stats: GDScript
@export var starting_energy: int = 20
@export var invincibility: bool = false

func _ready():
    g.energy = starting_energy
    if enemy_stats:
        enemies.active_stats = enemy_stats.new()
    var ship = get_node_or_null("%Ship")
    if ship:
        ship.invincible = invincibility or OS.has_feature("invincibility")
    print_debug("i executed: " + self.name)
