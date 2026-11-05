extends CharacterBody2D

@export var animation: AnimatedSprite2D
@export var fishingMinigame: PackedScene

var _speed: float = 100.0
var _jump_speed: float = -300.0
var _is_fishing: bool = false
var _current_fishing_instance: Node = null

func _unhandled_input(event: InputEvent) -> void:
	# Fishing
	if Input.is_action_just_pressed("fish") and is_on_floor():
		if GameManager.is_on_boat:
			_start_fishing()
		else:
			print("No puedes pescar aqui.")
		get_viewport().set_input_as_handled()
		
		# Interact
	if Input.is_action_just_pressed("interact"):
		print("GOING TO RPG ZONE")
		var main_node = get_tree().current_scene
		if main_node.has_method("change_zone"):
			main_node.change_zone(2)

func _physics_process(delta: float) -> void:
	# Gravity
	velocity += get_gravity() * delta
	
	if _is_fishing:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
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
