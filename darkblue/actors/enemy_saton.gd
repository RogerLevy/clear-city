@tool
class_name EnemySaton
extends Vessel2D

static var DEFAULT_ANIM: Array = range(27)

func init():
    animation = DEFAULT_ANIM
    animationSpeed = 1.0 / 3.0
