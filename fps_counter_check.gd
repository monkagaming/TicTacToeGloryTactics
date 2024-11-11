extends Control

var fps_counter_check: CheckButton

func _ready() -> void:
	# Find the CheckButton node with the correct name
	fps_counter_check = find_child("FPSCheckButton") as CheckButton
	
	if fps_counter_check:
		# Connect the toggled signal
		if not fps_counter_check.is_connected("toggled", Callable(self, "_on_FPSCounter_check_toggled")):
			fps_counter_check.connect("toggled", Callable(self, "_on_FPSCounter_check_toggled"))
		
		# Load saved FPS counter setting
		load_fps_counter_setting()
	else:
		push_error("FPSCheckButton node not found!")

func _on_FPSCounter_check_toggled(toggled_on: bool) -> void:
	FpsManager.toggle_fps(toggled_on)
	save_fps_counter_setting(toggled_on)

func load_fps_counter_setting():
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		var fps_counter_enabled = config.get_value("video", "fps_counter", true)
		FpsManager.toggle_fps(fps_counter_enabled)
	else:
		print("No settings file found, using default FPS counter setting.")
	
	# Always update the checkbox to reflect the current state in FpsManager
	update_checkbox_state()

func save_fps_counter_setting(is_enabled: bool):
	var config = ConfigFile.new()
	config.load("user://settings.cfg")
	config.set_value("video", "fps_counter", is_enabled)
	config.save("user://settings.cfg")

func _gui_input(event):
	if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
		accept_event()  # Prevent the event from propagating

# Add this function to update the checkbox state when the settings are opened
func update_checkbox_state():
	if fps_counter_check:
		fps_counter_check.set_pressed_no_signal(FpsManager.fps_enabled)

# Call this function when the node becomes visible
func _on_visibility_changed():
	if visible:
		update_checkbox_state()
