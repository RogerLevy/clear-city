@tool
class_name EnemyHousefly
extends Vessel2D

static var DEFAULT_ANIM: Array = range(2)

func init():
    animation = DEFAULT_ANIM
    animationSpeed = 1.0/2
