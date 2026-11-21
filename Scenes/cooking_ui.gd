extends CanvasLayer

signal closed

@onready var heat_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Header/HeatLabel
@onready var empty_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/EmptyLabel
@onready var scroll_container: ScrollContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ScrollContainer
@onready var fish_list: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/FishList
@onready var close_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CloseButton

const DEFAULT_ENERGY_GAIN := 20
var _boat: Node2D = null

func _ready() -> void:
	GameManager.fish_inventory_changed.connect(_refresh_list)
	close_btn.pressed.connect(_close)
	_refresh_list()

func setup(boat_ref: Node2D) -> void:
	_boat = boat_ref

func _process(_delta: float) -> void:
	if not is_instance_valid(_boat):
		return
	var heat: float = _boat._oven_heat_left
	heat_label.text = "Calor: %ds" % ceili(heat)
	if heat <= 0.0:
		_close()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()

func _refresh_list() -> void:
	for child in fish_list.get_children():
		child.queue_free()
		
	var is_empty := GameManager.caught_fish.is_empty()
	empty_label.visible = is_empty
	scroll_container.visible = not is_empty
	
	if is_empty:
		return
		
	for entry in GameManager.caught_fish.values():
		var fish_data: FishType = entry["data"]
		var count: int = entry["count"]
		fish_list.add_child(_create_cook_row(fish_data, count))

func _create_cook_row(fish: FishType, count: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)
	
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)
	
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(22, 22)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if fish.fish_icon:
		icon.texture = fish.fish_icon
	row.add_child(icon)
	
	var name_label := Label.new()
	name_label.text = "%s x%d" % [fish.fish_name, count]
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	name_label.add_theme_font_size_override("font_size", 11)
	row.add_child(name_label)
	
	var energy_gain: int = fish.energy_value if "energy_value" in fish else DEFAULT_ENERGY_GAIN
	var cook_btn := Button.new()
	cook_btn.text = "+%d E" % energy_gain
	cook_btn.focus_mode = Control.FOCUS_NONE
	cook_btn.add_theme_font_size_override("font_size", 11)
	cook_btn.pressed.connect(func():
		GameManager.cook_fish(fish, energy_gain)
	)
	row.add_child(cook_btn)
	
	return panel

func _close() -> void:
	closed.emit()
	queue_free()
