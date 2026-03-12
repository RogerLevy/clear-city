@tool
extends Actor2D

# Hazardous orb that damages player on contact

var r: float = 8.0       # collision radius

func init():
    act(float_around)

func float_around():
    # Basic floating behavior
    pass
