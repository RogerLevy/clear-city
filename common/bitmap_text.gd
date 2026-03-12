@tool
class_name BitmapText
extends Node2D

enum Justify { LEFT, CENTER, RIGHT }

@export var text: String = "":
	set(v):
		text = v
		queue_redraw()

@export var font_texture: Texture2D
@export var char_width: int = 8
@export var char_height: int = 8
@export var separator: int = 1  # 1px red lines between chars
@export var spacing: int = 0    # extra pixels between drawn chars
@export var justify: Justify = Justify.LEFT:
	set(v):
		justify = v
		queue_redraw()

func _get_text_width() -> int:
	if text.length() == 0: return 0
	return text.length() * char_width + (text.length() - 1) * spacing

func _draw():
	if not font_texture: return
	var cell_w = char_width + separator
	var cell_h = char_height + separator
	var x = 0
	match justify:
		Justify.CENTER: x = -_get_text_width() / 2
		Justify.RIGHT: x = -_get_text_width()
	for i in text.length():
		var c = text.unicode_at(i)
		var col = c % 16
		var row = c / 16
		var src = Rect2(separator + col * cell_w, separator + row * cell_h, char_width, char_height)
		draw_texture_rect_region(font_texture, Rect2(x, 0, char_width, char_height), src)
		x += char_width + spacing
