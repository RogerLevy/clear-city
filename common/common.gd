extends CanvasLayer

var canvas_item
var border
var playfield:Node2D

func _input(event):
    if event.is_action_pressed("toggle_fullscreen"):
        if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN and \
           DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
            print_debug("Going fullscreen.")
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
        else:
            print_debug("Going windowed.")
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
            set_windowed_size()

    # F7: Toggle pause (for debugging - switch to editor via taskbar)
    if event is InputEventKey and event.pressed and event.keycode == KEY_F7:
        beat.toggle_pause()
        if get_tree().paused:
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        else:
            Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

    # Click to unpause
    if get_tree().paused and event is InputEventMouseButton and event.pressed:
        beat.resume()
        Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
        # Clear shoot action so turret doesn't fire
        Input.action_release("shoot")
        get_viewport().set_input_as_handled()

    if event is InputEventMouseMotion:
        constrain_mouse()

    if edit_mode and edit_mode.is_node_ready():
        edit_mode.handle_input(event)

func _on_files_dropped( files ):
    print("Files dropped:")
    for file in files:
        print("  ", file)	

func set_windowed_size():
    var viewport_size = get_viewport().get_visible_rect().size
    get_window().size = Vector2i(viewport_size * 2)
    var screen_idx = get_window().current_screen
    var screen_size = DisplayServer.screen_get_size(screen_idx)
    var screen_pos = DisplayServer.screen_get_position(screen_idx)
    get_window().position = screen_pos + (screen_size - get_window().size) / 2

func init_window():
    if not OS.has_feature("editor") and DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
        set_windowed_size()	
    
func init_drag():
    get_viewport().files_dropped.connect(_on_files_dropped)

func init_border():
    layer = 100
    follow_viewport_enabled = false
    follow_viewport_scale = 1.0

    border = Control.new()
    add_child(border)
    border.set_script(preload("res://common/draw_border.gd"))

## Constrain mouse to game viewport (call from _process)
func constrain_mouse():
    if get_tree().paused: return
    if not get_window().has_focus(): return
    if get_window().is_embedded(): return

    var root = get_tree().root
    var game_size = Vector2(root.content_scale_size)
    if game_size.x <= 0 or game_size.y <= 0: return

    var mouse = root.get_mouse_position()
    var clamped = mouse.clamp(Vector2.ZERO, game_size - Vector2(1,1))
    if mouse != clamped:
        root.warp_mouse(clamped)

var edit_mode

func init_edit_mode():
    var EditModeScript = preload("res://common/edit_mode.gd")
    edit_mode = EditModeScript.new()
    add_child(edit_mode)
    
func somewhere( x1:float, y1:float, x2:float, y2:float ) -> Vector2: 
    return Vector2(randf_range(x1, x2), randf_range(y1, y2))

# ==================================================================================================
# Positioning

@export var pen:Vector2

func at( x, y = 0.0 ):
    if typeof( x ) == TYPE_FLOAT:
        pen = Vector2( x, y )
    else:
        pen = x

# ==================================================================================================
# Scene Manager

@export var scenes = {}
var scene_manifest_path: String = "res://scene_manifest.gd"

func load_all_scenes():
    print("Loading all scenes...")
    if OS.has_feature("editor"):
        _scan_directory("res://")
        _save_manifest()
    else:
        _load_from_manifest()
    print("Loaded %d scenes" % scenes.size())

## Override in subclass to filter scenes for export manifest
func _should_include_in_manifest(scene_path: String) -> bool:
    return true

func _save_manifest():
    var file = FileAccess.open(scene_manifest_path, FileAccess.WRITE)
    if not file:
        print("Failed to write scene manifest")
        return
    file.store_line("# Auto-generated scene manifest - do not edit")
    file.store_line("static func get_scenes() -> Dictionary:")
    file.store_line("\treturn {")
    var count := 0
    for scene_name in scenes.keys():
        var scene: PackedScene = scenes[scene_name]
        if not _should_include_in_manifest(scene.resource_path):
            continue
        file.store_line("\t\t\"%s\": \"%s\"," % [scene_name, scene.resource_path])
        count += 1
    file.store_line("\t}")
    print("Saved scene manifest with %d entries" % count)

func _load_from_manifest():
    var manifest = load(scene_manifest_path)
    if not manifest:
        print("Scene manifest not found: %s" % scene_manifest_path)
        return
    var paths: Dictionary = manifest.get_scenes()
    for scene_name in paths.keys():
        var scene_resource = load(paths[scene_name])
        if scene_resource:
            scenes[scene_name] = scene_resource

func _scan_directory(path: String):
    #print("Scanning directory: %s" % path)
    var dir = DirAccess.open(path)
    if not dir:
        #print("Failed to open directory: %s" % path)
        return
        
    dir.list_dir_begin()
    var file_name = dir.get_next()
    
    while file_name != "":
        # Skip hidden files/folders
        if file_name.begins_with("."):
            file_name = dir.get_next()
            continue
            
        # Build full path more reliably
        var full_path = path.path_join(file_name)
        #print("  Found: %s (dir: %s)" % [full_path, dir.current_is_dir()])
        
        if dir.current_is_dir():
            #print("  Recursing into: %s" % full_path)
            _scan_directory(full_path)
        elif file_name.ends_with(".tscn"):
            var scene_resource = load(full_path)
            if scene_resource:
                var scene_name = file_name.get_basename()
                scenes[scene_name] = scene_resource
                print("  Loaded scene: %s -> %s" % [scene_name, full_path])
            else:
                print("  Failed to load: %s" % full_path)
        
        file_name = dir.get_next()

