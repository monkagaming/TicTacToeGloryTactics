extends Control

var sfx_slider: HSlider
var hbox_container: HBoxContainer
@onready var sfx_number_label: Label = $HBoxContainer/SFXNumberLabel

func _ready():
	hbox_container = get_node("HBoxContainer")
	sfx_slider = hbox_container.get_node("SFX_Slider")
	sfx_number_label = hbox_container.get_node("SFXNumberLabel")

	# Load the saved SFX volume setting
	load_sfx_volume_setting()

	# Connect the value_changed signal
	if not sfx_slider.is_connected("value_changed", Callable(self, "_on_SFX_Slider_value_changed")):
		sfx_slider.connect("value_changed", Callable(self, "_on_SFX_Slider_value_changed"))

func _on_SFX_Slider_value_changed(value: float):
	var sfx_manager = get_node("/root/SFXManager")
	if sfx_manager:
		sfx_manager.set_sfx_volume(value / 100.0)
	else:
		print("SFXManager is not found!")
	
	update_sfx_number_label(value)
	save_sfx_volume_setting(value)

func update_sfx_number_label(value: float):
	sfx_number_label.text = str(int(value)) + "%"

func load_sfx_volume_setting():
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		var sfx_volume = config.get_value("audio", "sfx_volume", 1.0) * 100
		sfx_slider.value = sfx_volume
		_on_SFX_Slider_value_changed(sfx_volume)  # Update the volume immediately
	else:
		print("No settings file found, using default SFX volume.")

func save_sfx_volume_setting(value: float):
	var config = ConfigFile.new()
	config.load("user://settings.cfg")
	config.set_value("audio", "sfx_volume", value / 100.0)
	config.save("user://settings.cfg")

func _gui_input(event):
	if event.is_action_pressed("ui_left"):
		sfx_slider.value -= 5  # or whatever step you prefer
	elif event.is_action_pressed("ui_right"):
		sfx_slider.value += 5  # or whatever step you prefer
