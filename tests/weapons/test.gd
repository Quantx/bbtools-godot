extends Node3D

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
	
	movement_state_option.clear()
	for state in MovementState.size():
		if _movement_state_flags[state] & _MOVEMENT_STATE_FLAG_UNTARGETABLE:
			continue
		
		var movement_state_name := MovementState.find_key(state) as String
		movement_state_option.add_item(movement_state_name)
		movement_state_option.set_item_metadata(movement_state_option.item_count - 1, state)

func _process(_delta: float) -> void:
	standing.button_pressed = is_standing()
	fully_deployed.button_pressed = is_deployed()

func _mech_movement(delta: float) -> void:
	movement_process(delta)
	
	movement_play()
	
	if "position" in root_motion:
		mech.translate_object_local(root_motion.position as Vector3)
	
	if "rotation" in root_motion:
		mech.quaternion *= root_motion.rotation as Quaternion
	
	#mech.movement_pre_advance()
	#
	#var movement_playback := mech.get_movement_playback()
	#
	#if movement_playback.state != walk_state:
		#walk_state = movement_playback.state
		#walk_position = 0.0
	#
	#var movement_animation := mech.get_movement_animation()
	#
	#var animation := movement_animation.animation as Animation
	#var animation_delta := delta * movement_animation.speed as float
	#
	#var root_motion := _animation_root_motion(animation, movement_animation.root_motion_track, walk_position, animation_delta)
	#if "start_position" in root_motion && "end_position" in root_motion:
		#var walk_vector := root_motion.end_position as Vector3 - root_motion.start_position as Vector3
		#mech.translate_object_local(walk_vector)
		##var walk_velocity := walk_vector / animation_delta
	#
	#if "start_rotation" in root_motion && "end_rotation" in root_motion:
		#var walk_rotation := root_motion.end_rotation as Quaternion * (root_motion.start_rotation as Quaternion).inverse()
		#mech.quaternion *= walk_rotation
	#
	#mech.movement_advance(walk_position, movement_playback.position, delta)
	#
	#walk_position += delta
	#if animation.loop_mode == Animation.LoopMode.LOOP_LINEAR && walk_position > movement_playback.length as float:
		#walk_position -= movement_playback.length

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
	
	movement_target_state = MovementState.Idle
	movement_current_state = MovementState.Idle
	movement_current_position = 0.0
	
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

func _on_movement_state_item_selected(index: int) -> void:
	if !mech:
		return
	
	var state := movement_state_option.get_item_metadata(index) as MovementState
	set_movement_target(state)

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

#region movement
static func animation_root_motion(animation: Animation, root_motion_track: NodePath, start_time: float, delta: float) -> Dictionary[String, Variant]:
	var end_time := start_time + delta
	
	var motion: Dictionary[String, Variant]
	
	for t in animation.get_track_count():
		# Find root motion tracks
		if animation.track_get_path(t) != root_motion_track:
			continue
		
		match animation.track_get_type(t):
			Animation.TrackType.TYPE_POSITION_3D:
				motion.start_position = animation.position_track_interpolate(t, start_time)
				motion.end_position = animation.position_track_interpolate(t, end_time)
				motion.position = motion.end_position as Vector3 - motion.start_position as Vector3
				motion.velocity = motion.position / maxf(delta, 0.01)
			Animation.TrackType.TYPE_ROTATION_3D:
				motion.start_rotation = animation.rotation_track_interpolate(t, start_time)
				motion.end_rotation = animation.rotation_track_interpolate(t, end_time)
				motion.rotation = motion.end_rotation as Quaternion * (motion.start_rotation as Quaternion).inverse()
	
	return motion

enum MovementState {
	None,
	
	Idle,
	TurnRight,
	TurnLeft,
	
	Reverse,
	Walk,
	Run,
	Wheel,
	
	Melee,
	
	DeployOpen,
	DeployIdle,
	DeployClose,
	
	SlideFront,
	SlideBack,
	SlideRight,
	SlideLeft,
	
	FallFront,
	FallBack,
	FallRight,
	FallLeft,
	
	RiseFront,
	RiseBack,
	RollRight,
	RollLeft,
	
	DeathTorso,
	DeathTorsoMirror,
	DeathLegRight,
	DeathLegLeft,
}

