@tool
class_name Vessel2D
extends Actor2D

# Common properties for ships, enemies, and other combat entities

@export var hp: int = 1          # health points
@export var r: float = 8.0       # collision radius
@export var m: float = 1.0       # mass
@export var atk: int = 1         # attack power
@export var bounty: int = 10     # points/reward when killed
@export var firing_rate: int = 10
@export var snd_damage: AudioStreamWAV = preload("res://darkblue/sfx/snd-06.wav")
@export var bounty_font: Font = preload("res://darkblue/fonts/darkblue_mini.ttf")

const DeathCircle = preload("res://darkblue/effects/death_circle.gd")

func recovering() -> bool:
    return false

var dead: bool = false

func damage(amount: int):
    if dead: return
    if not is_visible_in_tree(): return  # Not active yet (sequence not launched)
    g.sfx(snd_damage, 0.6)
    hp -= amount
    if hp <= 0:
        dead = true
        die()

func die():
    # Spawn death effect
    var playfield = g.get("playfield")
    if playfield:
        DeathCircle.spawn(playfield, global_position, r, Color( "d1d1b2" ), clampf(16.0 / r, 0.5, 1.5) )
        FloatingText.spawn(playfield, global_position, str(bounty), bounty_font)
    # Spawn tris
    var tm = g.get("tri_manager")
    if tm:
        for i in bounty:
            var angle = randf() * TAU
            tm.spawn(global_position, Vector2.from_angle(angle) * 40)
    queue_free()
