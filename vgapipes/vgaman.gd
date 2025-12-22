@tool
extends Actor2D

func init():
    act( func(): 
        position.x += randf_range(-1,1)
        position.y += randf_range(-1,1)
    )

    # slow!!!    
    #while 1:
        #await frame()
        #position.x += randf_range(-1,1)
        #position.y += randf_range(-1,1)
        
