@tool
class_name ResourceFormatLoaderBBBootSwitches extends ResourceFormatLoader

const extension := "boot_switches"

func _load(path: String, _original_path: String, _use_sub_threads: bool, _cache_mode: int) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if !file:
		print("Failed to open file: %s, got error: %s" % [path, error_string(FileAccess.get_open_error())])
		return null
	
	var switches := BBBootSwitches.new()
	
	var font_path := file.get_pascal_string()
	switches.font = load(font_path) as Font
	
	var system_count := file.get_32()
	
	switches.system_count = system_count
	
	switches.error_color = Color.from_rgba8(file.get_8(), file.get_8(), file.get_8(), file.get_8())
	switches.primary_color = Color.from_rgba8(file.get_8(), file.get_8(), file.get_8(), file.get_8())
	
	switches.error_vertices = file.get_buffer(system_count * 16).to_vector2_array()
	
	var progress_quad_count := file.get_32()
	switches.progress_quad_count = progress_quad_count
	switches.progress_splits = PackedFloat32Array([0.0]) + file.get_buffer(progress_quad_count * 4).to_float32_array()
	switches.progress_vertices = file.get_buffer(system_count * progress_quad_count * 32).to_vector2_array()
	
	switches.success_text = file.get_pascal_string()
	switches.success_positions = file.get_buffer(system_count * 8).to_vector2_array()
	
	return switches

func _get_recognized_extensions() -> PackedStringArray:
	return [extension]

func _handles_type(type: StringName) -> bool:
	return ClassDB.is_parent_class(type, "Resource");

func _get_resource_type(path: String) -> String:
	return "Resource" if path.get_extension() == extension else ""

func _get_resource_script_class(path: String) -> String:
	return "BBBootSwitches" if path.get_extension() == extension else ""
