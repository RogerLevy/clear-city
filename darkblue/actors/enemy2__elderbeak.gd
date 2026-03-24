@tool
extends Vessel2D

static var IDLE_ANM:Array = range( 22 ) 

func init():
    animation = IDLE_ANM
    animationSpeed = 1.0/3
    #animationSpeed = g.anim_speed( IDLE_ANM, 2 )

#func _ready():
    #print_debug("enemy2 says hi")
    #super._ready()
