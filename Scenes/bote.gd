extends Node2D

@export var limit_min: Marker2D
@export var limit_max: Marker2D

@export_group("Animación de Flotado y Rebote")
@export var wave_speed: float = 2.0        ## Velocidad del vaivén normal del agua
@export var wave_height: float = 1.0       ## Cuántos píxeles sube/baja en reposo
@export var sink_depth: float = 5.0        ## Cuántos píxeles se hunde al entrar
@export var max_tilt_deg: float = 2.0      ## Grados máximos de inclinación al entrar
@export var sink_time: float = 0.15       ## Qué tan rápido se hunde (más alto = más amortiguado)
@export var recover_time: float = 1.0      ## Qué tan lento vuelve a flotar

@export_group("Horno y Cocina")
@export var coal_cost: int = 5
@export var oven_burn_duration: float = 25.0
@export var cooking_ui_scene: PackedScene

var _oven_heat_left: float = 0.0

@onready var visuals: Node2D = $Visuals

var _time: float = 0.0
var _impact_y: float = 0.0      # Desplazamiento vertical extra por el impacto
var _impact_rot: float = 0.0    # Rotación extra por el impacto
var _wobble_tween: Tween

func _process(delta: float) -> void:
	_time += delta
	
	# 1. Movimiento base de las olas (suave y constante)
	var wave_y := sin(_time * wave_speed) * wave_height
	var wave_rot := sin(_time * (wave_speed * 0.7)) * deg_to_rad(0.8)
	
	# 2. Sumamos las olas + el efecto del impacto (sin que se peleen)
	visuals.position.y = wave_y + _impact_y
	visuals.rotation = wave_rot + _impact_rot
	
	if _oven_heat_left > 0.0:
		_oven_heat_left = maxf(0.0, _oven_heat_left - delta)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameManager.is_on_boat = true
		
		# Proporcional a qué tan lejos del centro cayó (de -1.0 a 1.0)
		# Si cae en el centro casi no se inclina; si cae en una punta se inclina más
		var offset_ratio := clampf((body.global_position.x - global_position.x) / 80.0, -1.0, 1.0)
		_play_board_bounce(offset_ratio, sink_depth)
		
		body.velocity = Vector2.ZERO
		body.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
		if limit_min and limit_max:
			body.boat_min = limit_min.global_position
			body.boat_max = limit_max.global_position

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameManager.is_on_boat = false
		body.motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
		# Al saltar fuera, el bote se aligera un poco hacia arriba
		_play_board_bounce(0.0, -sink_depth * 0.5)
		
func _on_helm_interactable_interacted(player: Node2D, option_index: int, option_name: String):
	if GameManager.is_on_event:
		return
	
	match option_index:
		0:
			if GameManager.is_on_route:
				if RouteManager.is_steering:
					RouteManager.is_steering = false
					player.set_physics_process(true)
				else:
					RouteManager.is_steering = true
					player.set_physics_process(false)
			else:
				MainScene.show_map(true)
		1:
			MainScene.show_map(false)
			
func _on_oven_interactable_interacted(player: Node2D, option_index: int, option_name: String):
	if GameManager.is_on_event:
		return
		
	match option_index:
		0:
			_light_oven()
		1:
			_open_cooking_ui(player)

func _light_oven() -> void:
	if GameManager.coal < coal_cost:
		print("Carbón insuficiente (necesitas ", coal_cost, ").")
		_play_board_bounce(0.2, 1.5)
		return
		
	GameManager.modify_resources(-coal_cost, 0, 0, 0)
	_oven_heat_left = oven_burn_duration
	_play_board_bounce(-0.15, 2.0)

func _open_cooking_ui(player: Node2D) -> void:
	if _oven_heat_left <= 0.0:
		print("El horno está apagado. Prende los carbones primero.")
		_play_board_bounce(0.2, 1.5)
		return
		
	if GameManager.caught_fish.is_empty():
		print("No tienes peces en la bodega para cocinar.")
		return
		
	if not cooking_ui_scene:
		push_warning("Asigna CookingUI.tscn en el Inspector del barco.")
		return
		
	player.set_physics_process(false)
	var ui := cooking_ui_scene.instantiate()
	get_tree().current_scene.add_child(ui)
	ui.setup(self)
	ui.closed.connect(func():
		if is_instance_valid(player):
			player.set_physics_process(true)
	)

func _play_board_bounce(tilt_ratio: float, target_sink: float) -> void:
	if _wobble_tween and _wobble_tween.is_valid():
		_wobble_tween.kill()
		
	_wobble_tween = create_tween().set_parallel(true)
	
	# FASE 1: Hundimiento e inclinación amortiguada
	_wobble_tween.tween_property(self, "_impact_y", target_sink, sink_time)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_wobble_tween.tween_property(self, "_impact_rot", deg_to_rad(max_tilt_deg * tilt_ratio), sink_time)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# FASE 2: Recuperación suave sobre el agua (TRANS_BACK hace 1 solo contra-rebote sutil)
	_wobble_tween.chain().tween_property(self, "_impact_y", 0.0, recover_time)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_wobble_tween.parallel().tween_property(self, "_impact_rot", 0.0, recover_time * 1.1)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
