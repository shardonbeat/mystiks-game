extends CanvasLayer

signal fishing_finished (success: bool, fish: FishType, value: int)

@export var fish: FishType
@export var rod: RodType

@export var root_ui: Control
@export var catchArea: Control
@export var barTrack: ColorRect
@export var catchBar: ColorRect
@export var fishIcon: TextureRect
@export var treasureIcon: TextureRect
@export var progressBar: ProgressBar
@export var labelFishName: Label
@export var burst: GPUParticles2D

const BASE_BAR_HEIGHT := 20.0
const BASE_HOOK_WINDOW := 0.6
const BASE_SCAPE_DRAIN := 22.0
const PROGRESS_GAIN := 28.0
const TREASURE_FILL_RATE := 55.0
const TREASURE_NEED := 50
const DURATION := 5.0

enum STATE { CASTING, BITE, HOOK, PLAY, END }

var _state: STATE = STATE.CASTING
var _elapsed: float = 0.0
var _duration: float = 0.0
var _bite_timer: float = 2.0
var _hook_window: float
var _bar_h: float
var _bar_pos: float = 0.0
var _bar_vel: float = 0.0
var _fish_pos: float = 0.5
var _fish_vel: float = 0.0
var _progress_val: float = 0.0
var _treasure_active: bool = false
var _treasure_val: float = 0.0
var _fish_seed: float

func _ready() -> void:
	if not fish or not rod:
		push_warning("PESCA REQUIERE AL MENOS UN PEZ Y UNA CAÑA.")
		return
	
	set_physics_process(false)
	await get_tree().process_frame   # wait for the layout to finish
	_set_defaults()
	set_physics_process(true)
		
func _unhandled_input(event: InputEvent) -> void:
	if _state == STATE.HOOK:
		if event.is_action_pressed("ui_accept"):
			_on_hook()
			
func _update_input_bar(delta: float):
	var up := Input.is_action_pressed("ui_accept")
	var dir := 1.0 if up else -1.0
	
	_bar_vel += dir * rod.bar_accel * delta
	_bar_vel -= _bar_vel * rod.bar_drag * delta
	_bar_vel -= rod.bar_gravity * delta
	
	var track_h := _track_height()
	if track_h > 0.0:
		_bar_pos += _bar_vel * delta / track_h
	_bar_pos = clamp(_bar_pos, 0.0, 1.0)
	
	if _bar_pos == 0.0 and _bar_vel < 0.0:
		_bar_vel *= -0.35
	if _bar_pos == 1.0 and _bar_vel > 0.0:
		_bar_vel *= -0.35
		
	_set_catch_bar_visual()
		
func _physics_process(delta: float) -> void:
	_elapsed += delta
	_duration += delta
	
	match _state:
		STATE.CASTING:
			_bite_timer = _rng_bite_time()
			_state = STATE.BITE
		STATE.BITE:
			var bite_mult = rod.bite_rate_mult if rod else 1.0
			_bite_timer -= delta * bite_mult
			if _bite_timer <= 0.0:
				_prompt_hook()
		STATE.HOOK:
			_hook_window -= delta * (rod.hook_window_mult if rod else 1.0)
			if _hook_window <= 0.0:
				_fail("MUY LENTO.")
		STATE.PLAY:
			_update_input_bar(delta)
			_update_fish_motion(delta)
			
			var fish_y := _fish_center_y()
			var is_overlapping := fish_y >= catchBar.position.y \
				and fish_y <= catchBar.position.y + _bar_h
			
			if is_overlapping:
				_progress_val += PROGRESS_GAIN * delta
				if _treasure_active and _treasure_val < TREASURE_NEED:
					_treasure_val += TREASURE_FILL_RATE * delta
			else:
				var escape_mult = fish.escape_rate if fish and "escape_rate" in fish else 1.0
				_progress_val -= BASE_SCAPE_DRAIN * escape_mult * delta
			
			_progress_val = clamp(_progress_val, 0.0, 100.0)
			progressBar.value = _progress_val
			
			if _progress_val >= 100.0:
				_win()
			if _progress_val <= 0.0:
				_fail("SE ESCAPO")
		STATE.END:
			pass
			
func _prompt_hook():
	_state = STATE.HOOK
	var hook_mult = rod.hook_window_mult if rod else 1.0
	_hook_window = BASE_HOOK_WINDOW * hook_mult
	
	flash_node(catchArea, 0.12)
	_punch_ui(root_ui, 1.05, 0.08)

