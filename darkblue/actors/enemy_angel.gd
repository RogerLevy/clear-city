@tool
extends Vessel2D

static var IDLE_ANM:Array = range(10)

func init():
    animation = IDLE_ANM
    animationSpeed = 1.0
