@tool
class_name King
extends Vessel2D

static var DEFAULT_ANIM: Array = range(2)

func init():
    animation = DEFAULT_ANIM
    animationSpeed = musical_anim_speed(DEFAULT_ANIM,1)
