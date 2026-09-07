@tool
class_name ResourceFormatLoaderBBBootStart extends ResourceFormatLoader

const extension := "boot_start"

func _load(path: String, _original_path: String, _use_sub_threads: bool, _cache_mode: int) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if !file:
		print("Failed to open file: %s, got error: %s" % [path, error_string(FileAccess.get_open_error())])
		return null
	
	var start := BBBootStart.new()
	
	var system_count := file.get_32()
	
	start.system_count = system_count
	
	var progress_count := file.get_32()
	start.progress_count = progress_count
	start.progress_positions = file.get_buffer(system_count * progress_count * 8).to_vector2_array()
	
	return start

func _get_recognized_extensions() -> PackedStringArray:
	return [extension]

func _handles_type(type: StringName) -> bool:
	return ClassDB.is_parent_class(type, "Resource");

func _get_resource_type(path: String) -> String:
	return "Resource" if path.get_extension() == extension else ""

func _get_resource_script_class(path: String) -> String:
	return "BBBootStart" if path.get_extension() == extension else ""
