@tool
class_name EnemyJollyboy
extends Vessel2D

static var DEFAULT_ANIM: Array = range(36)

func init():
    animation = DEFAULT_ANIM
    animationSpeed = 1.0 / 3.0
