extends Node

var random_event_scene: PackedScene = preload("res://Scenes/event_scene.tscn")
var event_timer: float = 5.0
var event_interval: float = 15.0
var _active_event_instance: Node

func _ready() -> void:
	if GameManager.is_on_route:
		start_route()

func start_route() -> void:
	event_timer = event_interval
	emit_signal("route_started")
	
func stop_route() -> void:
	GameManager.is_on_route = false
		
func _process(delta: float) -> void:
	if not GameManager.is_on_route:
		return
		
	event_timer -= delta
	if event_timer <= 0.0:
		trigger_random_event()
		event_timer = event_interval
		
func trigger_random_event() -> void:
	if is_instance_valid(_active_event_instance):
		return
	
	if random_event_scene:
		_active_event_instance = random_event_scene.instantiate()
		get_tree().current_scene.add_child(_active_event_instance)
		if _active_event_instance.has_method("start_random_event"):
			_active_event_instance.start_random_event()
