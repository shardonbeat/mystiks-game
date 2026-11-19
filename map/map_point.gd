class_name MapPoint
extends TextureButton

signal point_selected(point: MapPoint)

@export var data: IslandNodeData
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	anim_sprite.play("expand")
	
	pivot_offset = size / 2.0
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))
	
func _on_pressed():
	point_selected.emit(self)
	
func _on_hover(is_hovering: bool):
	if disabled:
		return
	var target_scale := Vector2(1.25, 1.25) if is_hovering else Vector2.ONE
	create_tween().tween_property(self, "scale", target_scale, 0.12)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
