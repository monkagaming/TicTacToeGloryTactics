extends Control

@onready var fullscreen_check: CheckBox = $HBoxContainer/FullscreenCheck

func _ready() -> void:
	# Initialize fullscreen checkbox
	fullscreen_check.set_pressed(FullscreenManager.is_fullscreen)
	
	# Connect the toggled signal
	if not fullscreen_check.is_connected("toggled", Callable(self, "_on_FullscreenCheck_toggled")):
		fullscreen_check.connect("toggled", Callable(self, "_on_FullscreenCheck_toggled"))
	
	# Load saved fullscreen setting
	load_fullscreen_setting()

func _gui_input(event):
	if event.is_action_pressed("ui_accept"):
		fullscreen_check.button_pressed = !fullscreen_check.button_pressed
		_on_FullscreenCheck_toggled(fullscreen_check.button_pressed)
	accept_event()

func _on_FullscreenCheck_toggled(button_pressed: bool) -> void:
	FullscreenManager.set_fullscreen(button_pressed)
	save_fullscreen_setting(button_pressed)

func load_fullscreen_setting():
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		var is_fullscreen = config.get_value("video", "fullscreen", false)
		fullscreen_check.set_pressed(is_fullscreen)
		FullscreenManager.set_fullscreen(is_fullscreen)
	else:
		print("No settings file found, using default fullscreen setting.")

func save_fullscreen_setting(is_fullscreen: bool):
	var config = ConfigFile.new()
	config.load("user://settings.cfg")
	config.set_value("video", "fullscreen", is_fullscreen)
	config.save("user://settings.cfg")

func _notification(what):
	if what == NOTIFICATION_FOCUS_ENTER:
		modulate = Color(1.2, 1.2, 1.2)  # Brighten when focused
	elif what == NOTIFICATION_FOCUS_EXIT:
		modulate = Color(1, 1, 1)  # Normal color when not focused
