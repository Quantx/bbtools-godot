class_name BBBootStart extends Resource

@export var font: Font

@export var linesdefs: BBLinesDefs
@export var spritedefs: BBSpriteDefs

@export var duration: float

@export var progress_line_idx: int
@export var completion_line_idx: int

@export var progress_sprites_work_idx: int
@export var progress_sprites_done_idx: int

@export var text_strings: PackedStringArray
@export var text_positions: PackedVector2Array

@export var completion_position: Vector2

@export var system_count: int

@export var progress_count: int # Progress bars per system
@export var progress_positions: PackedVector2Array # Position of the progress bar on the screen

var _progress_rects: Array[Rect2]
func _init_progress_rects() -> void:
	var lines := linesdefs.defines[progress_line_idx]
	
	var min := Vector2.INF
	var max := -Vector2.INF
	
	for p in lines:
		min = p.min(min)
		max = p.max(max)
	
	var rect: Rect2
	rect.position = min
	rect.end = max
	
	_progress_rects.resize(system_count * progress_count)
	for i in system_count * progress_count:
		_progress_rects[i] = rect
		_progress_rects[i].position += progress_positions[i]

func get_progress_rect(system_idx: int, progress_idx: int, weight: float) -> Rect2:
	if progress_line_idx < 0:
		return Rect2()
	
	if _progress_rects.is_empty():
		_init_progress_rects()
	
	assert(system_idx < system_count)
	assert(progress_idx < progress_count)
	
	var idx := progress_idx * system_count + system_idx
	
	var rect := _progress_rects[idx]
	rect.size.x *= clampf(weight, 0.0, 1.0)
	
	# TODO: Figure about a better way to do this
	if progress_idx % 2 == 1:
		rect.position.x -= rect.size.x
	
	return rect

func get_completion_lines() -> PackedVector2Array:
	if completion_line_idx < 0:
		return PackedVector2Array()
	
	return linesdefs.defines[completion_line_idx]