func _win():
	_state = STATE.END
	if burst:
		burst.restart()
		burst.emitting = true
	_punch_ui(root_ui, 1.08, 0.15)
	
	await get_tree().create_timer(0.4).timeout
	emit_signal("fishing_finished", true, fish, int(_treasure_val))
	queue_free()

func _fail(_why: String):
	_state = STATE.END
	print("ERROR: " + _why)
	
	_shake(5.0, 0.20)
	
	await get_tree().create_timer(0.2).timeout
	emit_signal("fishing_finished", false, fish, 0)
	queue_free()
	
func _on_hook():
	_state = STATE.PLAY
	treasureIcon.visible = _treasure_active
	_progress_val = 20.0
	
	var freeze_mult = rod.hit_freeze_mult if rod else 1.0
	_time_freeze(0.06 * freeze_mult)
	_shake(6.0, 0.18)
	
func _rng_bite_time() -> float:
	return max(0.25, fish.bite_time_avg + 
	randf_range(-fish.bite_time_variance, fish.bite_time_variance))
	
func _track_height() -> float:
	return max(1.0, barTrack.size.y - _bar_h)
	
func _bar_px_top() -> float:
	return barTrack.position.y + _track_height() * (1.0 - _bar_pos)
	
func _set_catch_bar_visual():
	catchBar.scale = Vector2.ONE
	catchBar.size = Vector2(barTrack.size.x * 0.9, _bar_h)
	catchBar.position = Vector2(
		barTrack.position.x + barTrack.size.x * 0.05,
		_bar_px_top()
	)
	
func _set_defaults():
	if fish:
		labelFishName.text = fish.fish_name
	barTrack.modulate = fish.tint.lerp(Color.DARK_BLUE, 0.5)
	_bar_h = BASE_BAR_HEIGHT + (rod.bar_size_bonus if rod else 0.0)
	_hook_window = BASE_HOOK_WINDOW * (rod.hook_window_mult if rod else 1.0)
	_bite_timer = _rng_bite_time()
	_fish_seed = randf() * 1000
	_bar_pos = 0.0
	
	_set_catch_bar_visual()
	_set_fish_visual()
	
	progressBar.value = 0
	treasureIcon.visible = false
	if fish and rod:
		_treasure_active = randf() < fish.treasure_chance * rod.treasure_mult								
	_treasure_val = 0.0
	
	_punch_ui(root_ui, 1.03, 0.12)
	
func _fish_center_y() -> float:
	var bottom := barTrack.position.y + barTrack.size.y - 12.0
	var top := barTrack.position.y + 12.0
	return lerp(bottom, top, _fish_pos)	

func _set_fish_visual():
	fishIcon.position.y = _fish_center_y() - fishIcon.size.y * fishIcon.scale.y * 0.5
	if fish:
		fishIcon.modulate = fish.tint
		
func _update_fish_motion(delta: float):
	var d := fish.difficulty
	match fish.pattern:
		fish.MovePattern.SMOOTH:
			var t = _elapsed + _fish_seed
			var target = 0.5 + 0.35 * sin(t * 1.2) * 0.15 * sin(t * 2.7 + 1.3)
			_fish_vel += (target - _fish_pos) * (2.2 + 2.0 * d)
			_fish_vel += 0.84 - 0.2 * d
			
	_fish_pos += _fish_vel * delta * 0.45
	_fish_pos = clamp(_fish_pos, 0.02, 0.98)
	_set_fish_visual()

func _punch_ui(node: Node, scale_to: float, time: float):
	if not node: return
	var t := create_tween()
	t.tween_property(node, "scale", Vector2.ONE * scale_to, time * 0.5)
	t.tween_property(node, "scale", Vector2.ONE, time * 0.5)
	
func flash_node(node: CanvasItem, duration: float):
	if not node: return
	var t := create_tween()
	t.tween_property(node, "modulate", Color(1,1,1,0.4), duration * 0.5)
	t.tween_property(node, "modulate", Color(1,1,1,1), duration * 0.5)

func _shake(intensity: float, duration: float):
	if not root_ui: return
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for i in range(8):
		var off := Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(root_ui, "position", off, duration/8.0)
	tween.tween_property(root_ui, "position", Vector2.ZERO, 0.06)
	
func _time_freeze(seconds: float):
	Engine.time_scale = 0.0
	await get_tree().create_timer(seconds, true, true, true).timeout
	Engine.time_scale = 1.0
