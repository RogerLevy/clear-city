@tool
extends Node2D

# Turret orbits around the ship and points at mouse cursor

@export var orbit_radius: float = 32.0
@export var mouse_lerp_speed: float = 0.5
@export var shot_speed: float = 800.0
@export var snd_shoot: AudioStreamWAV

var aim: float = 0.0      # target angle (where we want to point)
var current_angle: float = 0.0  # actual angle (lerps towards aim)

func _physics_process(_delta):
    if Engine.is_editor_hint(): return

    var ship = get_parent()
    if not ship: return

    # Only update aim if mouse is within game viewport
    if g.mouse_in_viewport():
        aim = (g.mouse_pos() - ship.global_position).angle()
        if g.quantize_aim:
            var step = deg_to_rad(45)
            aim = round(aim / step) * step

    # Lerp current angle towards aim
    current_angle = lerp_angle(current_angle, aim, mouse_lerp_speed)

    # Position turret orbiting the ship
    position = Vector2.from_angle(current_angle) * orbit_radius

    # Rotate to face the aim direction
    rotation = current_angle

    # Shooting
    if Input.is_action_just_pressed("shoot"):
        fire_pea()

func fire_pea():
    if g.energy <= 1: return  # preserve last energy point

    g.energy -= 1
    g.sfx(snd_shoot, 0.6)

    var shot = g.spawn("shot", null, get_parent().global_position)
    if shot:
        shot.velocity = Vector2.from_angle(current_angle) * shot_speed
