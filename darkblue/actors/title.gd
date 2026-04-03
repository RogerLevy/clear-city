extends Actor2D

func init():
    %TitleMenu.visible = false
    Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
    scale.y = 0
    await secs(2)
    var tween:Tween = create_tween()
    tween.tween_property(self, "scale:y", 1, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
    tween.tween_callback( func():
        %TitleMenu.visible = true
        )
