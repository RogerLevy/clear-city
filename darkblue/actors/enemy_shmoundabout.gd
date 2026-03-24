@tool
class_name EnemyShmoundabout
extends Vessel2D

static var DEFAULT_ANIM: Array = range(50)

func init():
    animation = DEFAULT_ANIM
    animationSpeed = musical_anim_speed(DEFAULT_ANIM, 4)
