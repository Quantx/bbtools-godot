class_name BBSwitchesPlayer extends Node2D

@export var switches: BBBootSwitches
@export var error_blink_rate := 1.0

var _system_levels: PackedFloat32Array
func set_system(idx: int, level: float) -> void:
	if !switches:
		return
	
	_system_levels.resize(switches.system_count)
	_system_levels[idx] = level
	
	queue_redraw()

var _error_blink: bool
func _process(_delta: float) -> void:
	if !switches || _system_levels.size() < switches.system_count:
		return
	
	var blink_rate := int(error_blink_rate * 1000.0)
	var blink := Time.get_ticks_msec() % blink_rate > blink_rate / 2
	
	if _error_blink != blink:
		_error_blink = blink
		for level in _system_levels:
			if level < 0.0:
				queue_redraw()
				break

func _draw() -> void:
	if !switches || _system_levels.size() < switches.system_count:
		return
	
	for system_idx in switches.system_count:
		var progress := _system_levels[system_idx]
		if progress < 0.0:
			if _error_blink:
				draw_rect(switches.get_error_rect(system_idx), switches.error_color)
			continue
		
		for quad_idx in switches.progress_quad_count:
			var weight := switches.get_progress_weight(quad_idx, progress)
			if weight > 0.0:
				var quads := switches.get_progress_quad(system_idx, quad_idx, weight)
				draw_colored_polygon(quads, switches.primary_color)
		
		if is_equal_approx(progress, 1.0):
			draw_string(switches.font, switches.success_positions[system_idx], switches.success_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, switches.primary_color)
