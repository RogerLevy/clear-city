@tool
extends VBoxContainer

var editor_interface: EditorInterface

const BASE_CLASSES = ["Actor2D", "Vessel2D", "StateMachineCharacterBody2D"]
const OUTPUT_DIR = "res://darkblue/actors/"

@onready var texture_picker: EditorResourcePicker = %TexturePicker
@onready var class_name_edit: LineEdit = %ClassNameEdit
@onready var base_class_option: OptionButton = %BaseClassOption
@onready var frame_width_spin: SpinBox = %FrameWidthSpin
@onready var frame_height_spin: SpinBox = %FrameHeightSpin
@onready var create_button: Button = %CreateButton
@onready var status_label: Label = %StatusLabel

func _ready():
    for bc in BASE_CLASSES:
        base_class_option.add_item(bc)
    base_class_option.select(1)  # Default to Vessel2D

    texture_picker.base_type = "Texture2D"
    texture_picker.resource_changed.connect(_on_texture_changed)
    create_button.pressed.connect(_on_create_pressed)

func _on_texture_changed(resource: Resource):
    if resource:
        var tex = resource as Texture2D
        if tex:
            frame_width_spin.value = tex.get_width()
            frame_height_spin.value = tex.get_height()
        if class_name_edit.text.is_empty():
            # Auto-fill class name from texture filename
            var path = resource.resource_path
            var filename = path.get_file().get_basename()
            class_name_edit.text = filename

func to_snake_case(s: String) -> String:
    var result = ""
    for i in s.length():
        var c = s[i]
        if c == c.to_upper() and c != c.to_lower() and result.length() > 0 and result[-1] != "_":
            result += "_"
        result += c.to_lower()
    return result

func _on_create_pressed():
    var texture = texture_picker.edited_resource as Texture2D
    var cname = class_name_edit.text.strip_edges()
    var base_class = BASE_CLASSES[base_class_option.selected]
    var fw = int(frame_width_spin.value)
    var fh = int(frame_height_spin.value)

    if cname.is_empty():
        status_label.text = "Error: Enter a class name"
        return

    var filename = to_snake_case(cname)
    var script_path = OUTPUT_DIR + filename + ".gd"
    var scene_path = OUTPUT_DIR + filename + ".tscn"

    # Check if files exist
    if FileAccess.file_exists(script_path):
        status_label.text = "Error: " + script_path + " already exists"
        return
    if FileAccess.file_exists(scene_path):
        status_label.text = "Error: " + scene_path + " already exists"
        return

    # Generate script
    var frame_count = 1
    if texture:
        var hframes = max(1, texture.get_width() / fw)
        var vframes = max(1, texture.get_height() / fh)
        frame_count = hframes * vframes
    var script_content = generate_script(cname, base_class, frame_count)
    var f = FileAccess.open(script_path, FileAccess.WRITE)
    if not f:
        status_label.text = "Error: Cannot write " + script_path
        return
    f.store_string(script_content)
    f.close()

    # Generate scene
    var scene_content = generate_scene(cname, filename, texture, fw, fh, base_class)
    f = FileAccess.open(scene_path, FileAccess.WRITE)
    if not f:
        status_label.text = "Error: Cannot write " + scene_path
        return
    f.store_string(scene_content)
    f.close()

    # Refresh and open
    editor_interface.get_resource_filesystem().scan()
    await get_tree().create_timer(0.5).timeout
    editor_interface.open_scene_from_path(scene_path)
    var script = load(script_path)
    if script:
        editor_interface.edit_script(script)

    status_label.text = "Created " + filename

func generate_script(cname: String, base_class: String, frame_count: int) -> String:
    return """@tool
class_name %s
extends %s

static var DEFAULT_ANIM: Array = range(%d)

func init():
	animation = DEFAULT_ANIM
	animationSpeed = 1.0 / 3.0
""" % [cname, base_class, frame_count]

func generate_scene(cname: String, filename: String, texture: Texture2D, fw: int, fh: int, base_class: String) -> String:
    var lines: PackedStringArray = []
    lines.append('[gd_scene format=3]')
    lines.append('')

    var ext_id = 1
    var texture_ext_id = ""
    var script_ext_id = ""

    # External resources
    var script_path = OUTPUT_DIR + filename + ".gd"
    lines.append('[ext_resource type="Script" path="%s" id="%d_script"]' % [script_path, ext_id])
    script_ext_id = '%d_script' % ext_id
    ext_id += 1

    if texture:
        lines.append('[ext_resource type="Texture2D" path="%s" id="%d_tex"]' % [texture.resource_path, ext_id])
        texture_ext_id = '%d_tex' % ext_id
        ext_id += 1

    lines.append('')

    # Sub-resources
    var collision_radius = min(fw, fh) / 2.0
    lines.append('[sub_resource type="CircleShape2D" id="CircleShape2D_1"]')
    lines.append('radius = %.1f' % collision_radius)
    lines.append('')

    # Root node
    var groups = '["enemies"]' if base_class == "Vessel2D" else '["actors"]'
    lines.append('[node name="%s" type="CharacterBody2D" groups=%s]' % [cname, groups])
    lines.append('position = Vector2(100, 100)')
    lines.append('collision_layer = 0')
    lines.append('collision_mask = 0')
    lines.append('script = ExtResource("%s")' % script_ext_id)

    if texture and (base_class == "Actor2D" or base_class == "Vessel2D"):
        lines.append('sprite_texture = ExtResource("%s")' % texture_ext_id)
        lines.append('frame_width = %d' % fw)
        lines.append('frame_height = %d' % fh)

    if base_class == "Vessel2D":
        lines.append('hp = 1')
        lines.append('r = %.1f' % collision_radius)
        lines.append('bounty = 10')

    lines.append('')

    # Sprite2D
    lines.append('[node name="Sprite2D" type="Sprite2D" parent="."]')
    if texture:
        lines.append('texture = ExtResource("%s")' % texture_ext_id)
        var hframes = max(1, texture.get_width() / fw)
        var vframes = max(1, texture.get_height() / fh)
        if hframes > 1:
            lines.append('hframes = %d' % hframes)
        if vframes > 1:
            lines.append('vframes = %d' % vframes)
    lines.append('')

    # Area2D with collision
    lines.append('[node name="Area2D" type="Area2D" parent="."]')
    lines.append('collision_layer = 2')
    lines.append('collision_mask = 0')
    lines.append('')

    lines.append('[node name="CollisionShape2D" type="CollisionShape2D" parent="Area2D"]')
    lines.append('shape = SubResource("CircleShape2D_1")')
    lines.append('')

    return "\n".join(lines)
