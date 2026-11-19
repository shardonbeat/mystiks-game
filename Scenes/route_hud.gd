extends CanvasLayer

@onready var destination_label: Label = $DestinationLabel
@onready var route_bar: TextureProgressBar = $RouteBar
@onready var boat_icon: TextureRect = $RouteBar/TextureRect

const LINE_START_X := 12
const LINE_END_X := 84

func _ready() -> void:
	route_bar.min_value = 0.0
	route_bar.max_value = 1.0
	
	RouteManager.route_started.connect(_on_route_started)
	RouteManager.route_progress_updated.connect(_on_route_progress_updated)
	RouteManager.route_completed.connect(_on_route_completed)
	
	if GameManager.is_on_route and RouteManager.current_destination:
		_on_route_started(RouteManager.current_destination)
	else:
		visible = false
		
func _on_route_started(_destination: IslandNodeData):
	visible = true
	destination_label.text = "Destino: %s" % _destination.display_name
	_update_visuals(0.0)
	
func _on_route_progress_updated(progress: float, _remaining_seconds: float) -> void:
	_update_visuals(progress)
	
func _on_route_completed(_destination: IslandNodeData):
	_update_visuals(1.0)
	await get_tree().create_timer(1.0)
	visible = false
	
func _update_visuals(progress: float):
	route_bar.value = progress
	
	var start_x := route_bar.size.x * 0.25
	var end_x := route_bar.size.x * 1
	
	var tip_x := lerpf(start_x, end_x, progress)
	boat_icon.position.x = tip_x - (boat_icon.size.x / 2.0)
