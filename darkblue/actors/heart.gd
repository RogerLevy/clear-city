@tool
extends Actor2D
var _tween:Tween
var snd_heart: AudioStreamWAV = preload("res://darkblue/sfx/heart-01.wav")
var snd_collect: AudioStreamWAV = preload("res://darkblue/sfx/heart-02.wav")

func init():
    g.sfx(snd_heart,0.25)
    beat.beat_hit.connect(_on_beat)
    #_beat()
    add_to_group("pickups")
    $Area2D.area_entered.connect(_on_area_entered)
    if g.p1:
        velocity = (g.p1.position - position).normalized() * 50
    else:
        velocity.x = g.scroll_speed.x

func _beat():
    scale = Vector2(1.4, 1.4)
    if _tween:
        _tween.stop()
    _tween = create_tween()
    _tween.tween_property(self, "scale", Vector2(1, 1), beat.scale * 1.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
    

func _on_beat(b: int):
    #if b % 2 != 0: return
    _beat()

func _on_area_entered(area: Area2D):
    var actor = area.get_parent()
    if actor == g.p1:
        collect()

func collect():
    g.sfx(snd_collect,0.25)
    var tm = g.get("tri_manager")
    if tm:
        tm.trap_all()
    queue_free()
