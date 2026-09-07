class_name BBBootSwitches extends Resource

@export var font: Font

@export var system_count: int

@export var error_color: Color
@export var primary_color: Color

@export var error_vertices: PackedVector2Array
func get_error_rect(system_idx: int) -> Rect2:
	assert(system_idx <= system_count)
	
	system_idx *= 2
	var rect := Rect2(error_vertices[system_idx], Vector2.ZERO)
	rect.end = error_vertices[system_idx + 1]
	return rect

@export var progress_quad_count: int # Quads per system
@export var progress_splits: PackedFloat32Array # One split per quad for each system
@export var progress_vertices: PackedVector2Array

func get_progress_weight(quad_idx: int, progress: float) -> float:
	return clampf(remap(progress, progress_splits[quad_idx], progress_splits[quad_idx + 1], 0.0, 1.0), 0.0, 1.0)

func get_progress_quad(system_idx: int, quad_idx: int, weight: float) -> PackedVector2Array:
	assert(system_idx < system_count)
	assert(quad_idx < progress_quad_count)
	
	var offset := system_count * 4 * quad_idx
	
	var from := offset + system_idx * 2
	var to := from + system_count * 2
	
	var points: PackedVector2Array
	points.resize(4)
	
	points[0] = progress_vertices[from]
	points[1] = progress_vertices[from + 1]
	
	# Swizzel these two vertices
	points[2] = points[1].lerp(progress_vertices[to + 1], weight)
	points[3] = points[0].lerp(progress_vertices[to], weight)
	
	return points

@export var success_text: String
@export var success_positions: PackedVector2Array
