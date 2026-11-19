class_name Interactable
extends Area2D

signal option_selected(player: Node2D, option_index: int, option_name: String)

@export var options: Array[String] = ["Interactuar"]
@export var float_offset: float = 6.0
@export var anim_duration: float = 0.22

@onready var options_list: VBoxContainer = $OptionsList
@onready var option_template: Control = $OptionsList/OptionTemplate

var _player_in_range: Node2D = null
var _selected_index: int = 0
var _rows: Array[Control] = []
var _base_position: Vector2
var _menu_tween: Tween

func _ready() -> void:
	collision_layer = 0
	set_collision_mask_value(1, true)
	set_collision_mask_value(2, true)
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	_base_position = options_list.position
	options_list.visible = false
	options_list.modulate.a = 0.0
	
	_build_options()
	
func _build_options():
	option_template.visible = true
	
	for row in _rows:
		row.queue_free()
	_rows.clear()
	
	for i in range(options.size()):
		var row := option_template.duplicate() as Control
		row.visible = true
		row.get_node("prompt_text").text = options[i]
		options_list.add_child(row)
		_rows.append(row)
		
	_update_selection_visuals()
	
func _update_selection_visuals():
	for i in range(_rows.size()):
		var row := _rows[i]
		var is_selected := (i == _selected_index)
		row.get_node("prompt_button").visible = is_selected
		row.get_node("ButtonInd").visible = is_selected
		row.modulate = Color.WHITE if is_selected else Color(0.75, 0.75, 0.75, 0.85) 

func _unhandled_input(event: InputEvent) -> void:
	if _player_in_range == null or options.size() <= 1:
		return
		
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_selected_index = (_selected_index + 1) % options.size()
			_update_selection_visuals()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_selected_index = (_selected_index - 1 + options.size()) % options.size()
			_update_selection_visuals()
			get_viewport().set_input_as_handled()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = body
		_selected_index = 0
		_update_selection_visuals()
		_show_menu()
		if "current_interactable" in body:
			body.current_interactable = self

func _on_body_exited(body: Node2D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		_hide_menu()
		if "current_interactable" in body and body.current_interactable == self:
			body.current_interactable = null

func _show_menu():
	if _menu_tween and _menu_tween.is_valid():
		_menu_tween.kill()
		
	options_list.visible = true
	options_list.position = _base_position + Vector2(0, float_offset)
	options_list.modulate.a = 0.0
	options_list.scale = Vector2(0.85, 0.85)
	
	_menu_tween = create_tween().set_parallel(true)
	_menu_tween.tween_property(options_list, "position", _base_position, anim_duration)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_menu_tween.tween_property(options_list, "modulate:a", 1.0, anim_duration * 0.8)
	_menu_tween.tween_property(options_list, "scale", Vector2.ONE, anim_duration)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	for i in range(_rows.size()):
		var row := _rows[i]
		row.modulate.a = 0.0
		var t := create_tween()
		t.tween_interval(i * 0.05)
		t.tween_property(row, "modulate:a", 1.0 if i == _selected_index else 0.85, 0.15)
	
func _hide_menu() -> void:
	if _menu_tween and _menu_tween.is_valid():
		_menu_tween.kill()
		
	_menu_tween = create_tween().set_parallel(true)
	_menu_tween.tween_property(options_list, "position", _base_position + Vector2(0, float_offset * 0.5), anim_duration * 0.7)
	_menu_tween.tween_property(options_list, "modulate:a", 0.0, anim_duration * 0.7)
	_menu_tween.tween_property(options_list, "scale", Vector2(0.9, 0.9), anim_duration * 0.7)
	_menu_tween.chain().tween_callback(func(): options_list.visible = false)

func trigger_interaction(player: Node2D) -> void:
	if options.is_empty():
		return
	var active_row := _rows[_selected_index]
	var pulse := create_tween()
	pulse.tween_property(active_row, "scale", Vector2(1.12, 1.12), 0.06)
	pulse.tween_property(active_row, "scale", Vector2.ONE, 0.08)
	
	option_selected.emit(player, _selected_index, options[_selected_index])
