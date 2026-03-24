@tool
class_name EnemyDolly
extends Vessel2D

static var DEFAULT_ANIM: Array = range(1)

func init():
    animation = DEFAULT_ANIM
    animationSpeed = 1.0 / 3.0
