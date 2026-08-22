extends Node3D

static func _animation_root_motion(animation: Animation, root_motion_track: NodePath, start_time: float, delta: float) -> Dictionary[String,Variant]:
	var wrap_around := false
	var end_time := start_time + delta
	if end_time > animation.length:
		if animation.loop_mode == Animation.LoopMode.LOOP_LINEAR:
			end_time -= animation.length
			wrap_around = true
		else:
			end_time = animation.length
	
	var motion: Dictionary[String,Variant]
	
	for t in animation.get_track_count():
		# Find root motion tracks
		if animation.track_get_path(t) != root_motion_track:
			continue
		
		var is_position := animation.track_get_type(t) == Animation.TrackType.TYPE_POSITION_3D
		if is_position || animation.track_get_type(t) == Animation.TrackType.TYPE_ROTATION_3D:
			var key_last := animation.track_get_key_count(t) - 1
			for k in key_last:
				var from_time := animation.track_get_key_time(t, k)
				var from: Variant = animation.track_get_key_value(t, k)
				
				var to_time := animation.track_get_key_time(t, k + 1)
				var to: Variant = animation.track_get_key_value(t, k + 1)
				
				if start_time >= from_time && start_time <= to_time:
					var start_weight := inverse_lerp(from_time, to_time, start_time)
					if is_position:
						motion.start_position = (from as Vector3).lerp(to as Vector3, start_weight)
					else:
						motion.start_rotation = (from as Quaternion).slerp(to as Quaternion, start_weight)
				
				if end_time >= from_time && end_time <= to_time:
					var end_weight := inverse_lerp(from_time, to_time, end_time)
					if is_position:
						motion.end_position = (from as Vector3).lerp(to as Vector3, end_weight)
						if wrap_around:
							motion.end_position += animation.track_get_key_value(t, key_last) as Vector3
					else:
						motion.end_rotation = (from as Quaternion).slerp(to as Quaternion, end_weight)
						if wrap_around:
							motion.end_rotation = (animation.track_get_key_value(t, key_last) as Quaternion) * motion.end_rotation
	
	return motion

const mech_directory := "res://proprietary/loc/mechs/"
const mwep_directory := "res://proprietary/loc/weapons/main/"
const swep_directory := "res://proprietary/loc/weapons/sub/"

@onready var camera_axis := $CameraAxis as Node3D

@onready var mech_option := $TopLeft/MechList as OptionButton

@onready var mwep_option := $TopLeft/MWepList as OptionButton
@onready var mwep_slot := $TopLeft/MWepSlot as SpinBox
@onready var mwep_switch := $TopLeft/MWepSwitch as Button
@onready var mwep_fire := $TopLeft/MWepFire as Button

@onready var swep_option := $TopLeft/SWepList as OptionButton
@onready var swep_slot := $TopLeft/SWepSlot as SpinBox
@onready var swep_switch := $TopLeft/SWepSwitch as Button
@onready var swep_fire := $TopLeft/SWepFire as Button

@onready var standing := $TopRight/Standing as CheckBox
@onready var fully_deployed := $TopRight/FullyDeployed as CheckBox
@onready var movement_state_option := $TopRight/MovementState as OptionButton
@onready var movement_speed_spin := $TopRight/MovementSpeed as SpinBox
@onready var movement_turn_slider := $TopRight/MovementTurn as HSlider
@onready var movement_teleport_check := $TopRight/Teleport as CheckBox

var mech: BBMech

var walk_state: BBMech.MovementState
var walk_position: float

var projectile_flying: bool
@onready var projectile := $Projectile as Node3D

func _ready() -> void:
	var mech_dirs := DirAccess.get_directories_at(mech_directory)
	for mech_id_str in mech_dirs:
		var resource_list := ResourceLoader.list_directory(mech_directory + mech_id_str)
		for resource in resource_list:
			if !resource.ends_with(".mech_scene"):
				continue
			
			var mech_path := mech_directory + mech_id_str + "/" + resource
			
			mech_option.add_item("Mech_%s" % mech_id_str)
			mech_option.set_item_metadata(mech_option.item_count - 1, mech_path)
	
	_add_option_resources(mwep_directory, ".weapon", mwep_option)
	_add_option_resources(swep_directory, ".weapon", swep_option)
	
	for i in BBMech.MovementState.IntermediateStateSentinel:
		var movement_state_name := BBMech.MovementState.find_key(i) as String
		movement_state_option.add_item(movement_state_name)

func _process(_delta: float) -> void:
	standing.button_pressed = mech && mech.is_standing()
	fully_deployed.button_pressed = mech && mech.is_deployed()

