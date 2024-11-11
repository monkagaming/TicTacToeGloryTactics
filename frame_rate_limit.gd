extends Control

@onready var fps_input: LineEdit = $HBoxContainer/FPSInput
@onready var invalid_label: Label = $HBoxContainer/InvalidLabel

var current_fps_limit: int = 60  # Default value

func _ready():
	fps_input.text = str(current_fps_limit)
	invalid_label.hide()
	fps_input.connect("text_submitted", Callable(self, "_on_fps_input_submitted"))
	fps_input.connect("focus_exited", Callable(self, "_on_fps_input_focus_exited"))
	load_fps_limit()

func _on_fps_input_submitted(new_text: String):
	update_fps_limit(new_text)

func _on_fps_input_focus_exited():
	update_fps_limit(fps_input.text)

func update_fps_limit(new_text: String):
	var new_fps = new_text.to_int()
	if new_fps >= 1 and new_fps <= 60:
		current_fps_limit = new_fps
		Engine.max_fps = current_fps_limit
		invalid_label.hide()
		save_fps_limit()
	else:
		invalid_label.text = "Invalid (1-60)"
		invalid_label.show()
		fps_input.text = str(current_fps_limit)  # Reset to current valid value

func save_fps_limit():
	var config = ConfigFile.new()
	config.load("user://settings.cfg")
	config.set_value("video", "fps_limit", current_fps_limit)
	config.save("user://settings.cfg")

func load_fps_limit():
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		current_fps_limit = config.get_value("video", "fps_limit", 60)  # Default to 60 if not set
		fps_input.text = str(current_fps_limit)
		Engine.max_fps = current_fps_limit

# Call this when the settings menu is opened
func update_ui():
	load_fps_limit()
	fps_input.text = str(current_fps_limit)
	invalid_label.hide()

func _gui_input(event):
	if event.is_action_pressed("ui_accept"):
		fps_input.grab_focus()
