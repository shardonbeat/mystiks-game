extends CanvasLayer

@export var events: Array[EventType]
static var last_event: EventType

@export var root_event_ui: Control
@export var eventName: Label
@export var eventDescription: RichTextLabel

@export var labelFuel: Label
@export var labelStamina: Label
@export var labelMoney: Label

@export var option_buttons_container: HBoxContainer
@export var option_buttons: Array[TextureButton]    
@export var exit_button: Button

var _option_button_tween: Tween
var _initial_container_y: float

func _ready() -> void:
	if root_event_ui:
		root_event_ui.visible = false
		
	if option_buttons_container:
		_initial_container_y = option_buttons_container.position.y
		
	if exit_button:
		exit_button.pressed.connect(_on_exit_button_pressed)
		
	for btn in option_buttons:
		if btn:
			btn.mouse_entered.connect(func(): btn.self_modulate = Color(1.3, 1.3, 1.3))
			btn.mouse_exited.connect(func(): btn.self_modulate = Color(1.0, 1.0, 1.0))

func start_random_event():
	if GameManager.is_on_event:
		push_error("ERROR: Ya hay un evento activo.")
		return
		
	if events.is_empty():
		push_error("ERROR: No hay eventos asignados en el Array 'events' de " + name)
		return
		
	var current_event: EventType = null
	
	while true:
		current_event = events.pick_random()
		if current_event == null:
			push_error("ERROR: El evento seleccionado en la lista es nulo.")
			return    
			
		if events.size() == 1 or current_event != last_event:
			break
	
	GameManager.is_on_event = true
	
	var main = get_tree().current_scene
	
	if main and main.has_method("play_cinematic_bars"):
		main.play_cinematic_bars(true, Vector2(2, 2), 0.8)
	
	if _option_button_tween and _option_button_tween.is_valid():
		_option_button_tween.kill()
		
	_option_button_tween = create_tween().set_parallel(true)
	_option_button_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	print("RANDOM EVENT! " + current_event.event_name)
	if root_event_ui:
		root_event_ui.visible = true
		
	if option_buttons_container:
		_option_button_tween.tween_property(option_buttons_container, "position:y", 448.0, 0.8)
		
	if eventName:    
		eventName.text = current_event.event_name
		
	if eventDescription:
		eventDescription.text = "[center]" + current_event.event_description + "[/center]"
		
	if GameManager and labelFuel and labelStamina and labelMoney:
		labelFuel.text = str(GameManager.coal)
		labelStamina.text = str(GameManager.energy)
		labelMoney.text = str(GameManager.money)
		
	setup_options(current_event.event_solving_options)
	last_event = current_event

func setup_options(choices: Array):
	for i in range(option_buttons.size()):
		var btn = option_buttons[i]
		if not btn:
			continue
			
		if i < choices.size():
			var choice: EventOption = choices[i]
			btn.visible = true
			
			var nameLabel_node = btn.find_child("Label", true, false) as Label
			if nameLabel_node:
				nameLabel_node.text = choice.option_name
				
			_update_button_resources(btn, choice.needed_resources)
			
			var affordable := _can_afford(choice.needed_resources)
			btn.disabled = not affordable
			btn.modulate = Color(1.0, 1.0, 1.0) if affordable else Color(0.5, 0.5, 0.5, 0.8)
			
			if btn.pressed.is_connected(_on_option_button_pressed):
				btn.pressed.disconnect(_on_option_button_pressed)
			btn.pressed.connect(_on_option_button_pressed.bind(choice))
		else:
			btn.visible = false

func _update_button_resources(btn: TextureButton, needed: Dictionary):
	var resources_map = {
		"coal": ["neededResourcesContainer/CoalIcon", "coalLabel"],
		"energy": ["neededResourcesContainer/EnergyIcon", "energyLabel"],
		"money": ["neededResourcesContainer/MoneybagIcon", "moneyLabel"]
	}
	
	for key in resources_map:	
		var icon_node = btn.get_node_or_null(resources_map[key][0])
		if icon_node:
			var cost: int = needed.get(key, 0)
			var label = icon_node.get_node_or_null(resources_map[key][1]) as Label
			icon_node.visible = cost > 0
			if label:
				label.text = str(cost)
				
func _can_afford(needed: Dictionary) -> bool:
	return GameManager.coal >= needed.get("coal", 0) \
		and GameManager.energy >= needed.get("energy", 0) \
		and GameManager.money >= needed.get("money", 0)
				
func _on_option_button_pressed(option: EventOption):
	for btn in option_buttons:
		if btn:
			btn.disabled = true
			
	GameManager.coal -= option.needed_resources.get("coal", 0)
	GameManager.energy -= option.needed_resources.get("energy", 0)
	GameManager.money -= option.needed_resources.get("money", 0)

	if labelFuel and labelStamina and labelMoney:
		labelFuel.text = str(GameManager.coal)
		labelStamina.text = str(GameManager.energy)
		labelMoney.text = str(GameManager.money)
		
	print("Chosen option: ", option.option_name)
	
	_on_exit_button_pressed()

func _on_exit_button_pressed():
	if _option_button_tween and _option_button_tween.is_valid():
		_option_button_tween.kill()
		
	if option_buttons_container:
		_option_button_tween = create_tween()
		_option_button_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_option_button_tween.tween_property(option_buttons_container, "position:y", _initial_container_y, 0.8)
		
	var main = get_tree().current_scene
	if main and main.has_method("play_cinematic_bars"):
		await main.play_cinematic_bars(false, Vector2.ONE, 0.8)
		
	if root_event_ui:
		root_event_ui.visible = false
		
	GameManager.is_on_event = false
	print("Event flew away!")
	queue_free()
	
