@tool
class_name EnemyGumpus
extends Vessel2D

static var DEFAULT_ANIM: Array = range(24)

func init():
    animation = DEFAULT_ANIM
    animationSpeed = 1.0 / 3.0
