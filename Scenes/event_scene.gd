extends CanvasLayer

@export var events: Array[EventType]
var last_event: EventType

@export var root_event_ui: Control
@export var eventName: Label
@export var exit_button: Button

var is_on_event: bool = false

func _ready() -> void:
	if root_event_ui:
		root_event_ui.visible = false
		
	if exit_button:
		exit_button.pressed.connect(_on_exit_button_pressed)	

func start_random_event():
	#! Los eventos comienzan uno encima del otro, se crean
	#! varias instancias de evento sin haber terminado la anterior.
	if is_on_event:
		return
		
	if events.is_empty():
		push_error("ERROR: No hay eventos asignados en el Array 'events' de " + name)
		return
		
	var current_event: EventType = null
	
	while true:
		current_event= events.pick_random()
		
		if current_event == null:
			push_error("ERROR: El evento seleccionado en la lista es nulo.")
			return	
			
		if events.size() == 1 or current_event != last_event:
			break
	
	is_on_event = true
	var current_event_name: String = current_event.event_name
	
	print("RANDOM EVENT! " + current_event_name)
	if root_event_ui:
		root_event_ui.visible = true
		
	if eventName:	
		eventName.text = current_event_name
		
	last_event = current_event

'''
BOTON DE PRUEBA

Se busca probar la variabilidad en los eventos, es decir, que
estos sean distintos uno del anterior, asi como comprobar el
factor random y el tiempo entre eventos.

El boton de salida debe ser removido una vez estructurado
el sistema RPG base.

#! El boton de salida no detecta el raton a nivel
#! de interfaz (ARREGLAR)
'''
func _on_exit_button_pressed():
	is_on_event = false
	if root_event_ui:
		root_event_ui.visible = false
		
	queue_free()	
