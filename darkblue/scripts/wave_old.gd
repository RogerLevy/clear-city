class_name WaveOld
extends Node2D

var event_number = 0

func _process(delta):
    if get_children().size() == 0:
        queue_free()

func event(name):
    var event = find_child(name, true, false)
    if event == null: return
    event.start()

func start():
    $WaveSequence.play()

func next():
    if event_number >= get_child_count(): return
    var event = get_child( event_number )
    event_number += 1
    if event == null: return
    event.start()
    
