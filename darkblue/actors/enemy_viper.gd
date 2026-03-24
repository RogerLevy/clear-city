@tool
class_name EnemyViper
extends Vessel2D

static var DEFAULT_ANIM: Array = range(23)

func init():
    animation = DEFAULT_ANIM
    animationSpeed = musical_anim_speed(DEFAULT_ANIM, 23)
