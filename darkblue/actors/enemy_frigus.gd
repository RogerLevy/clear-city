@tool
extends Vessel2D
class_name EnemyFrigus

static var IDLE_ANM:Array = range( 14 )  

func init():
    animation = IDLE_ANM
    animationSpeed = 1.0/3