func _spawn_actor(instance: Node, parent: Node = null, position: Vector2 = Vector2.INF) -> Node:
    if parent == null:
        if playfield:
            playfield.add_child.call_deferred(instance)
        else:
            get_tree().current_scene.add_child.call_deferred(instance)
    else:
        parent.add_child.call_deferred(instance)

    if position == Vector2.INF:
        position = pen

    if instance.has_method("set_global_position"):
        instance.set_global_position(position)
    elif instance.has_method("set_position"):
        instance.set_position(position)
        
    return instance

func _spawn_scene(scene_name: String, parent: Node = null, position: Vector2 = Vector2.INF) -> Node:
    var instance = scenes[scene_name].instantiate()
    return _spawn_actor( instance, parent, position )

func get_scene(scene_name: String) -> PackedScene:
    return scenes.get(scene_name)

func has_scene(scene_name: String) -> bool:
    return scenes.has(scene_name)
    
func spawn(name: String, parent: Node = null, position: Vector2 = Vector2.INF) -> Node:
    # Spawn by name 
    #if actor_scripts.has(name):
        #return _spawn_actor(name, parent, position)
    if name == "":
        return _spawn_actor(Actor2D.new(), parent, position)
        
    if scenes.has(name):
        return _spawn_scene(name, parent, position)
    else:
        print("Not found: %s" % name)
        return null
# ==================================================================================================
# Actor Script Manager

@export var actor_scripts = {}

func load_all_actor_scripts():
    print("Loading all actor scripts...")
    _scan_directory_for_scripts("res://")
    print("Loaded %d actor scripts" % actor_scripts.size())

func _scan_directory_for_scripts(path: String):
    var dir = DirAccess.open(path)
    if not dir:
        return

    dir.list_dir_begin()
    var file_name = dir.get_next()

    while file_name != "":
        if file_name.begins_with("."):
            file_name = dir.get_next()
            continue

        var full_path = path.path_join(file_name)

        if dir.current_is_dir():
            _scan_directory_for_scripts(full_path)
        elif file_name.ends_with(".gd"):
            _check_if_actor_script(full_path, file_name)

        file_name = dir.get_next()

func _check_if_actor_script(script_path: String, file_name: String):
    var script = load(script_path)
    if script and _extends_actor2d(script):
        var script_name = file_name.get_basename()
        actor_scripts[script_name] = script
        print("  Loaded actor script: %s" % script_name)

func _extends_actor2d(script: Script) -> bool:
    var base = script.get_base_script()
    while base:
        if base.get_global_name() == "Actor2D":
            return true
        base = base.get_base_script()
    return false

func has_actor(actor_name: String) -> bool:
    return actor_scripts.has(actor_name)

func timeout( duration:float, on_timeout = null, one_shot = true ) -> Timer:
    var timer = Timer.new()
    timer.wait_time = duration
    timer.one_shot = one_shot
    timer.autostart = true
    if on_timeout:
        timer.timeout.connect( on_timeout ) # Connect to function
    return timer

## Call a method by name on all actors that have it
func shout(method_name: String, args: Array = []):
    for actor in get_tree().get_nodes_in_group("actors"):
        if actor.has_method(method_name):
            actor.callv(method_name, args)

## Get the center of the viewport
func screen_center() -> Vector2:
    return Vector2(get_viewport().get_visible_rect().size) / 2

## Get mouse position in game coordinates
func mouse_pos() -> Vector2:
    return get_tree().root.get_mouse_position()

## Check if mouse is within the game viewport
func mouse_in_viewport() -> bool:
    var pos = mouse_pos()
    var game_size = Vector2(get_tree().root.content_scale_size)
    return pos.x >= 0 and pos.y >= 0 and pos.x <= game_size.x and pos.y <= game_size.y 

## Find contact point between two positions using raycast against Area2D
## Returns the raycast hit position, or fallback if no hit
func find_contact_point(from: Vector2, to: Vector2, fallback: Vector2 = Vector2.ZERO) -> Vector2:
    var space = get_tree().root.world_2d.direct_space_state
    var query = PhysicsRayQueryParameters2D.create(from, to)
    query.collide_with_areas = true
    query.collide_with_bodies = false
    var result = space.intersect_ray(query)
    return result.position if result else fallback

## Play a sound effect (uses standard Godot mixer)
## Each sound self-chokes (stops previous instance of same sound)
var _sfx_players: Dictionary = {}

func sfx(stream: AudioStream, volume: float = 1.0, bus: String = "SFX" ):
    if not stream: return

    # Stop previous instance of this sound
    if _sfx_players.has(stream):
        var prev = _sfx_players[stream]
        if is_instance_valid(prev):
            prev.stop()
            prev.queue_free()

    var player = AudioStreamPlayer.new()
    player.stream = stream
    player.volume_linear = volume
    player.bus = bus
    add_child(player)
    player.play()
    player.finished.connect(player.queue_free)
    _sfx_players[stream] = player

func _ready():
    get_tree().root.ready.connect(func(): playfield = get_tree().current_scene.get_node_or_null("%Playfield"))
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_process_input(true)
    init_window()
    init_drag()
    init_border()
    init_edit_mode()
    load_all_scenes()
    #load_all_actor_scripts()
