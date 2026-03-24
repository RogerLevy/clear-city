@tool
extends Vessel2D
class_name enemy7

static var IDLE_ANM:Array = range( 25 ) 

func init():
    animation = IDLE_ANM
    #animationSpeed = 1.0/3 
    animationSpeed = musical_anim_speed( IDLE_ANM, 2 )

#func _ready():
    #print_debug("enemy2 says hi")
    #super._ready()
