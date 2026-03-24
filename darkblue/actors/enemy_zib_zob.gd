@tool
class_name EnemyZibZob
extends Vessel2D

static var DEFAULT_ANIM: Array = range(10)

func init():
    animation = DEFAULT_ANIM
    animationSpeed = 1.0 / 3.0
