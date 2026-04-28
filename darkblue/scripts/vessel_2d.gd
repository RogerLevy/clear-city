@tool
class_name Vessel2D
extends Actor2D

signal died

# Common properties for ships, enemies, and other combat entities

@export var hp: int = 1          # health points
@export var r: float = 8.0       # collision radius
#@export var m: float = 1.0       # mass
@export var atk: int = 5         # attack power
@export var bounty: int = 10     # points/reward when killed
@export var snd_damage: AudioStreamWAV = preload("res://darkblue/sfx/snd-06.wav")
@export var snd_death: AudioStreamWAV = preload("res://darkblue/sfx/snd-06.wav")
static var bounty_font: Font = preload("res://darkblue/fonts/darkblue_mini.ttf")
@export var invincible: bool = false
@export var show_hp_bar: bool = true

const DeathCircle = preload("res://darkblue/effects/death_circle.gd")

static var damage_deadzone: float = 0.0  ## Screen edge margin where enemies can't be damaged

var _shake_counter: int = 0
var _max_hp: int = 0
var _display_hp: float = 0.0
var _damaged: bool = false

@export var stats:Dictionary

## Look up stats from enemies autoload using scene filename
func load_stats():
    var scene_path = scene_file_path
    if scene_path:
        var filename = scene_path.get_file().get_basename()
        stats = enemies.get_stats(filename)
        if stats != enemies._default:
            hp = stats.hp
            atk = stats.atk
            bounty = stats.bounty

func _ready():
    super._ready()
    if not Engine.is_editor_hint(): load_stats()
    _max_hp = hp
    _display_hp = float(hp)

func recovering() -> bool:
    return false

var dead: bool = false

func _in_damage_deadzone() -> bool:
    if damage_deadzone <= 0: return false
    if not is_in_group("enemies"): return false
    var vp_size = get_viewport_rect().size
    var pos = global_position
    return pos.x < damage_deadzone or pos.x > vp_size.x - damage_deadzone or \
           pos.y < damage_deadzone or pos.y > vp_size.y - damage_deadzone

func damage(amount: int):
    if invincible or recovering(): return
    if dead: return
    if not is_visible_in_tree(): return  # Not active yet (sequence not launched)
    if _in_damage_deadzone(): return
    hp -= amount
    _damaged = true
    if hp <= 0:
        dead = true
        die()
    else:
        g.sfx(snd_damage, 0.6)
        _shake_counter = 15

func die():
    g.sfx(snd_death, 0.6)
    died.emit()
    g.enemy_died.emit(self, global_position)
    # Spawn death effect
    var playfield = g.get("playfield")
    if playfield:
        var sprite_size = _get_sprite_size()
        var death_r = maxf(sprite_size.x, sprite_size.y) * 0.55
        DeathCircle.spawn(playfield, global_position, death_r, g.COLOR_MAIN, clampf(16.0 / death_r, 0.5, 1.5) )
        #FloatingText.spawn(playfield, global_position, str(bounty), Vessel2D.bounty_font)
    # Spawn tris biased towards player
    var tm = g.tri_manager
    if tm:
        var to_player = (g.p1.global_position - global_position).angle() if g.p1 else 0.0
        var angles: Array[float] = []
        var max_spread = PI * (bounty - 1.0) / bounty if bounty > 1 else 0.0
        for i in bounty:
            var t = float(i) / (bounty - 1) * 2.0 - 1.0 if bounty > 1 else 0.0
            var offset = sign(t) * pow(abs(t), 3.0) * max_spread
            angles.append(to_player + offset)
        angles.shuffle()
        for angle in angles:
            tm.spawn(global_position, Vector2.from_angle(angle) * randf_range(39.0, 41.0))
    queue_free()

func _process_shake():
    if _shake_counter:
        sprite.position.x = -1 if ((_shake_counter / 2) & 1) else 1
        _shake_counter -= 1
    else:
        sprite.position.x = 0
            
func _physics_process( _delta ):
    super._physics_process( _delta )
    _process_shake()
    _process_hp_bar()

func _process_hp_bar():
    if not show_hp_bar or not _damaged or _max_hp <= 0: return
    var diff = hp - _display_hp
    var roll_speed = absf(diff) * 0.05 + 0.1
    var prev = _display_hp
    _display_hp = move_toward(_display_hp, hp, roll_speed)
    if prev != _display_hp:
        queue_redraw()

func _get_sprite_size() -> Vector2:
    if sprite and sprite.texture:
        var tex_size = sprite.texture.get_size()
        if sprite.hframes > 1 or sprite.vframes > 1:
            return Vector2(tex_size.x / sprite.hframes, tex_size.y / sprite.vframes)
        return tex_size
    return Vector2(frame_width, frame_height)

func _draw():
    if Engine.is_editor_hint(): return
    if not show_hp_bar or not _damaged or _max_hp <= 0: return
    var size = _get_sprite_size()
    var bar_width: float = size.x
    var bar_y: float = -size.y * 0.5 - 2
    var filled: float = bar_width * (_display_hp / _max_hp)
    draw_line(Vector2(-bar_width * 0.5, bar_y), Vector2(-bar_width * 0.5 + filled, bar_y), g.COLOR_MAIN)