const _MOVEMENT_STATE_FLAG_ANIM_MASK := 0xFF
const _MOVEMENT_STATE_FLAG_UNSKIPPABLE := 0x100 # This animation must be played to completion before continuing
const _MOVEMENT_STATE_FLAG_UNTARGETABLE := 0x200 # An intermediate movement state that cannot be targeted
const _MOVEMENT_STATE_FLAG_MIRRORED := 0x400 # The mirror of this animation should be played instead
const _MOVEMENT_STATE_FLAG_FALLEN := 0x800 # The mech has fallen and is not standing

const _movement_state_flags: PackedInt32Array = [
	0 | _MOVEMENT_STATE_FLAG_UNTARGETABLE, # None
	
	0, # Idle
	5, # TurnRight
	5 | _MOVEMENT_STATE_FLAG_MIRRORED, # TurnLeft
	
	4, # Reverse
	1, # Walk
	2, # Run
	3, # Wheel
	
	20, # Melee
	
	21 | _MOVEMENT_STATE_FLAG_UNSKIPPABLE, # DeployOpen
	22 | _MOVEMENT_STATE_FLAG_UNTARGETABLE, # DeployIdle
	23 | _MOVEMENT_STATE_FLAG_UNSKIPPABLE | _MOVEMENT_STATE_FLAG_UNTARGETABLE, # DeployClose
	
	6, # SlideFront
	8, # SlideBack
	7, # SlideRight
	7 | _MOVEMENT_STATE_FLAG_MIRRORED, # SlideLeft
	
	9 | _MOVEMENT_STATE_FLAG_UNSKIPPABLE | _MOVEMENT_STATE_FLAG_FALLEN, # FallFront
	13 | _MOVEMENT_STATE_FLAG_UNSKIPPABLE | _MOVEMENT_STATE_FLAG_FALLEN, # FallBack
	10 | _MOVEMENT_STATE_FLAG_UNSKIPPABLE | _MOVEMENT_STATE_FLAG_FALLEN, # FallRight
	10 | _MOVEMENT_STATE_FLAG_UNSKIPPABLE | _MOVEMENT_STATE_FLAG_FALLEN | _MOVEMENT_STATE_FLAG_MIRRORED, # FallLeft
	
	14 | _MOVEMENT_STATE_FLAG_UNSKIPPABLE | _MOVEMENT_STATE_FLAG_UNTARGETABLE | _MOVEMENT_STATE_FLAG_FALLEN, # RiseFront
	15 | _MOVEMENT_STATE_FLAG_UNSKIPPABLE | _MOVEMENT_STATE_FLAG_UNTARGETABLE | _MOVEMENT_STATE_FLAG_FALLEN, # RiseBack
	12 | _MOVEMENT_STATE_FLAG_UNSKIPPABLE | _MOVEMENT_STATE_FLAG_UNTARGETABLE | _MOVEMENT_STATE_FLAG_FALLEN, # RollRight
	12 | _MOVEMENT_STATE_FLAG_UNSKIPPABLE | _MOVEMENT_STATE_FLAG_UNTARGETABLE | _MOVEMENT_STATE_FLAG_FALLEN | _MOVEMENT_STATE_FLAG_MIRRORED, # RollLeft
	
	17 | _MOVEMENT_STATE_FLAG_UNSKIPPABLE, # DeathTorso
	17 | _MOVEMENT_STATE_FLAG_UNSKIPPABLE | _MOVEMENT_STATE_FLAG_MIRRORED, # DeathTorsoMirror
	16 | _MOVEMENT_STATE_FLAG_UNSKIPPABLE | _MOVEMENT_STATE_FLAG_MIRRORED, # DeathLegRight
	16 | _MOVEMENT_STATE_FLAG_UNSKIPPABLE, # DeathLegLeft
]

var movement_target_state: MovementState
var movement_current_state: MovementState
var movement_current_position: float
var movement_done: bool
var movement_blend: float

var root_motion: Dictionary

# https://github.com/godotengine/godot/blob/master/scene/animation/animation_player.cpp
func set_movement_target(target: MovementState) -> void:
	var flags := _movement_state_flags[target]
	if flags & _MOVEMENT_STATE_FLAG_UNTARGETABLE:
		push_error("Cannot target movement state: %s" % MovementState.find_key(target))
		return
	
	movement_target_state = target

static func id_to_animation_name(id: int, mirrored: bool) -> StringName:
	return (&"Anim_%dM" if mirrored else &"Anim_%d") % id

func get_chassis_animation(animation_name: StringName) -> Animation:
	if !mech:
		return null
	
	return mech.chassis_anim_player.get_animation(animation_name)

