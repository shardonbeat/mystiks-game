extends Node

signal route_started(destination: IslandNodeData)
signal route_progress_updated(progress: float, remaining_seconds: float)
signal route_completed(destination: IslandNodeData)

var random_event_scene: PackedScene = preload("res://Scenes/event_scene.tscn")
var event_timer: float = 5.0
var event_interval: float = 15.0
var _active_event_instance: Node = null

var current_destination: IslandNodeData = null
var travel_duration: float = 0.0
var travel_elapsed: float = 0.0

var is_steering: bool = false

func _ready() -> void:
	if GameManager.is_on_route and current_destination:
		start_route(current_destination)

func _process(delta: float) -> void:
		
	if not GameManager.is_on_route:
		return
	
	if GameManager.is_on_event:
		return
	
	if current_destination != null and is_steering:
		travel_elapsed += delta
		var progress := clampf(travel_elapsed / travel_duration, 0.0, 1.0)
		route_progress_updated.emit(progress, maxf(0.0, travel_duration - travel_elapsed))
			
		if travel_elapsed >= travel_duration:
			_complete_route()
			return
			
	event_timer -= delta
	if event_timer <= 0.0:
		trigger_random_event()
		event_timer = event_interval

func start_route(destination: IslandNodeData) -> void:
	if not destination:
		push_error("RouteManager: Se intentó iniciar una ruta sin destino.")
		return
		
	current_destination = destination
	travel_duration = maxf(destination.travel_duration, 5.0)
	travel_elapsed = 0.0
	event_timer = event_interval
	
	GameManager.is_on_route = true
	route_started.emit(destination)
	
func stop_route() -> void:
	GameManager.is_on_route = false
	current_destination = null
	travel_elapsed = 0.0
		
	
func _complete_route() -> void:
	var arrived_island := current_destination
	
	if arrived_island:
		GameManager.current_island_id = arrived_island.id
		if not GameManager.discovered_islands.has(arrived_island.id):
			GameManager.discovered_islands.append(arrived_island)
			
	GameManager.is_on_route = false
	is_steering = false
	GameManager.reset_mystik_route_state()
	if arrived_island:
		GameManager.current_island_id = arrived_island.id
	current_destination = null
	route_completed.emit(arrived_island)
	print("Ha llegado a su destino.")
		
func trigger_random_event() -> void:
	if is_instance_valid(_active_event_instance):
		return
	
	if random_event_scene:
		_active_event_instance = random_event_scene.instantiate()
		get_tree().current_scene.add_child(_active_event_instance)
		if _active_event_instance.has_method("start_random_event"):
			_active_event_instance.start_random_event()
