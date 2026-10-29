extends Node

@export var random_event_scene: PackedScene
var event_timer: float = 0.0
var event_interval: float = 15.0

func start_route() -> void:
	GameManager.is_on_route = true
	GameManager.is_on_boat = true
	event_timer = event_interval
	emit_signal("route_started")
	
func _process(delta: float) -> void:
	if not GameManager.is_on_route:
		return
		
	event_timer -= delta
	if event_timer <= 0.0:
		trigger_random_event()
		event_timer = event_interval
		
func trigger_random_event() -> void:
	if random_event_scene:
		var event_instance = random_event_scene.instantiate()
		get_tree().current_scene.add_child(event_instance)
		event_instance.start_random_event()
