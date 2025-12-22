extends StateMachineCharacterBody2D

@export var count:int = 100

func init():
    var it:Node = get_child(0)
    if not it: return
    remove_child( it )
    for i in range(count):
        var clone = it.duplicate()
        clone.position = to_global( g.somewhere( -200, -200, 200, 200 ) )
        get_parent().add_child.call_deferred(clone)
        #await frame()
