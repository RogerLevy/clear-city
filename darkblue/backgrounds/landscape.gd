extends Node2D

@onready var sub_viewport: SubViewport = $SubViewport
@onready var display_blend: Sprite2D = $DisplayBlend
@onready var display_punch: Sprite2D = $DisplayPunch

func _ready():
    var tex := sub_viewport.get_texture()
    display_blend.texture = tex
    display_punch.texture = tex
    var starfield = get_tree().current_scene.get_node_or_null("%Starfield")
    if starfield:
        starfield.set_mask(tex)
