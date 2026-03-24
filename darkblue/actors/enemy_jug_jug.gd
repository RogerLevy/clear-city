@tool
class_name EnemyJugJug
extends Vessel2D

static var DEFAULT_ANIM: Array = range(23)

func init():
    animation = DEFAULT_ANIM
    animationSpeed = 1.0 / 3.0
