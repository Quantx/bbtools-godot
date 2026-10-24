class_name BBAnimationSequence extends Node

signal flags_event(flags : int)

@export var skeleton: Skeleton3D
@export var raycast_excludes: Array[CollisionObject3D]
@export_flags_3d_physics var raycast_mask := 0x1 | 0x10 # Terrain and World Physics

const expected_surface_effects_size := BBHitbox.Surface.Max * 9
@export var surface_effects: PackedInt32Array

var _effects_one_shot : bool
var _sounds_one_shot : bool
var _flags_one_shot : bool

func _effects_callback(effect_args_list: Array) -> void:
	if _effects_one_shot:
		return
	_effects_one_shot = true
	
	for effect_args: Dictionary in effect_args_list:
		_spawn_effect(effect_args)

func _sounds_callback(sound_args_list: Array) -> void:
	if _sounds_one_shot:
		return
	_sounds_one_shot = true
	
	for sound_args: Dictionary in sound_args_list:
		pass

func _flags_callback(flags: int) -> void:
	if _flags_one_shot:
		return
	_flags_one_shot = true
	
	flags_event.emit(flags)

# There's a "bug" in the animation mixer that causes Method Tracks to be called multiple times due to blending
# The "mixer_applied" signal is fired after all the Method Tracks are called and can be used to reset the one shots
func on_mixer_applied() -> void:
	_effects_one_shot = false
	_sounds_one_shot = false
	_flags_one_shot = false

var _effect_ray_query_parameters := PhysicsRayQueryParameters3D.new()
var _effect_intersect_ray_result := PhysicsIntersectRayResult3D.new()
func _spawn_effect(args: Dictionary) -> void:
	var bone_idx := skeleton.find_bone(args.attach_bone as String)
	assert(bone_idx >= 0)
	
	var effect_config := args.get("effect", null) as BBEffectConfigGroup
	
	if "surface_idx" in args:
		# Get surface type from raycast
		var attach_transform := skeleton.global_transform * skeleton.get_bone_global_pose(bone_idx)
		var attach_position := attach_transform * (args.position as Vector3)
		
		_effect_ray_query_parameters.from = attach_position - Vector3(0, 10, 0)
		_effect_ray_query_parameters.to = attach_position + Vector3(0, 10, 0)
		_effect_ray_query_parameters.collision_mask = raycast_mask
		
		_effect_ray_query_parameters.exclude = []
		for n in raycast_excludes:
			if is_instance_valid(n):
				_effect_ray_query_parameters.exclude.append(n.get_rid())
		
		var space_state := skeleton.get_world_3d().direct_space_state
		if space_state.intersect_ray_into(_effect_ray_query_parameters, _effect_intersect_ray_result):
			var surface := BBHitbox.surface_from_ray(_effect_intersect_ray_result)
			if surface != BBHitbox.Surface.None:
				effect_config = BBEffectManager.load_surface(args.surface_idx as int, surface, surface_effects)
	
	if effect_config:
		args.attach_node = skeleton
		BBEffectManager.spawn(effect_config, args, self)
