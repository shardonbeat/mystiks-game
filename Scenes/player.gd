extends CharacterBody2D

@export var animation: AnimatedSprite2D

var _speed: float = 100.0
var _jump_speed: float = -300.0

func _physics_process(delta: float) -> void:
	# Gravity
	velocity += get_gravity() * delta
	
	# Jump
	if Input.is_action_just_pressed("Jump"):
		if is_on_floor():
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
	
	if !is_on_floor():
		animation.play("jump")
	elif velocity.x !=0:
		animation.play("run")
	else:
		animation.play("idle")