func get_animation_speed(animation_id: int) -> float:
	if movement_current_state == MovementState.TurnRight || movement_current_state == MovementState.TurnLeft:
		return movement_turn_slider.value
	
	if animation_id in mech.chassis_root_motion_speeds:
		return movement_speed_spin.value / (mech.chassis_root_motion_speeds[animation_id] * 3.6)
	
	return 1.0

func movement_process(delta: float) -> void: 
	var flags := _movement_state_flags[movement_current_state]
	var animation_id := flags & _MOVEMENT_STATE_FLAG_ANIM_MASK
	
	var animation := get_chassis_animation(id_to_animation_name(animation_id, flags & _MOVEMENT_STATE_FLAG_MIRRORED))
	assert(animation != null)
	
	# Apply speed scaling
	delta *= get_animation_speed(animation_id)
	
	# Compute root motion for this movement
	root_motion = animation_root_motion(animation, mech.chassis_anim_player.root_motion_track, movement_current_position, delta)
	
	movement_current_position += delta
	movement_done = movement_current_position >= animation.length
	
	if !movement_done && flags & _MOVEMENT_STATE_FLAG_UNSKIPPABLE:
		# Finish the current animation if it's unskippable
		return
	
	var next_state := MovementState.None
	
	# Autoplay next state
	match movement_current_state:
		MovementState.FallRight:
			next_state = MovementState.RollRight
		MovementState.FallLeft:
			next_state = MovementState.RollLeft
		
		MovementState.DeployOpen:
			next_state = MovementState.DeployIdle
		
		MovementState.RiseBack, MovementState.RiseFront, \
		MovementState.DeployClose:
		#MovementState.DeathTorso, MovementState.DeathTorsoMirror, MovementState.DeathLegRight, MovementState.DeathLegLeft:
			next_state = MovementState.Idle
	
	if next_state == MovementState.None:
		if _movement_state_flags[movement_current_state] & _MOVEMENT_STATE_FLAG_FALLEN:
			if !(_movement_state_flags[movement_target_state] & _MOVEMENT_STATE_FLAG_FALLEN):
				# Standup
				if movement_current_state == MovementState.FallFront:
					next_state = MovementState.RiseFront
				else: # MovementState.FallBack, MovementState.RollRight, MovementState.RollLeft
					next_state = MovementState.RiseBack
		elif movement_current_state == MovementState.DeployIdle:
			if movement_target_state != MovementState.DeployOpen:
				# Undeploy
				next_state = MovementState.DeployClose
		elif movement_current_state != movement_target_state:
			next_state = movement_target_state
	
	if next_state == MovementState.None:
		if movement_done:
			match animation.loop_mode:
				Animation.LoopMode.LOOP_NONE:
					movement_current_position = animation.length
				Animation.LoopMode.LOOP_LINEAR:
					movement_current_position = fposmod(movement_current_position, animation.length)
					movement_done = false
				Animation.LoopMode.LOOP_PINGPONG:
					push_error("LOOP_PINGPONG is unsupported")
		return
	
	# TODO: Godot cannot properly blend short animations from the animation player. This results in weird clipping. So just set the blending to 0.2 seconds
	movement_blend = 0.2
	#if movement_current_state == MovementState.Melee || next_state == MovementState.Melee:
		#movement_blend = 0.75
	#elif movement_current_state == MovementState.TurnRight || movement_current_state == MovementState.TurnLeft:
		#movement_blend = 1.0
	
	movement_current_state = next_state
	movement_current_position = 0.0
	movement_done = false

func movement_play() -> void:
	if !mech:
		return
	
	var anim_player := mech.chassis_anim_player
	
	var flags := _movement_state_flags[movement_current_state]
	var animation_id := flags & _MOVEMENT_STATE_FLAG_ANIM_MASK
	
	if !movement_done:
		var animation_name := id_to_animation_name(animation_id, flags & _MOVEMENT_STATE_FLAG_MIRRORED)
		if anim_player.current_animation != animation_name:
			anim_player.play(animation_name)
	
	var length := anim_player.current_animation_length
	if absf(fposmod(movement_current_position - anim_player.current_animation_position + length * 0.5, length) - length * 0.5) > 0.1:
		# The playback speed has no effect on seeking
		anim_player.seek(movement_current_position)
	
	anim_player.speed_scale = get_animation_speed(animation_id)

func is_standing() -> bool:
	return !(_movement_state_flags[movement_current_state] & _MOVEMENT_STATE_FLAG_FALLEN)

func is_rising() -> bool:
	return movement_current_state == MovementState.RiseFront || movement_current_state == MovementState.RiseBack

func is_deployed() -> bool:
	return movement_current_state == MovementState.DeployIdle
#endregion
