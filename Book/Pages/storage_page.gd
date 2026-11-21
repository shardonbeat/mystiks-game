extends Control

@onready var total_label: Label = $BookColumns/RightPage/VBoxContainer/Header/TotalLabel
@onready var empty_label: Label = $BookColumns/RightPage/VBoxContainer/EmptyLabel
@onready var scroll_container: ScrollContainer = $BookColumns/RightPage/VBoxContainer/ScrollContainer
@onready var fish_list: VBoxContainer = $BookColumns/RightPage/VBoxContainer/ScrollContainer/FishList

func _ready() -> void:
	GameManager.fish_inventory_changed.connect(_refresh_inventory)
	visibility_changed.connect(_on_visibility_changed)
	_refresh_inventory()

func _on_visibility_changed() -> void:
	if visible:
		_refresh_inventory()

func _refresh_inventory() -> void:
	for child in fish_list.get_children():
		child.queue_free()
		
	var total := GameManager.get_total_fish_count()
	total_label.text = "Total: %d" % total
	
	var is_empty := GameManager.caught_fish.is_empty()
	empty_label.visible = is_empty
	scroll_container.visible = not is_empty
	
	if is_empty:
		return
		
	for entry in GameManager.caught_fish.values():
		var fish_data: FishType = entry["data"]
		var count: int = entry["count"]
		fish_list.add_child(_create_fish_row(fish_data, count))

func _create_fish_row(fish: FishType, count: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)
	
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)
	
	# 1. Icono del pez
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(24, 24)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if fish.fish_icon:
		icon.texture = fish.fish_icon
	row.add_child(icon)
	
	# 2. Nombre del pez
	var name_label := Label.new()
	name_label.text = fish.fish_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	name_label.add_theme_font_size_override("font_size", 12)
	row.add_child(name_label)
	
	# 3. Cantidad alineada a la derecha
	var count_label := Label.new()
	count_label.text = "x%d" % count
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.add_theme_font_size_override("font_size", 12)
	row.add_child(count_label)
	
	return panel
