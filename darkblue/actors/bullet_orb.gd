@tool
class_name BulletOrb
extends Actor2D

@export var atk: int = 30

static var DEFAULT_ANIM: Array = [1,3,3,2,1,1,0,0,]

func init():
    animation = DEFAULT_ANIM
    animationSpeed = musical_anim_speed(DEFAULT_ANIM, 1)
    add_to_group("enemy_projectiles")

func _physics_process(_delta):
    super._physics_process(_delta)
    position += velocity * _delta
