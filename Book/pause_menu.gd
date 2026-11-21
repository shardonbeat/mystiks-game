extends CanvasLayer

@export var tab_slide_offset: float = 5.0

@onready var dimmer: ColorRect = $Dimmer
@onready var book_root: Node2D = $BookRoot
@onready var book_sprite: AnimatedSprite2D = $BookRoot/BookSprite
@onready var pages_ui: Control = $BookRoot/PagesUI
@onready var bookmarks_box: VBoxContainer = $BookRoot/PagesUI/BookMarks
@onready var page_container: MarginContainer = $BookRoot/PagesUI/PageContainer

var _is_open: bool = false
var _is_animating: bool = false
var _pages: Array[Control] = []
var _tabs: Array[BaseButton] = []
var _tab_base_x: Array[float] = []
var _current_page: int = 0

var _prev_btn: BaseButton = null
var _next_btn: BaseButton = null

func _ready() -> void:
	layer = 10
	visible = false
	pages_ui.visible = false
	add_to_group("pause_menu")
	
	# Evitamos bucles en las animaciones de transición del libro
	if book_sprite.sprite_frames:
		for anim in ["open", "turn_next"]:
			if book_sprite.sprite_frames.has_animation(anim):
				book_sprite.sprite_frames.set_animation_loop(anim, false)
	
	# Registramos todas las páginas hijas de PageContainer en orden
	for child in page_container.get_children():
		if child is Control:
			_pages.append(child)
			child.visible = false
			
	# Registramos cada bookmark y guardamos su posición X original
	var tab_children := bookmarks_box.get_children()
	for i in range(tab_children.size()):
		if tab_children[i] is BaseButton:
			var btn: BaseButton = tab_children[i]
			var tab_index := _tabs.size()
			_tabs.append(btn)
			_tab_base_x.append(btn.position.x)
			btn.pressed.connect(func(): go_to_page(tab_index))
			
	# Botones opcionales de flecha en las esquinas
	_prev_btn = pages_ui.get_node_or_null("PrevPageBtn") as BaseButton
	_next_btn = pages_ui.get_node_or_null("NextPageBtn") as BaseButton
	if _prev_btn:
		_prev_btn.pressed.connect(func(): go_to_page(_current_page - 1))
	if _next_btn:
		_next_btn.pressed.connect(func(): go_to_page(_current_page + 1))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# No abrimos la pausa si hay un evento o mapa bloqueando el juego
		if not _is_open and GameManager.is_on_event:
			return
			
		get_viewport().set_input_as_handled()
		if _is_open:
			close_book()
		else:
			open_book()

func open_book() -> void:
	if _is_animating or _is_open:
		return
		
	_is_animating = true
	_is_open = true
	get_tree().paused = true
	visible = true
	
	pages_ui.visible = false
	pages_ui.modulate.a = 0.0
	
	var has_open_anim := _has_anim("open")
	if has_open_anim:
		book_sprite.stop()
		book_sprite.animation = "open"
		book_sprite.frame = 0
	
	var viewport_size := get_viewport().get_visible_rect().size
	var center_pos := viewport_size * 0.5
	var start_pos := Vector2(center_pos.x, viewport_size.y + 300.0)
	
	book_root.position = start_pos
	dimmer.modulate.a = 0.0
	
	# 1. Entrada del libro cerrado desde abajo
	var tween := create_tween().set_parallel(true)
	tween.tween_property(dimmer, "modulate:a", 1.0, 0.25)
	tween.tween_property(book_root, "position", center_pos, 0.38)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
	await tween.finished
	
	# 2. Apertura de tapas
	if has_open_anim:
		book_sprite.play("open")
		await book_sprite.animation_finished
		if _has_anim("idle"):
			book_sprite.play("idle")
			
	# 3. Preparamos la página actual y mostramos la interfaz
	_show_page_instant(_current_page)
	pages_ui.visible = true
	
	var ui_tween := create_tween()
	ui_tween.tween_property(pages_ui, "modulate:a", 1.0, 0.15)
	await ui_tween.finished
	
	_is_animating = false

func close_book() -> void:
	if _is_animating or not _is_open:
		return
		
	_is_animating = true
	
	# 1. Ocultamos contenido y bookmarks antes de cerrar las tapas
	var ui_tween := create_tween()
	ui_tween.tween_property(pages_ui, "modulate:a", 0.0, 0.1)
	await ui_tween.finished
	pages_ui.visible = false
	
	# 2. Cierre de tapas
	if _has_anim("open"):
		book_sprite.play_backwards("open")
		await book_sprite.animation_finished
	
	# 3. Salida hacia abajo
	var viewport_size := get_viewport().get_visible_rect().size
	var exit_pos := Vector2(viewport_size.x * 0.5, viewport_size.y + 300.0)
	
	var tween := create_tween().set_parallel(true)
	tween.tween_property(dimmer, "modulate:a", 0.0, 0.25)
	tween.tween_property(book_root, "position", exit_pos, 0.3)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		
	await tween.finished
	
	visible = false
	_is_open = false
	_is_animating = false
	get_tree().paused = false

func go_to_page(target_index: int) -> void:
	if _is_animating or not _is_open:
		return
	if target_index < 0 or target_index >= _pages.size() or target_index == _current_page:
		return
		
	_is_animating = true
	var going_forward := target_index > _current_page
	
	# Deslizamos los bookmarks de inmediato al hacer clic
	_update_tabs(target_index)
	
	# 1. Ocultamos solo el contenido del papel (los bookmarks siguen visibles)
	var fade_out := create_tween()
	fade_out.tween_property(page_container, "modulate:a", 0.0, 0.08)
	await fade_out.finished
	page_container.visible = false
	
	# 2. Animación de pasar hoja hacia adelante o atrás
	if _has_anim("turn_next"):
		if going_forward:
			book_sprite.play("turn_next")
		else:
			book_sprite.play_backwards("turn_next")
		await book_sprite.animation_finished
		
		if _has_anim("idle"):
			book_sprite.play("idle")
			
	# 3. Activamos la nueva página y refrescamos sus datos
	_show_page_instant(target_index)
	
	# 4. Mostramos el nuevo contenido
	page_container.visible = true
	var fade_in := create_tween()
	fade_in.tween_property(page_container, "modulate:a", 1.0, 0.1)
	await fade_in.finished
	
	_is_animating = false

func _show_page_instant(index: int) -> void:
	if _pages.is_empty():
		return
		
	_current_page = clampi(index, 0, _pages.size() - 1)
	
	for i in range(_pages.size()):
		var is_active := (i == _current_page)
		_pages[i].visible = is_active
		if is_active and _pages[i].has_method("refresh"):
			_pages[i].refresh()
			
	_update_tabs(_current_page)
	
	if _prev_btn:
		_prev_btn.visible = _current_page > 0
	if _next_btn:
		_next_btn.visible = _current_page < _pages.size() - 1

func _update_tabs(active_index: int) -> void:
	for i in range(_tabs.size()):
		var is_active := (i == active_index)
		_tabs[i].disabled = is_active
		
		var target_x := _tab_base_x[i] + (tab_slide_offset if is_active else 0.0)
		var tween := create_tween()
		tween.tween_property(_tabs[i], "position:x", target_x, 0.12)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _has_anim(anim_name: String) -> bool:
	return book_sprite.sprite_frames != null and book_sprite.sprite_frames.has_animation(anim_name)
