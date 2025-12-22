@tool
extends Actor2D

func init():
    await frame()
    g.at( position )
    g.spawn( "vgaman" )
