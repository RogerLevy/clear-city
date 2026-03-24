@tool
class_name Vessel2D
extends Actor2D

signal died

# Common properties for ships, enemies, and other combat entities

@export var hp: int = 1          # health points
@export var r: float = 8.0       # collision radius
@export var m: float = 1.0       # mass
@export var atk: int = 1         # attack power
@export var bounty: int = 10     # points/reward when killed
@export var snd_damage: AudioStreamWAV = preload("res://darkblue/sfx/snd-06.wav")
static var bounty_font: Font = preload("res://darkblue/fonts/darkblue_mini.ttf")

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
    died.emit()
    g.enemy_died.emit(self, global_position)
    # Spawn death effect
    var playfield = g.get("playfield")
    if playfield:
        DeathCircle.spawn(playfield, global_position, r, g.COLOR_MAIN, clampf(16.0 / r, 0.5, 1.5) )
        FloatingText.spawn(playfield, global_position, str(bounty), Vessel2D.bounty_font)
    # Spawn tris biased towards player
    var tm = g.tri_manager
    if tm:
        var to_player = (g.p1.global_position - global_position).angle() if g.p1 else 0.0
        var angles: Array[float] = []
        for i in bounty:
            var t = float(i) / (bounty - 1) * 2.0 - 1.0 if bounty > 1 else 0.0
            var offset = sign(t) * pow(abs(t), 3.0) * PI
            angles.append(to_player + offset)
        angles.shuffle()
        for angle in angles:
            tm.spawn(global_position, Vector2.from_angle(angle) * randf_range(34.0, 36.0))
    queue_free()
