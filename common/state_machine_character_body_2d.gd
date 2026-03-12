@tool
class_name StateMachineCharacterBody2D
extends CharacterBody2D

var behavior: Callable
@export var state_name: String = ""
var delta: float = 0
@export var frame_counter:int = 0
@export var time_counter:float = 0 
@export var debug:bool = false

func init():
    pass

func _ready():
    if process_mode != Node.PROCESS_MODE_DISABLED and not Engine.is_editor_hint():
        init()

func act( cb: Callable ) -> void:
    if Engine.is_editor_hint(): return
    behavior = cb
    if debug:
        var method_name = cb.get_method()
        state_name = method_name if method_name !="<anonymous lambda>" else "%s:%d" % [get_stack()[1].function, get_stack()[1].line]
        print_debug( state_name )

func passed( time:float ):
    var passed = ( time <= time_counter )
    if passed: time_counter = 0.0
    return passed

func _physics_process( _delta ):
    if not Engine.is_editor_hint():
        self.delta = _delta
        time_counter += _delta
        if behavior: behavior.call()
        move_and_slide()

signal universe_heat_death

func frames( frames:int = 1 ):
    # usage:
    #   await frames(10)    # wait 10 frames
    frame_counter = 0
    if Engine.is_editor_hint(): 
        await universe_heat_death
        return        
    for i in range(frames):
        await get_tree().physics_frame
        frame_counter += 1
    #state_name = get_stack()[0].function
    #if debug:
        #print_debug("%s:%d" % [state_name, get_stack()[0].line])

func frame():
    # usage:
    #   await frame()    # wait 1 frame
    if Engine.is_editor_hint(): 
        await universe_heat_death
        return
    await get_tree().physics_frame
    #state_name = get_stack()[0].function
    #if debug:
        #print_debug("%s:%d" % [state_name, get_stack()[0].line])

func secs( time:float = 1.0 ):
    # usage:
    #   await secs( 5 )    # wait 5 seconds
    if Engine.is_editor_hint():
        await universe_heat_death
        return
    var elapsed = 0.0
    while elapsed < time:
        await get_tree().physics_frame
        elapsed += delta
    #state_name = get_stack()[0].function
    #if debug:
        #print_debug("%s:%d" % [state_name, get_stack()[0].line])

func beats( count:float = 1.0 ):
    # usage:
    #   await beats( 4 )    # wait 4 beats (tempo-scaled)
    if Engine.is_editor_hint():
        await universe_heat_death
        return
    var real_time = count * beat.scale
    var elapsed = 0.0
    while elapsed < real_time:
        await get_tree().physics_frame
        elapsed += delta
