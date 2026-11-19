extends CharacterBody2D

@export var animation: AnimatedSprite2D
@export var fishingMinigame: PackedScene

var _speed: float = 100.0
var _jump_speed: float = -300.0
var _is_fishing: bool = false
var _current_fishing_instance: Node = null

var current_interactable: Interactable = null

var boat_min: Vector2
var boat_max: Vector2

func _unhandled_input(event: InputEvent) -> void:
	if GameManager.is_on_event:
		return
	
	if event.is_action_pressed("use_mystik"):
		if GameManager.use_mystik_help():
			get_viewport().set_input_as_handled()
	
	# Fishing
	if Input.is_action_just_pressed("fish"):
		if GameManager.is_on_boat and !_is_fishing:
			_start_fishing()
		else:
			print("No puedes pescar aqui.")
		get_viewport().set_input_as_handled()
		
		# Interact
	if Input.is_action_just_pressed("interact"):
		if current_interactable != null:
			current_interactable.trigger_interaction(self)
			get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	# Gravity
	if GameManager.is_on_boat:
		if GameManager.is_on_event:
			velocity = Vector2.ZERO
			animation.play("idle")
			move_and_slide()
			return
			
		if _is_fishing:
			velocity = Vector2.ZERO
			move_and_slide()
			return
			
		var input_dir := Input.get_vector("Left", "Right", "Up", "Down")
		velocity = input_dir * _speed
		
		if velocity.x > 0:
			animation.flip_h = true
		elif velocity.x < 0:
			animation.flip_h = false
			
		move_and_slide()
		
		if boat_min != Vector2.ZERO and boat_max != Vector2.ZERO:
			global_position.x = clamp(global_position.x, min(boat_min.x, boat_max.x), max(boat_min.x, boat_max.x))
			global_position.y = clamp(global_position.y, min(boat_min.y, boat_max.y), max(boat_min.y, boat_max.y))
		
	else:
		velocity += get_gravity() * delta
	
		# Jump
		if Input.is_action_just_pressed("Jump") and is_on_floor():
			velocity.y = _jump_speed
		
		# Movement
		if Input.is_action_pressed("Right"):
			velocity.x = _speed
			animation.flip_h = true
		elif Input.is_action_pressed("Left"):
			velocity.x = -_speed
			animation.flip_h = false
		else:
			velocity.x = 0
		move_and_slide()
	
	# Animations
	
	#if !is_on_floor():
	#	animation.play("jump")
	if velocity.x !=0:
		animation.play("run")
	else:
		animation.play("idle")
		
func _start_fishing() -> void:
	if not fishingMinigame:
		print("ERROR: Escena de Pesca no asignada a Player.")
		return
		
	_is_fishing = true
	_current_fishing_instance = fishingMinigame.instantiate()
	_current_fishing_instance.fishing_finished.connect(_on_fishing_finished)
	get_tree().current_scene.add_child(_current_fishing_instance)	
	
func _on_fishing_finished(success: bool, fish: FishType, value: int):
	_is_fishing = false
	
	if _current_fishing_instance:
		_current_fishing_instance.queue_free()
		_current_fishing_instance = null
	
	if success:
		print("CAUGHT A FISH.")
	else:
		print("THE FISH GOT AWAY!")
