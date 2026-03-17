extends Actor2D

func init():
    beat.beat_hit.connect(_on_beat)
    _beat()
    add_to_group("pickups")
    $Area2D.area_entered.connect(_on_area_entered)

func _beat():
    scale = Vector2(1.4, 1.4)
    var tween = create_tween()
    tween.tween_property(self, "scale", Vector2(1, 1), beat.scale * 1.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _on_beat(b: int):
    if b % 2 != 0: return
    _beat()

func _on_area_entered(area: Area2D):
    var actor = area.get_parent()
    if actor == g.p1:
        collect()

func collect():
    var tm = g.get("tri_manager")
    if tm:
        tm.trap_all()
    queue_free()
