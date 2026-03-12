@tool
class_name Actor2D
extends StateMachineCharacterBody2D

@onready var sprite:Sprite2D

@export var sprite_texture: Texture2D:
    set(value):
        sprite_texture = value
        update_sprite()

@export_range(0, 2048, 1) var frame_width: int = 16:
    set(value):
        frame_width = max( value, 1 )
        update_sprite()

@export_range(0, 2048, 1) var frame_height: int = 16:
    set(value):
        frame_height = max( value, 1 )
        update_sprite()

@export_range(0, 255, 1) var current_frame:int = 0:
    set(value):
        current_frame = value
        if is_node_ready():
            if sprite:
                sprite.frame = value % (sprite.hframes * sprite.vframes)

@export var animation:Array = []
@export var animationSpeed:float = 1.0
@export var animationPos:float = 0.0

func update_sprite():
    if not sprite_texture: return
    var s = get_node_or_null("Sprite2D")
    if not s: return

    s.texture = sprite_texture
    s.hframes = max(1, sprite_texture.get_width() / frame_width)
    s.vframes = max(1, sprite_texture.get_height() / frame_height)

    if current_frame < s.hframes * s.vframes:
        s.frame = current_frame
    
func _ready():
    add_to_group("actors")
    sprite = find_child("Sprite2D")
    update_sprite()
    if get_parent() == get_tree().root:
        var cam = Camera2D.new()
        add_child(cam)
    super._ready()
    
func set_sprite(texture: Texture2D, frame_width: int, frame_height: int):
    sprite.texture = texture
    self.frame_width = frame_width
    self.frame_height = frame_height
    update_sprite()
   
func _physics_process( _delta ):
    
    if animation.size() > 0:
        animationPos += animationSpeed 
        if animationPos >= animation.size():
            animationPos = fmod( animationPos, animation.size() )
        current_frame = animation[ animationPos ]
        
    super._physics_process( _delta )

func musical_anim_speed(frames: Array, period: float) -> float:
    return frames.size() / (period * beat.scale * Engine.physics_ticks_per_second)
