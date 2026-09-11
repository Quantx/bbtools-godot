class_name BBStartPlayer extends Node2D

@export var line_thickness := 1.0
@export var line_antialias := false

@export var start: BBBootStart

@export var color: Color

enum Mode {
	Work,
	Pass,
	Fail,
}

var mode := Mode.Work:
	set = set_mode

func set_mode(new_mode: Mode) -> void:
	mode = new_mode
	
	match mode:
		Mode.Work:
			_work_rate = -1
		Mode.Fail:
			var min_level := INF
			for l in _system_levels:
				min_level = minf(min_level, clamp(l, 0.0, 1.0))
			
			_work_rate = int(min_level * 100.0)
		Mode.Pass:
			_work_rate = 100

var time: float:
	set = set_time

func set_time(t: float) -> void:
	if !start:
		time = 0.0
	
	time = clampf(t, 0.0, start.duration)

var _work_rate: int = -1
var _completion_weight: float

var _system_levels: PackedFloat32Array
func set_system(idx: int, level: float) -> void:
	if !start:
		return
	
	_system_levels.resize(start.system_count)
	_system_levels[idx] = level

func _draw_sprite(sprite_idx: int) -> void:
	var sprite: BBSprite = start.spritedefs.defines[sprite_idx]
	
	# The spritesheets all use HUD_01.dds texture, so we need to override that here
	draw_texture_rect_region(sprite.spritesheet.texture, Rect2(sprite.position, sprite.size), sprite.get_texture_rect(), color)

func _draw_lines(color_idx: int, lerp_weight := 1.0) -> void:
	lerp_weight = clampf(lerp_weight, 0.0, 1.0)
	if is_zero_approx(lerp_weight):
		return
	
	var lines := start.linesdefs.defines[color_idx]
	
	if lerp_weight < 1.0:
		var lerped_lines := lines.duplicate() # Don't modify the original lines
		for i in range(0, lines.size(), 2):
			lerped_lines[i + 1] = lines[i].lerp(lines[i + 1], lerp_weight)
		lines = lerped_lines
	
	draw_multiline(lines, color, line_thickness, line_antialias)

func _process(delta: float) -> void:
	_completion_weight = minf(_completion_weight + delta, 1.0) if mode == Mode.Pass else 0.0
	queue_redraw()

func _draw() -> void:
	if !start:
		return
	
	draw_set_transform_matrix(Transform2D.IDENTITY)
	
	# Draw background lines
	_draw_lines(0, time / start.duration)
	if time < start.duration || _system_levels.size() < start.system_count:
		return
	
	# Draw background sprites
	_draw_sprite(3)
	_draw_sprite(4)
	
	# Draw background text
	for i in range(1, start.text_strings.size()):
		draw_string(start.font, start.text_positions[i], start.text_strings[i], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, color)
	
	for system_idx in start.system_count:
		var level := _system_levels[system_idx]
		for progress_idx in start.progress_count:
			var rect := start.get_progress_rect(system_idx, progress_idx, level)
			var alpha := clampf(2.0 - level, 0.0, 1.0)
			draw_rect(rect, Color(color, alpha))
		
		var progress_sprite_idx := start.progress_sprites_work_idx if level <= 1.0 else start.progress_sprites_done_idx
		_draw_sprite(progress_sprite_idx + system_idx)
	
	match mode:
		Mode.Pass:
			_draw_sprite(2)
		Mode.Fail:
			_draw_sprite(0)
	
	# Work rate
	if _work_rate >= 0:
		draw_string(start.font, start.text_positions[0], "%d%%" % _work_rate, HORIZONTAL_ALIGNMENT_RIGHT, 50.0, 16, color)
	
	# Completion bar
	if start.completion_line_idx >= 0 && _completion_weight > 0.0:
		draw_set_transform(start.completion_position, 0.0, Vector2(_completion_weight, 1.0))
		_draw_lines(start.completion_line_idx)
