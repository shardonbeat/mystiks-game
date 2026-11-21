extends HBoxContainer

@onready var mystik_grid: GridContainer = $BookColumns/LeftPage/MystikGrid
@onready var portrait_rect: TextureRect = $BookColumns/RightPage/HeaderBox/PortraitRect
@onready var name_label: Label = $BookColumns/RightPage/HeaderBox/NameLabel
@onready var hability_title: Label = $BookColumns/RightPage/Habilidad
@onready var hability_label: Label = $BookColumns/RightPage/HabilityLabel
@onready var desc_label: RichTextLabel = $BookColumns/RightPage/DescLabel
@onready var equip_button: Button = $BookColumns/RightPage/EquipButton

var _selected_mystik: MystikData = null

func _ready() -> void:
	if not equip_button.pressed.is_connected(_on_equip_pressed):
		equip_button.pressed.connect(_on_equip_pressed)
	refresh_mystik_book()

func refresh() -> void:
	refresh_mystik_book()

func refresh_mystik_book() -> void:
	for child in mystik_grid.get_children():
		child.queue_free()
		
	if GameManager.owned_mystiks.is_empty():
		name_label.text = "Sin Mystiks"
		desc_label.text = "Aún no has formado vínculo con ningún Mystik."
		portrait_rect.texture = null
		hability_title.visible = false
		equip_button.visible = false
		return
		
	equip_button.visible = true
	
	for mystik in GameManager.owned_mystiks:
		var slot := Button.new()
		slot.custom_minimum_size = Vector2(72, 72)
		slot.icon = mystik.icon
		slot.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.expand_icon = true		
		slot.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		slot.pressed.connect(func(): _select_mystik(mystik))
		mystik_grid.add_child(slot)
	
	if _selected_mystik == null or not (_selected_mystik in GameManager.owned_mystiks):
		_selected_mystik = GameManager.equipped_mystik if GameManager.equipped_mystik else GameManager.owned_mystiks[0]
		
	_select_mystik(_selected_mystik)

func _select_mystik(mystik: MystikData) -> void:
	_selected_mystik = mystik
	portrait_rect.texture = mystik.icon
	name_label.text = mystik.mystik_name
	hability_label.text = mystik.get_ability_name()
	desc_label.text = mystik.description
	
	if GameManager.equipped_mystik == mystik:
		equip_button.text = "Equipado"
		equip_button.disabled = true
	elif GameManager.is_on_route:
		equip_button.text = "En ruta"
		equip_button.disabled = true
	else:
		equip_button.text = "Equipar"
		equip_button.disabled = false

func _on_equip_pressed() -> void:
	if _selected_mystik == null or GameManager.is_on_route:
		return
		
	GameManager.equipped_mystik = _selected_mystik
	GameManager.mystik_uses_left = _selected_mystik.max_uses
	GameManager.mystik_cooldown_left = 0.0
	GameManager.is_mystik_exhausted = false
	GameManager.mystik_changed.emit()
	
	_select_mystik(_selected_mystik)
