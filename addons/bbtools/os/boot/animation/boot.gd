class_name BBBoot extends Resource

@export var font: Font
@export var strings_path: String# = "res://proprietary/loc/os/boot/strings.txt"

@export var texture: Texture2D
@export var spritesheet: BBSpriteSheet

@export var linesdefs: BBLinesDefs

@export var duration: float
@export var draws: Array[BBBootDrawBase]

func get_spritesheet_region(idx: int) -> Rect2:
	return spritesheet.frames[idx].image_region(texture.get_size())

var _strings: PackedStringArray
func get_strings() -> PackedStringArray:
	if _strings.is_empty():
		var strings_file := FileAccess.open(strings_path, FileAccess.READ)
		_strings = strings_file.get_as_text().split("\n")
		for i in _strings.size():
			_strings[i] = _strings[i].strip_edges()
	
	return _strings
