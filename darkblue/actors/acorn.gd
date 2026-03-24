@tool
class_name Acorn
extends Vessel2D

static var DEFAULT_ANIM: Array = range(4)

func init():
    animation = DEFAULT_ANIM
    animationSpeed = 1.0 / 3.0
