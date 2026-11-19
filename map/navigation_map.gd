extends CanvasLayer

signal route_confirmed(target_data: IslandNodeData)

@onready var map_world: Node2D = $MapWorld
@onready var map_texture: TextureRect = $MapWorld/mapTexture
@onready var route_line: Line2D = $MapWorld/RouteLine
@onready var exit_button: Button = $HUD/ExitButton
@onready var info_panel: PanelContainer = $HUD/InfoPanel
@onready var zone_image: TextureRect = $HUD/InfoPanel/MarginContainer/VBoxContainer/ZoneImage
@onready var title_label: Label = $HUD/InfoPanel/MarginContainer/VBoxContainer/TitleLabel
@onready var cost_label: Label = $HUD/InfoPanel/MarginContainer/VBoxContainer/CostLabel
@onready var desc_label: RichTextLabel = $HUD/InfoPanel/MarginContainer/VBoxContainer/DescLabel
@onready var sail_button: Button = $HUD/InfoPanel/MarginContainer/VBoxContainer/SailButton

@onready var fog_overlay: ColorRect = $MapWorld/FogOverlay

var can_plot_route: bool = true

var _is_dragging: bool = false
var _drag_start_pos: Vector2 = Vector2.ZERO
const DRAG_THRESHOLD := 5.0

var _points: Array[MapPoint] = []
var _points_by_id: Dictionary = {}
var _selected_point: MapPoint = null
var _origin_point: MapPoint = null

func _ready() -> void:
	route_line.clear_points()
	info_panel.visible = false
	
	exit_button.pressed.connect(_exit)
	sail_button.pressed.connect(_on_sail_pressed)
	
	map_world.scale = Vector2(1.6, 1.6)
	
	for child in map_world.get_children():
		if child is MapPoint:
			_points.append(child)
			child.point_selected.connect(_on_point_selected)
			if child.data and not child.data.id.is_empty():
				_points_by_id[child.data.id] = child
			
	if not _points.is_empty():
		_origin_point = _points[0]
		var current_id: String = GameManager.get("current_island_id") if GameManager.get("current_island_id") else ""
		if _points_by_id.has(current_id):
			_origin_point = _points_by_id[current_id]
	
	if _origin_point:
		_focus_on_point(_origin_point, false)
		
	_update_fog_of_war()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_exit()
		get_viewport().set_input_as_handled()
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_is_dragging = true
			_drag_start_pos = event.position
		else:
			_is_dragging = false
	elif event is InputEventMouseMotion and _is_dragging:
		map_world.position += event.relative
		_clamp_map_position()
		
		if event.position.distance_to(_drag_start_pos) > DRAG_THRESHOLD:
			get_viewport().set_input_as_handled()

func _focus_on_point(point: MapPoint, smooth: bool = true):
	var viewport_size := get_viewport().get_visible_rect().size
	var target_screen_pos := Vector2(viewport_size.x * 0.35, viewport_size.y * 0.5)
	var point_center := point.position + (point.size / 2.0)
	var target_pos := target_screen_pos - (point_center * map_world.scale)
	
	var map_size := map_texture.size * map_world.scale
	var margin := 250.0
	target_pos.x = clampf(target_pos.x, minf(0.0, viewport_size.x - map_size.x) - margin, margin)
	target_pos.y = clampf(target_pos.y, minf(0.0, viewport_size.y - map_size.y) - margin, margin)
	
	if smooth:
		var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(map_world, "position", target_pos, 0.35)
	else:
		map_world.position = target_pos

func _clamp_map_position() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var map_size := map_texture.size * map_world.scale
	var margin := 250.0
	
	map_world.position.x = clampf(map_world.position.x, minf(0.0, viewport_size.x - map_size.x) - margin, margin)
	map_world.position.y = clampf(map_world.position.y, minf(0.0, viewport_size.y - map_size.y) - margin, margin)

func _on_point_selected(point: MapPoint) -> void:
	if not point.data:
		push_error("ERROR: El punto %s no tiene datos asignados." % point.name)
		return
		
	_selected_point = point
	var info := point.data
	
	info_panel.visible = true
	title_label.text = info.display_name
	desc_label.text = info.description
	if zone_image and info.zone_image:
		zone_image.texture = info.zone_image
	
	_focus_on_point(point, true)
	route_line.clear_points()
	
	if not can_plot_route:
		cost_label.visible = false
		sail_button.visible = false
		return
	
	cost_label.visible = true
	sail_button.visible = true
	
	if _origin_point == _selected_point:
		cost_label.text = "Ubicacion actual"
		cost_label.modulate = Color(0.7, 0.9, 1.0)
		sail_button.disabled = true
		return
	
	var is_reachable : bool = _origin_point and _origin_point.data and _origin_point.data.connected_islands.has(info.id)
	
	if not is_reachable:
		cost_label.text = "Fuera de alcance directo"
		cost_label.modulate = Color(1.0, 0.4, 0.4)
		sail_button.disabled = true
		return
	
	route_line.add_point(_origin_point.position + (_origin_point.size / 2.0))
	route_line.add_point(_selected_point.position + (_selected_point.size / 2.0))
	
	if GameManager.coal < info.coal_cost:
		cost_label.text = "Carbon Insuficiente"
		cost_label.modulate = Color(1.0, 0.4, 0.4)
		sail_button.disabled = true
	else:
		cost_label.text = "Costo de viaje: %d" % info.coal_cost
		cost_label.modulate = Color.WHITE
		sail_button.disabled = false

func _on_sail_pressed() -> void:
	if not _selected_point or not _selected_point.data:
		return
	
	GameManager.modify_resources(-_selected_point.data.coal_cost, 0, 0, 0)
	RouteManager.start_route(_selected_point.data)
	get_tree().current_scene.change_zone(3)
	_exit()

func _exit() -> void:
	GameManager.is_on_event = false
	queue_free()
	
func _update_fog_of_war():
	if not fog_overlay or not fog_overlay.material:
		return
	
	var clear_zones := PackedVector3Array()
	var unlocked_islands: Array[String] = []
	
	for island in GameManager.discovered_islands:
		if not unlocked_islands.has(island):
			unlocked_islands.append(island)
			
	if _origin_point and _origin_point.data:
		var origin_id := _origin_point.data.id
		if not unlocked_islands.has(origin_id):
			unlocked_islands.append(origin_id)
		for neighbor_id in _origin_point.data.connected_islands:
			if not unlocked_islands.has(neighbor_id):
				unlocked_islands.append(neighbor_id)
	
	for id in unlocked_islands:
		if _points_by_id.has(id):
			var pt: MapPoint = _points_by_id[id]
			var center := pt.position + (pt.size / 2.0)
			clear_zones.append(Vector3(center.x, center.y, 110.0))
			
			pt.visible = true
			
	for pt in _points:
		if pt.data:
			var is_unlocked := unlocked_islands.has(pt.data.id)
			pt.disabled = not is_unlocked
			pt.mouse_filter = Control.MOUSE_FILTER_STOP if is_unlocked \
							else Control.MOUSE_FILTER_IGNORE 
		
	var mat := fog_overlay.material as ShaderMaterial
	mat.set_shader_parameter("map_size", map_texture.size)
	mat.set_shader_parameter("clear_count", clear_zones.size())
	mat.set_shader_parameter("clear_zones", clear_zones)
