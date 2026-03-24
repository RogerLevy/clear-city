@tool
class_name EnemyWaffil
extends Vessel2D

static var DEFAULT_ANIM: Array = range(40)

func init():
    animation = DEFAULT_ANIM
    animationSpeed = beat.secs(2)
