@tool
extends Vessel2D

# === Properties ===
var flash_ctr: int = -1          # <0 = normal, >=0 = recovering (invincibility frames)
var tri_cooldown: int = -1       # separate cooldown for tri collection
var paralysis: int = 0           # prevents input when >0
var _tri_accumulator: int = 0    # accumulated tris for display
var _tri_display_timer: float = 0.0  # time since last tri collection

# === Tweaks ===
@export var sbp: int = 5         # screen bounce paralysis length
@export var spd: float = 15     # normal movement speed
@export var ine: float = 0.93    # inertia multiplier

# === Sounds ===
@export var snd_collect: AudioStreamWAV
@export var snd_bounce: AudioStreamWAV
@export var damage_font: Font = preload("res://darkblue/fonts/darkblue_mini.ttf")
var _collect_snd_cooldown: int = 0

func recovering() -> bool:
    return flash_ctr >= 0

func get_speed() -> float:
    return spd / 2.5 if tri_cooldown >= 0 else spd

# === Main behavior ===
func init():
    r = 13.0
    m = 10.0
    act(main_behavior)

func main_behavior():
    update_sprite_flash()
    handle_controls()

func update_sprite_flash():
    if flash_ctr < 0:
        current_frame = 0
        return
    # Flash effect: alternate to flash frame
    current_frame = 15 if flash_ctr % 5 < 2 else 0
    if flash_ctr > -1:
        flash_ctr -= 1
        if flash_ctr == -1:
            check_overlapping_hazards()

func handle_controls():
    if paralysis > 0:
        paralysis -= 1
        return

    var input := Vector2.ZERO
    if Input.is_action_pressed("left"):  input.x -= 1
    if Input.is_action_pressed("right"): input.x += 1
    if Input.is_action_pressed("up"):    input.y -= 1
    if Input.is_action_pressed("down"):  input.y += 1

    # Counter-thrust boost: extra accel when opposing current velocity
    var boost := Vector2.ONE
    if input.x != 0 and sign(input.x) != sign(velocity.x):
        boost.x = 1.0 + abs(velocity.x) * 0.03
    if input.y != 0 and sign(input.y) != sign(velocity.y):
        boost.y = 1.0 + abs(velocity.y) * 0.03

    velocity += input * get_speed() * boost

func _physics_process(delta):
    velocity *= ine
    screen_bounce(0.9)
    attract_tris()
    check_tris()
    super._physics_process(delta)

func attract_tris():
    if dead or Engine.is_editor_hint(): return
    var tm = g.get("tri_manager")
    if not tm: return
    tm.attract_trapped(global_position, 300.0)
    if tri_cooldown < 0:
        tm.attract_to(global_position, 35.0, 200.0)

func check_tris():
    if dead or Engine.is_editor_hint(): return
    if tri_cooldown >= 0:
        tri_cooldown -= 1
        return
    var tm = g.get("tri_manager")
    if not tm: return
    if _collect_snd_cooldown > 0:
        _collect_snd_cooldown -= 1
    var collected = tm.check_ship_collision(global_position, r)
    if collected > 0:
        if _collect_snd_cooldown <= 0:
            g.sfx(snd_collect, 0.2, "Collect")
            _collect_snd_cooldown = 3
        g.energy += collected
        _tri_accumulator += collected
        _tri_display_timer = 0.0
    elif _tri_accumulator > 0:
        _tri_display_timer += get_physics_process_delta_time()
        if _tri_display_timer >= 0.2:
            FloatingText.spawn(get_parent(), global_position, "+" + str(_tri_accumulator), damage_font, 16, Color("0f0"), self)
            _tri_accumulator = 0

func screen_bounce(damping: float) -> bool:
    var screen_size = get_viewport().get_visible_rect().size
    var bounced = false

    # Left edge
    if global_position.x < r and velocity.x < 0:
        velocity.x *= -damping
        bounced = true
    # Right edge
    if global_position.x > screen_size.x - r and velocity.x > 0:
        velocity.x *= -damping
        bounced = true
    # Top edge
    if global_position.y < r and velocity.y < 0:
        velocity.y *= -damping
        bounced = true
    # Bottom edge
    if global_position.y > screen_size.y - r and velocity.y > 0:
        velocity.y *= -damping
        bounced = true

    if bounced:
        g.sfx(snd_bounce)
        paralysis = sbp
    return bounced

