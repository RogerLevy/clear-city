extends Node2D

func _ready():
    var starfield = get_tree().current_scene.get_node_or_null("%Starfield")
    var pv_sub = get_tree().current_scene.get_node_or_null("%PixelatedViewport/SubViewport")
    if starfield and pv_sub:
        starfield.set_mask(pv_sub.get_texture())
