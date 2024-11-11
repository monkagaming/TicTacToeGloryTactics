# InputManager.gd
extends Node

enum INPUT_SCHEMES { KEYBOARD_AND_MOUSE, GAMEPAD, TOUCH_SCREEN }
var INPUT_SCHEME: INPUT_SCHEMES = INPUT_SCHEMES.KEYBOARD_AND_MOUSE

# Load input settings from config
func load_input_settings():
	var config = ConfigFile.new()
	if config.load("user://input_settings.cfg") == OK:
		INPUT_SCHEME = config.get_value("input", "scheme", INPUT_SCHEMES.KEYBOARD_AND_MOUSE)
	else:
		print("No input settings found, using default.")

# Save input settings to config
func save_input_settings():
	var config = ConfigFile.new()
	config.load("user://input_settings.cfg")
	config.set_value("input", "scheme", INPUT_SCHEME)
	config.save("user://input_settings.cfg")
