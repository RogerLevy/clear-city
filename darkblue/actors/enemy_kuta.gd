@tool
class_name EnemyKuta
extends Vessel2D

static var DEFAULT_ANIM: Array = range(36)

func init():
    animation = DEFAULT_ANIM
    animationSpeed = 1.0 / 2.0
