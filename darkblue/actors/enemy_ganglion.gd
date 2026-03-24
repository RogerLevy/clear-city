@tool
class_name EnemyGanglion
extends Vessel2D

static var DEFAULT_ANIM: Array = range(17)

func init():
    animation = DEFAULT_ANIM
    animationSpeed = 1.0 / 3.0
