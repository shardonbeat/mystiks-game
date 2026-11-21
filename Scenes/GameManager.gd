extends Node

enum IslandNation { FLUCTANTIA, TROPICANTIA, INSECANTIA, CAELUMANTIA, ANIMANTIA }
var current_island_id: String = "fluctantia"
var discovered_islands: Array[String] = ["fluctantia"]

# RECURSOS
signal fish_inventory_changed

var coal: int = 100
var energy: int = 100
var money: int = 100
var caught_fish: Dictionary = {}

signal resources_changed
var _drain_accumulator: float = 0.0

# MYSTIKS
signal mystik_changed
signal mystik_ability_triggered(mystik: MystikData)

var owned_mystiks: Array[MystikData] = []
var mystik_affinity: Dictionary = {}

var equipped_mystik: MystikData = null
var mystik_uses_left: int = 0
var mystik_cooldown_left: float = 0.0
var is_mystik_exhausted: bool = false

# ESTADOS
var is_on_boat: bool = false
var is_on_route: bool = false
signal event_state_changed(is_active: bool)
var is_on_event: bool = false:
	set(value):
		is_on_event = value
		event_state_changed.emit(is_on_event)

var _fade_rect: ColorRect
var _is_transitioning_scene: bool = false

func _ready() -> void:
	var default_mystik := load("res://mystiks/Pescao.tres") as MystikData
	if default_mystik:
		unlock_mystik(default_mystik)
		
	_setup_scene_fader()

func _process(delta: float) -> void:
	if is_on_route and not GameManager.is_on_event:
		_drain_accumulator += delta
		if _drain_accumulator >= 2.0:
			_drain_accumulator -= 2.0
			energy = max(0, energy - 1)
			
	if mystik_cooldown_left > 0.0:
		mystik_cooldown_left = maxf(0.0, mystik_cooldown_left - delta)
		mystik_changed.emit()

# GESTION DE RECURSOS

func modify_resources(c: int, e: int, m: int, f: int):
	coal = max(0, coal + c)
	energy = max(0, energy + e)
	money = max(0, money + m)
	emit_signal("resources_changed")

#@ GESTION DE PECES

func add_fish(fish: FishType, amount: int = 1) -> void:
	if not fish or amount <= 0:
		push_error("ERROR DE PEZ, NO EXISTE")
		return
	var key := fish.fish_name
	if caught_fish.has(key):
		caught_fish[key]["count"] += amount
	else:
		caught_fish[key] = { "data": fish, "count": amount }
	fish_inventory_changed.emit()

func remove_fish(fish: FishType, amount: int = 1) -> bool:
	if not fish or amount <= 0:
		return false
	var key := fish.fish_name
	if not caught_fish.has(key):
		return false
		
	var current: int = caught_fish[key]["count"]
	if current < amount:
		return false
		
	if current == amount:
		caught_fish.erase(key)
	else:
		caught_fish[key]["count"] = current - amount
		
	fish_inventory_changed.emit()
	return true

func get_fish_count(fish: FishType) -> int:
	if not fish or not caught_fish.has(fish.fish_name):
		return 0
	return caught_fish[fish.fish_name]["count"]

func get_total_fish_count() -> int:
	var total := 0
	for entry in caught_fish.values():
		total += entry["count"]
	return total

func cook_fish(fish: FishType, food_gain: int = 10) -> bool:
	if remove_fish(fish, 1):
		modify_resources(0, 0, 0, food_gain)
		return true
	return false

func sell_fish(fish: FishType, price: int = 15) -> bool:
	if remove_fish(fish, 1):
		modify_resources(0, 0, price, 0)
		return true
	return false

# GESTION DE MYSTIKS

func unlock_mystik(new_mystik: MystikData) -> void:
	if not owned_mystiks.has(new_mystik):
		owned_mystiks.append(new_mystik)
		mystik_affinity[new_mystik.id] = 100
		if equipped_mystik == null:
			equip_mystik(new_mystik)

func equip_mystik(mystik: MystikData):
	if is_on_route:
		return false
	if mystik_affinity.get(mystik.id, 100) <= 0:
		return false
		
	equipped_mystik = mystik
	reset_mystik_route_state()
	return true

func can_use_mystik_help() -> bool:
	if not equipped_mystik or is_on_event:
		return false
	if mystik_uses_left <= 0 or mystik_cooldown_left > 0.0:
		return false
		
	# Evitamos gastar cargas si la habilidad no aplica en el contexto actual
	match equipped_mystik.ability_type:
		MystikData.AbilityType.CURRENT_SURGE:
			return is_on_route and RouteManager.is_steering
			
	return true
	
func use_mystik_help() -> bool:
	if not can_use_mystik_help():
		return false
		
	mystik_uses_left -= 1
	mystik_cooldown_left = equipped_mystik.cooldown_seconds
	
	match equipped_mystik.ability_type:
		MystikData.AbilityType.CURRENT_SURGE:
			RouteManager.travel_elapsed = minf(RouteManager.travel_duration, \
			RouteManager.travel_elapsed + equipped_mystik.power_value)
			
	mystik_ability_triggered.emit(equipped_mystik)
	mystik_changed.emit()
	return true
	
func reset_mystik_route_state() -> void:
	mystik_uses_left = equipped_mystik.max_uses if equipped_mystik else 0
	mystik_cooldown_left = 0.0
	is_mystik_exhausted = false
	mystik_changed.emit()
	
func _setup_scene_fader() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 100
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS # Funciona incluso con el libro de pausa abierto
	add_child(canvas)
	
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0.04, 0.05, 0.08, 0.0)
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(_fade_rect)

func change_scene_with_fade(scene_path: String, duration: float = 0.35) -> void:
	if _is_transitioning_scene:
		return
	_is_transitioning_scene = true
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP # Bloquea clics dobles durante el fundido
	
	# 1. Fundido a negro
	var tween_out := create_tween()
	tween_out.tween_property(_fade_rect, "color:a", 1.0, duration)
	await tween_out.finished
	
	# 2. Despausamos (por si venimos del libro) y cambiamos de escena
	get_tree().paused = false
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	
	# 3. Aclarado suave ya dentro de la nueva escena
	var tween_in := create_tween()
	tween_in.tween_property(_fade_rect, "color:a", 0.0, duration)
	await tween_in.finished
	
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_is_transitioning_scene = false
