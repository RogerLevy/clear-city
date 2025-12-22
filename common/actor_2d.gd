@tool
class_name Actor2D
extends StateMachineCharacterBody2D

@onready var sprite:Sprite2D = $Sprite2D

@export var sprite_texture: Texture2D:
    set(value):
        sprite_texture = value
        if is_node_ready():
            update_sprite()

@export var frame_width: int = 16:
    set(value):
        frame_width = max( value, 1 )
        if is_node_ready():        
            update_sprite()

@export var frame_height: int = 16:
    set(value):
        frame_height = max( value, 1 )
        if is_node_ready():
            update_sprite()

@export_range(0, 255, 1) var current_frame:int = 0:
    set(value):
        current_frame = value
        if is_node_ready():
            if sprite:
                sprite.frame = value % (sprite.hframes * sprite.vframes)


func update_sprite():
    if not sprite_texture: return
    sprite.texture = sprite_texture
    sprite.hframes = max(1, sprite_texture.get_width() / frame_width)
    sprite.vframes = max(1, sprite_texture.get_height() / frame_height)
    
    if( current_frame < sprite.hframes * sprite.vframes ):
        sprite.frame = current_frame
    
func _ready():
    update_sprite()
    super._ready()
    
func set_sprite(texture: Texture2D, frame_width: int, frame_height: int):
    sprite.texture = texture
    self.frame_width = frame_width
    self.frame_height = frame_height
    update_sprite()
   
