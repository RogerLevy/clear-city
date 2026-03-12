@tool
extends Node2D

# Run this script in the editor to generate tri sprite sheet
# Add to a scene, select the node, and click "Capture" in the inspector

@export var capture: bool = false:
    set(value):
        if value and Engine.is_editor_hint():
            generate_sprite_sheet()

const FRAME_COUNT = 72
const FRAME_SIZE = 16

func generate_sprite_sheet():
    print("Generating tri sprite sheet...")

    # Create viewport for rendering
    var viewport = SubViewport.new()
    viewport.size = Vector2i(FRAME_SIZE, FRAME_SIZE)
    viewport.transparent_bg = true
    viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
    add_child(viewport)

    # Create polygon (same as tri.tscn)
    var polygon = Polygon2D.new()
    polygon.position = Vector2(FRAME_SIZE / 2, FRAME_SIZE / 2)
    polygon.scale = Vector2(0.667, 0.667)
    polygon.color = Color(0.498, 0.498, 0.667, 1.0)
    polygon.polygon = PackedVector2Array([
        Vector2(0, -10),
        Vector2(8.66, 5),
        Vector2(-8.66, 5)
    ])
    viewport.add_child(polygon)

    # Create line (outline) - without cutout shader for capture
    var line = Line2D.new()
    line.position = Vector2(FRAME_SIZE / 2, FRAME_SIZE / 2)
    line.scale = Vector2(0.667, 0.667)
    line.points = PackedVector2Array([
        Vector2(0, -10),
        Vector2(8.66, 5),
        Vector2(-8.66, 5),
        Vector2(0, -10)
    ])
    line.width = 2.0
    line.default_color = Color(0.3, 0.3, 0.5, 1.0)  # Darker outline
    viewport.add_child(line)

    # Create output image
    var sheet = Image.create(FRAME_SIZE * FRAME_COUNT, FRAME_SIZE, false, Image.FORMAT_RGBA8)

    # Capture each frame
    for i in FRAME_COUNT:
        var angle = i * (TAU / FRAME_COUNT)
        polygon.rotation = angle
        line.rotation = angle

        # Force render
        viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
        await RenderingServer.frame_post_draw

        # Capture
        var frame = viewport.get_texture().get_image()
        sheet.blit_rect(frame, Rect2i(0, 0, FRAME_SIZE, FRAME_SIZE), Vector2i(i * FRAME_SIZE, 0))

    # Save
    var path = "res://darkblue/actors/tri_sheet.png"
    sheet.save_png(path)
    print("Saved: ", path)

    # Cleanup
    viewport.queue_free()
    print("Done! Reimport the texture in Godot.")
