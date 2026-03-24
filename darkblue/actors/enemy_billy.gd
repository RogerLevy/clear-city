@tool
class_name EnemyBilly
extends Vessel2D

static var DEFAULT_ANIM: Array = range(20)

func init():
    animation = DEFAULT_ANIM
    animationSpeed = 1.0 / 3.0
