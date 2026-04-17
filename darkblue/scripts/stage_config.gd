class_name StageConfig
extends Node

@export var enemy_stats: GDScript
@export var starting_energy: int = 20
@export var invincibility: bool = false
@export var ship_speed: float = -1.0  # -1 = use ship's default
@export var enemy_bullet_factor: float = 1.0
@export var burst_force_factor: float = 1.0
@export var damage_deadzone: float = 0.0  ## Screen edge margin where enemies can't be damaged
@export var scroll_speed: Vector2 = Vector2(-50, 0)
@export var debug_info: bool = false

func _ready():
    g.energy = starting_energy
    if enemy_stats:
        enemies.active_stats = enemy_stats.new()
    var ship = get_node_or_null("%Ship")
    if ship:
        ship.invincible = invincibility or OS.has_feature("invincibility")
        if ship_speed > 0:
            ship.spd = ship_speed
    g.enemy_bullet_factor = enemy_bullet_factor
    g.burst_force_factor = burst_force_factor
    g.scroll_speed = scroll_speed
    Vessel2D.damage_deadzone = damage_deadzone
    g.debug_info = debug_info
