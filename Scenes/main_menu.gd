extends Control

@export_file("*.tscn") var game_scene: String = "res://Scenes/main_scene.tscn"

@onready var logo: Sprite2D = $MystiksTitle
@onready var bg_map: TextureRect = $TextureRect
@onready var buttons_box: VBoxContainer = $VBoxContainer
@onready var play_btn: TextureButton = $VBoxContainer/Play
@onready var continue_btn: TextureButton = $VBoxContainer/Continue
@onready var exit_btn: TextureButton = $VBoxContainer/Exit
@onready var clouds: TextureRect = get_node_or_null("CloudsOverlay")

var _logo_base_y: float = 0.0
var _is_transitioning: bool = false

func _ready() -> void:
	_logo_base_y = logo.position.y
	
	play_btn.pressed.connect(_on_play_pressed)
	continue_btn.pressed.connect(_on_continue_pressed)
	exit_btn.pressed.connect(_on_exit_pressed)
	
	var has_save := FileAccess.file_exists("user://savegame.save")
	continue_btn.disabled = not has_save
	if not has_save:
		continue_btn.modulate = Color(0.6, 0.6, 0.6, 0.75)
	
	for btn in [play_btn, continue_btn, exit_btn]:
		_setup_button_feel(btn)
		
	_play_intro_animation()
	_start_ambient_motion()
	_start_map_cinematic()

func _process(delta: float) -> void:
	if clouds:
		clouds.position.x -= 12.0 * delta
		if clouds.position.x <= -clouds.size.x * 0.5:
			clouds.position.x = 0.0

func _play_intro_animation() -> void:
	logo.modulate.a = 0.0
	logo.position.y = _logo_base_y - 20.0
	
	var tween := create_tween().set_parallel(true)
	tween.tween_property(logo, "modulate:a", 1.0, 0.45)
	tween.tween_property(logo, "position:y", _logo_base_y, 0.5)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
	var delay := 0.15
	for btn in [play_btn, continue_btn, exit_btn]:
		var target_alpha := 0.75 if btn.disabled else 1.0
		btn.modulate.a = 0.0
		var btn_tween := create_tween()
		btn_tween.tween_interval(delay)
		btn_tween.tween_property(btn, "modulate:a", target_alpha, 0.3)
		delay += 0.1

func _start_ambient_motion() -> void:
	var float_tween := create_tween().set_loops()
	float_tween.tween_property(logo, "position:y", _logo_base_y + 6.0, 1.8)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	float_tween.tween_property(logo, "position:y", _logo_base_y - 4.0, 1.8)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _setup_button_feel(btn: TextureButton) -> void:
	btn.pivot_offset = btn.size * 0.5
	var label := btn.get_node_or_null("Label") as Label
	var base_label_y := label.position.y if label else 0.0
	
	btn.mouse_entered.connect(func():
		if btn.disabled or _is_transitioning:
			return
		var t := create_tween().set_parallel(true)
		t.tween_property(btn, "scale", Vector2(1.06, 1.06), 0.12).set_trans(Tween.TRANS_BACK)
		t.tween_property(btn, "modulate", Color(1.15, 1.12, 1.05), 0.12)
	)
	
	btn.mouse_exited.connect(func():
		if btn.disabled:
			return
		var t := create_tween().set_parallel(true)
		t.tween_property(btn, "scale", Vector2.ONE, 0.12)
		t.tween_property(btn, "modulate", Color.WHITE, 0.12)
		if label:
			label.position.y = base_label_y
	)
	
	btn.button_down.connect(func():
		if btn.disabled:
			return
		btn.scale = Vector2(0.97, 0.97)
		if label:
			label.position.y = base_label_y + 2.0 # Efecto de presionar hacia abajo
	)
	
	btn.button_up.connect(func():
		if btn.disabled:
			return
		btn.scale = Vector2(1.06, 1.06)
		if label:
			label.position.y = base_label_y
	)

func _on_play_pressed() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	GameManager.change_scene_with_fade(game_scene)

func _on_continue_pressed() -> void:
	_on_play_pressed()

func _on_exit_pressed() -> void:
	get_tree().quit()
	
func _start_map_cinematic() -> void:
	# Recorrido infinito y suave por distintos puntos del mapa (volcán, serpiente este, islas sur)
	# Ajusta los valores si quieres enfocar más alguna zona específica
	var map_tween := create_tween().set_loops()
	map_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Punto 1: Hacia el volcán central / norte
	map_tween.tween_property(bg_map, "position", Vector2(-80, -30), 7.0)
	# Punto 2: Hacia la bahía de la serpiente (derecha)
	map_tween.tween_property(bg_map, "position", Vector2(-210, -70), 8.0)
	# Punto 3: Hacia las islas del sur
	map_tween.tween_property(bg_map, "position", Vector2(-130, -135), 7.5)
	# Punto 4: Regreso suave al encuadre inicial
	map_tween.tween_property(bg_map, "position", Vector2(-30, -25), 7.0)
