extends Node2D

@export var animation: AnimationPlayer
@export var zones: Array[PackedScene] =  []
@export var boat_zone_index: int = 2

var _current_zone: int = 1 
var _instanciated_zone: Node

func _ready() -> void:
	if zones.is_empty():
		push_error("THERE ARE NO ZONES.")
		return
	_create_lvl(_current_zone)
	
func change_zone(zone_num: int) -> void:
	if zones.is_empty():
		return
	if zone_num < 1 or zone_num > zones.size():
		print("Zone index ", zone_num, " out of bounds.")
		return
		
	if is_instance_valid(_instanciated_zone):
		var player = _instanciated_zone.find_child("Player", true, false)
		if player:
			player.set_physics_process(false)
			player.set_process_unhandled_input(false)
		
	animation.play("transition_out")
	await animation.animation_finished
	_delete_lvl()
	_current_zone = zone_num
	_create_lvl(_current_zone)
	await get_tree().create_timer(0.5).timeout
	animation.play_backwards("transition_out")
	
func _create_lvl(lvl_num: int):
	var is_boat: bool = (lvl_num == boat_zone_index)
	GameManager.is_on_boat = is_boat
	GameManager.is_on_route = is_boat
	
	_instanciated_zone = zones[lvl_num - 1].instantiate()
	add_child(_instanciated_zone)

func _delete_lvl():
	if is_instance_valid(_instanciated_zone):
		_instanciated_zone.queue_free()
