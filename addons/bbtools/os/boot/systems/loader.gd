@tool
class_name ResourceFormatLoaderBBBootSwitches extends ResourceFormatLoader

const extension := "boot_switches"

func _load(path: String, _original_path: String, _use_sub_threads: bool, _cache_mode: int) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if !file:
		print("Failed to open file: %s, got error: %s" % [path, error_string(FileAccess.get_open_error())])
		return null
	
	var switches := BBBootSwitches.new()
	
	var system_count := file.get_32()
	
	switches.system_count = system_count
	
	switches.switch_error_color = Color(file.get_8(), file.get_8(), file.get_8(), file.get_8())
	switches.switch_primary_color = Color(file.get_8(), file.get_8(), file.get_8(), file.get_8())
	
	switches.switch_error_vertices = file.get_buffer(system_count * 16).to_vector2_array()
	
	var switch_progress_quad_count := file.get_32()
	switches.switch_progress_quad_count = switch_progress_quad_count
	switches.switch_progress_vertices = file.get_buffer(system_count * switch_progress_quad_count * 32).to_vector2_array()
	
	switches.switch_success_text = file.get_pascal_string()
	switches.switch_success_positions = file.get_buffer(system_count * 8).to_vector2_array()
	
	var startup_progress_count := file.get_32()
	switches.startup_progress_count = startup_progress_count
	switches.startup_progress_positions = file.get_buffer(system_count * startup_progress_count * 8).to_vector2_array()
	
	return switches

func _get_recognized_extensions() -> PackedStringArray:
	return [extension]

func _handles_type(type: StringName) -> bool:
	return ClassDB.is_parent_class(type, "Resource");

func _get_resource_type(path: String) -> String:
	return "Resource" if path.get_extension() == extension else ""

func _get_resource_script_class(path: String) -> String:
	return "BBBootSwitches" if path.get_extension() == extension else ""
