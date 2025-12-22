extends CanvasLayer

var canvas_item

func _input(event):
    if event.is_action_pressed("toggle_fullscreen"):
        if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
        elif DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_files_dropped( files ):
    print("Files dropped:")
    for file in files:
        print("  ", file)	

func init_window():
    if not OS.has_feature("editor") and DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
        get_window().size *= 2
        var screen_size = DisplayServer.screen_get_size()
        var window_size = get_window().size
        get_window().position = (screen_size - window_size) / 2	
    
func init_drag():
    get_viewport().files_dropped.connect(_on_files_dropped)

func init_border():
    # RenderingServer.set_default_clear_color(Color(0.1, 0.1, 0.2))  # dark blue
    layer = 100
    follow_viewport_enabled = false  # Draw in screen space, not viewport space
    follow_viewport_scale = 1.0  # Prevent viewport scale from affecting this layer
            
    var border = Control.new()
    add_child(border)
    border.set_script(preload("res://common/draw_border.gd"))

func init_mouse():
    if not OS.has_feature("editor"):
        Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _ready():
    init_window()
    init_drag()
    init_border()
    init_mouse()
    load_all_scenes()
    
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

func load_all_scenes():
    print("Loading all scenes...")
    _scan_directory("res://")
    print("Loaded %d scenes" % scenes.size())
    
    ## Debug: print all loaded scenes
    #for scene_name in scenes.keys():
        #print("  - %s" % scene_name)

func _scan_directory(path: String):
    print("Scanning directory: %s" % path)
    var dir = DirAccess.open(path)
    if not dir:
        print("Failed to open directory: %s" % path)
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
        print("  Found: %s (dir: %s)" % [full_path, dir.current_is_dir()])
        
        if dir.current_is_dir():
            print("  Recursing into: %s" % full_path)
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
    
    print("Finished scanning: %s" % path)

func spawn_actor(actor_name:String):
    pass

func spawn_scene(scene_name: String, parent: Node = null, position: Vector2 = Vector2.INF) -> Node:
    # Spawn a scene by name
    if not scenes.has(scene_name):
        print("Scene not found: %s" % scene_name)
        return null
    
    var instance = scenes[scene_name].instantiate()
    if parent == null:
        get_tree().current_scene.add_child(instance)
    else:
        parent.add_child(instance)
    
    if position != Vector2.INF:
        position = pen
    
    if instance.has_method("set_global_position"):
        instance.set_global_position(position)
    elif instance.has_method("set_position"):
        instance.set_position(position)
    
    return instance

func get_scene(scene_name: String) -> PackedScene:
    # Get scene resource directly if you need more control
    return scenes.get(scene_name)

func has_scene(scene_name: String) -> bool:
    # Check if scene exists
    return scenes.has(scene_name)
