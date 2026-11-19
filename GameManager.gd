extends Node

enum IslandNation { FLUCTANTIA, TROPICANTIA, INSECANTIA, CAELUMANTIA, ANIMANTIA }
var current_island_id: String = "fluctantia"
var discovered_islands: Array[String] = ["fluctantia"]

# RECURSOS
var coal: int = 100
var energy: int = 100
var money: int = 100
var food: int = 50
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

func _ready() -> void:
	var default_mystik := load("res://mystiks/Pescao.tres") as MystikData
	if default_mystik:
		unlock_mystik(default_mystik)

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
	food = max(0, food + f)
	emit_signal("resources_changed")

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
	
	# Aplicamos efectos globales directamente aquí
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
