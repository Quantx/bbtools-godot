class_name BBObject extends Node3D

enum Flags {
	DontPlaceOnTerrain = 0x1,
	
	DeathmatchSpawn_Container = 0x4,
	
	Netting = 0x400,
	Objective = 0x2000,
	Resupply = 0x4000,
	ConquestSpawn = 0x8000,
}

@export var life: int
@export var id: int

@export var flags: int

@export var team_id: int

@export var ticket_value: int
@export var spawn_index: int