func _mech_movement(delta: float) -> void:
	mech.movement_pre_advance()
	
	var movement_playback := mech.get_movement_playback()
	
	if movement_playback.state != walk_state:
		walk_state = movement_playback.state
		walk_position = 0.0
	
	var movement_animation := mech.get_movement_animation()
	
	var animation := movement_animation.animation as Animation
	var animation_delta := delta * movement_animation.speed as float
	
	var root_motion := _animation_root_motion(animation, movement_animation.root_motion_track, walk_position, animation_delta)
	if "start_position" in root_motion && "end_position" in root_motion:
		var walk_vector := root_motion.end_position as Vector3 - root_motion.start_position as Vector3
		mech.translate_object_local(walk_vector)
		#var walk_velocity := walk_vector / animation_delta
	
	if "start_rotation" in root_motion && "end_rotation" in root_motion:
		var walk_rotation := root_motion.end_rotation as Quaternion * (root_motion.start_rotation as Quaternion).inverse()
		mech.quaternion *= walk_rotation
	
	mech.movement_advance(walk_position, movement_playback.position, delta)
	
	walk_position += delta
	if animation.loop_mode == Animation.LoopMode.LOOP_LINEAR && walk_position > movement_playback.length as float:
		walk_position -= movement_playback.length

func _physics_process(delta: float) -> void:
	if mech:
		_mech_movement(delta)
		camera_axis.position = mech.position + Vector3(0.0, 10.0, 0.0)
	
	if projectile_flying:
		projectile.translate(Vector3.BACK * (delta * 180.0))

func _add_option_resources(directory: String, extension: String, option: OptionButton) -> void:
	option.add_item("NONE")
	option.set_item_metadata(option.item_count - 1, "INVALID_PATH")
	
	var res_list := ResourceLoader.list_directory(directory)
	res_list.sort()
	for res_name in res_list:
		if !res_name.ends_with(extension):
			continue
		
		option.add_item(res_name.get_slice(".", 0))
		option.set_item_metadata(option.item_count - 1, directory + res_name)

func _on_mech_switch_pressed() -> void:
	if mech:
		remove_child(mech)
		mech.queue_free()
	
	var mech_path := mech_option.get_selected_metadata() as String
	var valid_mech := ResourceLoader.exists(mech_path)
	
	mwep_option.visible = valid_mech
	mwep_slot.visible = valid_mech
	mwep_switch.visible = valid_mech
	mwep_fire.visible = valid_mech
	
	swep_option.visible = valid_mech
	swep_slot.visible = valid_mech
	swep_switch.visible = valid_mech
	swep_fire.visible = valid_mech
	
	if !valid_mech:
		return
	
	var mech_scene := load(mech_path) as PackedScene
	mech = mech_scene.instantiate() as BBMech
	
	walk_state = BBMech.MovementState.Idle
	walk_position = 0.0
	
	add_child(mech)

func _on_mwep_switch_pressed() -> void:
	if !mech:
		return
	
	var mwep_path := mwep_option.get_selected_metadata() as String
	var mwep_cfg := load(mwep_path) as BBWeaponConfig if ResourceLoader.exists(mwep_path) else null
	var mwep_slot_idx := int(mwep_slot.value)
	
	mech.set_main_weapon(mwep_cfg, mwep_slot_idx)

func _on_mwep_fire_pressed() -> void:
	if !mech:
		return
	
	_fire_weapon(mech.mweps[mech.mwep_idx])

func _on_swep_switch_pressed() -> void:
	if !mech:
		return
	
	var swep_path := swep_option.get_selected_metadata() as String
	var swep_cfg := load(swep_path) as BBWeaponConfig if ResourceLoader.exists(swep_path) else null
	var swep_slot_idx := int(swep_slot.value)
	
	mech.set_sub_weapon(swep_cfg, swep_slot_idx)

func _on_swep_fire_pressed() -> void:
	if !mech:
		return
	
	_fire_weapon(mech.sweps[mech.swep_idx])

func _fire_weapon(wep: BBWeapon) -> void:
	if !wep:
		return
	
	for n in projectile.get_children():
		projectile.remove_child(n)
		n.queue_free()
	
	wep.fire()
	
	projectile.transform = wep.get_muzzle_transform(0)
	
	var p := wep.config.projectile_scene.instantiate()
	projectile.add_child(p)
	
	projectile_flying = true

func _on_projectile_freeze_pressed() -> void:
	projectile_flying = false

func _on_movement_state_item_selected(movement_state: BBMech.MovementState) -> void:
	if !mech:
		return
	
	mech.set_movement_state(movement_state, movement_teleport_check.button_pressed)

func _on_movement_speed_value_changed(value: float) -> void:
	if !mech:
		return
	
	mech.set_movement_speed(value / 3.6)

func _on_movement_turn_value_changed(value: float) -> void:
	if !mech:
		return
	
	mech.set_movement_turning(value)

func _on_hatch_toggled(toggled_on: bool) -> void:
	if !mech:
		return
	
	mech.hatch_closed = toggled_on

func _on_drop_left_tank_pressed() -> void:
	mech.drop_sub_tank(false)

func _on_drop_right_tank_pressed() -> void:
	mech.drop_sub_tank(true)

func _on_drop_armor_pressed() -> void:
	mech.drop_opt_armor()
