extends HBoxContainer

const MAIN_MENU_PATH := "res://Scenes/main_menu.tscn"

@onready var master_slider: HSlider = $BookColumns/LeftPage/MasterSlider
@onready var music_slider: HSlider = $BookColumns/LeftPage/MusicSlider
@onready var sfx_slider: HSlider = $BookColumns/LeftPage/SfxSlider
@onready var fullscreen_check: CheckButton = $BookColumns/LeftPage/FullscreenCheck

@onready var resume_button: TextureButton = $BookColumns/RightPage/ResumeButton
@onready var title_screen_button: TextureButton = $BookColumns/RightPage/TitleScreenButton
@onready var quit_button: TextureButton = $BookColumns/RightPage/QuitButton

func _ready() -> void:
	master_slider.value_changed.connect(func(val: float): _set_bus_volume("Master", val))
	music_slider.value_changed.connect(func(val: float): _set_bus_volume("Music", val))
	sfx_slider.value_changed.connect(func(val: float): _set_bus_volume("SFX", val))
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	
	resume_button.pressed.connect(_on_resume_pressed)
	title_screen_button.pressed.connect(_on_title_screen_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	if not ResourceLoader.exists(MAIN_MENU_PATH):
		title_screen_button.disabled = true
		title_screen_button.modulate = Color(0.5, 0.5, 0.5, 0.8)
		
	for btn in [resume_button, title_screen_button, quit_button]:
		if btn:
			btn.mouse_entered.connect(func(): btn.self_modulate = Color(0.2, 0.2, 0.2, 0.525))
			btn.mouse_exited.connect(func(): btn.self_modulate = Color(1.0, 1.0, 1.0, 1.0))
	
	refresh()

func refresh() -> void:
	_sync_slider_with_bus(master_slider, "Master")
	_sync_slider_with_bus(music_slider, "Music")
	_sync_slider_with_bus(sfx_slider, "SFX")
	
	var current_mode := DisplayServer.window_get_mode()
	var is_fullscreen := (
		current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN
		or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	)
	fullscreen_check.set_pressed_no_signal(is_fullscreen)

func _sync_slider_with_bus(slider: HSlider, bus_name: String) -> void:
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		slider.editable = false
		return
		
	slider.editable = true
	if AudioServer.is_bus_mute(bus_idx):
		slider.set_value_no_signal(0.0)
	else:
		var db := AudioServer.get_bus_volume_db(bus_idx)
		slider.set_value_no_signal(db_to_linear(db))

func _set_bus_volume(bus_name: String, linear_val: float) -> void:
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		return
		
	if linear_val <= 0.001:
		AudioServer.set_bus_mute(bus_idx, true)
	else:
		AudioServer.set_bus_mute(bus_idx, false)
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(linear_val))

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_resume_pressed() -> void:
	get_tree().call_group("pause_menu", "close_book")

func _on_title_screen_pressed() -> void:
	if not ResourceLoader.exists(MAIN_MENU_PATH):
		return
	get_tree().call_group("pause_menu", "close_book")
	GameManager.change_scene_with_fade(MAIN_MENU_PATH)

func _on_quit_pressed() -> void:
	get_tree().quit()