# === Damage system ===
func damage(amount: int):
    if amount == 0: return
    g.sfx(snd_damage)
    FloatingText.spawn(get_parent(), global_position, "-" + str(amount), damage_font, 16, Color("f00"), self)

    g.energy -= amount
    if g.energy <= 0:
        die()
        return

    expel(amount)
    flash_ctr = 90
    tri_cooldown = 30

func die():
    dead = true
    g.energy = 0
    flash_ctr = 62
    time_counter = 0.0
    slowdown_playfield()
    slowdown_starfield()
    beat.stop()
    act(death_behavior)

func slowdown_starfield():
    var starfield = get_tree().current_scene.get_node_or_null("%Starfield")
    if not starfield: return
    var decelerator = g.spawn("", get_parent(), Vector2.ZERO)
    decelerator.act(func():
        starfield.scroll_speed *= 0.94
    )

func death_behavior():
    update_sprite_flash()
    if passed(1.0):
        spawn_lightning()
        act(death_shatter)

func death_shatter():
    shatter()
    await secs(3.0)
    g.shout("retry")

func spawn_lightning():
    g.spawn("lightning", get_parent(), g.screen_center())

func shatter():
    for i in 200:
        var angle = randf() * TAU
        var dist = randf() * 14
        var dot = g.spawn("dot", null, global_position + Vector2.from_angle(angle) * dist)
        if dot:
            dot.velocity = Vector2.from_angle(randf() * TAU) * randf() * 40
    queue_free()

func expel(amount: int):
    print("expel ", amount)
    var tm:TriManager = g.get("tri_manager")
    if not tm: return
    for i in amount:
        var angle = randf() * TAU
        tm.spawn(global_position + Vector2.from_angle(angle) * 20, Vector2.from_angle(angle) * randf_range(39.0, 41.0))

func slowdown_playfield():
    var actors = get_tree().get_nodes_in_group("actors")
    for seq:Sequence in get_tree().get_nodes_in_group("sequences"):
        seq.freeze()
    var anims = g.playfield.find_children("*", "AnimationPlayer") if g.playfield else []
    var decelerator = g.spawn("", get_parent(), Vector2.ZERO)
    var sines = get_tree().get_nodes_in_group("sine_movements")
    var tm = g.get("tri_manager")
    # Disable animation tracks that control SineMovement properties
    for anim_player in anims:
        for anim_name in anim_player.get_animation_list():
            var anim:Animation = anim_player.get_animation(anim_name)
            for track_idx in anim.get_track_count():
                var path = str(anim.track_get_path(track_idx))
                if "SineMovement" in path:
                    anim.track_set_enabled(track_idx, false)
    decelerator.act(func():
        for actor in actors:
            if not actor: continue
            if actor == g.p1: continue
            actor.velocity *= 0.94
            actor.animationSpeed *= 0.94
        for anim in anims:
            anim.speed_scale *= 0.94
        for sine in sines:
            if is_instance_valid(sine):
                sine.speed *= 0.94
        if tm:
            tm.slowdown(0.94)
    )

# === Collision handlers (connect via Area2D signals) ===
func check_overlapping_hazards():
    # Check smaller hitbox for enemies
    for area in $EnemyHitbox.get_overlapping_areas():
        var actor = area.get_parent()
        if actor.is_in_group("enemies"):
            hit_enemy(actor)
            return
    # Check main hitbox for projectiles
    for area in $Area2D.get_overlapping_areas():
        var actor = area.get_parent()
        if actor.is_in_group("enemy_projectiles"):
            hit_orb(actor)
            return

func _on_area_entered(area: Area2D):
    if recovering(): return
    var actor = area.get_parent()

    if actor.is_in_group("enemy_projectiles"):
        hit_orb(actor)

func _on_enemy_hitbox_entered(area: Area2D):
    if recovering(): return
    var actor = area.get_parent()
    if actor.is_in_group("enemies"):
        hit_enemy(actor)
    #elif actor.is_in_group("resources"):
        #hit_tri(actor)

func hit_enemy(enemy):
    if recovering(): return
    damage(enemy.atk)
    var knockback = (global_position - enemy.global_position).normalized() * 300
    velocity += knockback

func hit_orb(orb):
    if recovering(): return
    damage(orb.atk)
    var knockback = (global_position - orb.global_position).normalized() * 0.5
    velocity += knockback
    orb.queue_free()

#func hit_tri(tri):
    #g.sfx(snd_collect, 0.5)
    #g.sfx(snd)
    #g.energy += 1
    #tri.queue_free()

func _ready():
    super._ready()
    if Engine.is_editor_hint(): return
    g.p1 = self
