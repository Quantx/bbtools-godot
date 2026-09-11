@tool
class_name ResourceFormatLoaderBBBootStart extends ResourceFormatLoader

const extension := "boot_start"

func _load(path: String, _original_path: String, _use_sub_threads: bool, _cache_mode: int) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if !file:
		print("Failed to open file: %s, got error: %s" % [path, error_string(FileAccess.get_open_error())])
		return null
	
	var start := BBBootStart.new()
	
	var font_path := file.get_pascal_string()
	start.font = load(font_path) as Font
	
	var linesdefs_path := file.get_pascal_string()
	start.linesdefs = load(linesdefs_path) as BBLinesDefs
	
	var spritedefs_path := file.get_pascal_string()
	start.spritedefs = load(spritedefs_path) as BBSpriteDefs
	
	start.duration = file.get_float()
	
	var progress_line_idx := file.get_8()
	if progress_line_idx == UINT8_MAX:
		progress_line_idx = -1
	
	start.progress_line_idx = progress_line_idx
	
	var completion_line_idx := file.get_8()
	if completion_line_idx == UINT8_MAX:
		completion_line_idx = -1
	
	start.completion_line_idx = completion_line_idx
	
	var progress_sprites_work_idx := file.get_8()
	if progress_sprites_work_idx == UINT8_MAX:
		progress_sprites_work_idx = -1
	
	start.progress_sprites_work_idx = progress_sprites_work_idx
	
	var progress_sprites_done_idx := file.get_8()
	if progress_sprites_done_idx == UINT8_MAX:
		progress_sprites_done_idx = -1
	
	start.progress_sprites_done_idx = progress_sprites_done_idx
	
	var string_count := file.get_32()
	for i in string_count:
		start.text_strings.append(file.get_pascal_string())
		start.text_positions.append(Vector2(file.get_float(), file.get_float()))
	
	start.completion_position = Vector2(file.get_float(), file.get_float())
	
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
