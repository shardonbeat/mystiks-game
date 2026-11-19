extends PanelContainer

@onready var icon_rect: TextureRect = $HBoxContainer/TextureRect
@onready var uses_label: Label = $HBoxContainer/VBoxContainer/UsesLabel
@onready var cooldown_bar: ProgressBar = $HBoxContainer/VBoxContainer/CooldawnBar

func _ready() -> void:
	icon_rect.pivot_offset = Vector2(32, 32)
	
	GameManager.mystik_changed.connect(_refresh_ui)
	GameManager.mystik_ability_triggered.connect(_on_mystik_triggered)
	_refresh_ui()
	
func _refresh_ui():
	var mystik := GameManager.equipped_mystik
	if not mystik:
		visible = false
		return
		
	visible = true
	icon_rect.texture = mystik.icon
	
	if GameManager.is_mystik_exhausted:
		uses_label.text = "Agotado"
	else:
		uses_label.text = "%d/%d [R]" % [GameManager.mystik_uses_left, mystik.max_uses]
	
	if mystik.cooldown_seconds > 0.0:
		cooldown_bar.max_value = mystik.cooldown_seconds
		cooldown_bar.value = mystik.cooldown_seconds - GameManager.mystik_cooldown_left
	else:
		cooldown_bar.max_value = 1.0
		cooldown_bar.value = 1.0
		
	if GameManager.can_use_mystik_help():
		icon_rect.modulate = Color.WHITE
	else:
		icon_rect.modulate = Color(0.55, 0.55, 0.55, 0.85)
		
func _on_mystik_triggered(_mystik: MystikData) -> void:
	var tween := create_tween()
	tween.tween_property(icon_rect, "scale", Vector2(1.25, 1.25), 0.1).set_trans(Tween.TRANS_SINE)
	tween.tween_property(icon_rect, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK)
