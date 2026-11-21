extends Node2D

const MAIN_MENU_PATH := "res://Scenes/main_menu.tscn"

@export var animation: AnimationPlayer
@export var zones: Array[PackedScene] = []
@export var boat_zone_index: int = 3

var _current_zone: int = 1
var _instanciated_zone: Node

@onready var map_scene: PackedScene = preload("res://map/navigation_map.tscn")
var _current_map_instance: Node = null

@export var top_bar: ColorRect
@export var bottom_bar: ColorRect

var _saved_zoom: Vector2 = Vector2.ONE
var _is_cinematic_active: bool = false
var _cinematic_tween: Tween

func _ready() -> void:
	RouteManager.route_completed.connect(_on_route_completed)
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

func _create_lvl(lvl_num: int) -> void:
	var is_boat: bool = (lvl_num == boat_zone_index)
	GameManager.is_on_boat = is_boat
	GameManager.is_on_route = is_boat
	
	_instanciated_zone = zones[lvl_num - 1].instantiate()
	add_child(_instanciated_zone)

func _delete_lvl() -> void:
	if is_instance_valid(_instanciated_zone):
		_instanciated_zone.queue_free()

func on_go_to_main_menu() -> void:
	get_tree().paused = false
	GameManager.change_scene_with_fade(MAIN_MENU_PATH)

func show_map(allow_routing: bool) -> void:
	if not map_scene:
		print("ERROR: No hay mapa asignado.")
		return
	if is_instance_valid(_current_map_instance):
		return
	
	GameManager.is_on_event = true
	_current_map_instance = map_scene.instantiate()
	_current_map_instance.can_plot_route = allow_routing
	_current_map_instance.route_confirmed.connect(_on_route_confirmed)
	get_tree().current_scene.add_child(_current_map_instance)

func _on_route_completed(destination: IslandNodeData) -> void:
	if destination and destination.zone_index > 0:
		change_zone(destination.zone_index)

func _on_route_confirmed(target_data: IslandNodeData) -> void:
	RouteManager.start_route(target_data)
	change_zone(boat_zone_index)

func play_cinematic_bars(active: bool, target_zoom: Vector2 = Vector2(1.5, 1.5), duration: float = 1.0) -> void:
	if _cinematic_tween and _cinematic_tween.is_valid():
		_cinematic_tween.kill()
		
	var camera = get_viewport().get_camera_2d()
	var viewport_height = get_viewport().get_visible_rect().size.y
	var bar_thickness = top_bar.size.y if top_bar else 100.0
	
	if active and not _is_cinematic_active and camera:
		_saved_zoom = camera.zoom
		
	_is_cinematic_active = active
	
	_cinematic_tween = create_tween().set_parallel(true)
	_cinematic_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	if active:
		if camera:
			_cinematic_tween.tween_property(camera, "zoom", target_zoom, duration)
		if top_bar and bottom_bar:
			_cinematic_tween.tween_property(top_bar, "position:y", 0.0, duration)
			_cinematic_tween.tween_property(bottom_bar, "position:y", viewport_height - bar_thickness, duration)
	else:
		if camera:
			_cinematic_tween.tween_property(camera, "zoom", _saved_zoom, duration)
		if top_bar and bottom_bar:
			_cinematic_tween.tween_property(top_bar, "position:y", -bar_thickness - 5.0, duration)
			_cinematic_tween.tween_property(bottom_bar, "position:y", viewport_height + 5.0, duration)
			
	await _cinematic_tween.finished
