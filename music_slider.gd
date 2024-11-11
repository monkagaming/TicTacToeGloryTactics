extends Control

var volume_slider: HSlider
var hbox_container: HBoxContainer
@onready var audionumberlabel: Label = $HBoxContainer/AudioNumberLabel

func _ready():
	hbox_container = get_node("HBoxContainer")
	volume_slider = hbox_container.get_node("Volume_Slider")
	audionumberlabel = hbox_container.get_node("AudioNumberLabel")

	# Load the saved volume setting
	load_volume_setting()

	# Connect the value_changed signal
	if not volume_slider.is_connected("value_changed", Callable(self, "_on_Volume_Slider_value_changed")):
		volume_slider.connect("value_changed", Callable(self, "_on_Volume_Slider_value_changed"))

func _on_Volume_Slider_value_changed(value: float):
	var volume_db = value / 100 * 60 - 60
	MusicManager.set_volume(volume_db)
	update_audio_number_label(value)
	save_volume_setting(value)

func update_audio_number_label(value: float):
	audionumberlabel.text = str(int(value)) + "%"

func load_volume_setting():
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		var volume = config.get_value("audio", "volume", 100)
		volume_slider.value = volume
		_on_Volume_Slider_value_changed(volume)  # Update the volume immediately
	else:
		print("No settings file found, using default volume.")

func save_volume_setting(value: float):
	var config = ConfigFile.new()
	config.load("user://settings.cfg")
	config.set_value("audio", "volume", value)
	config.save("user://settings.cfg")

func _gui_input(event):
	if event.is_action_pressed("ui_left"):
		volume_slider.value -= 5  # or whatever step you prefer
	elif event.is_action_pressed("ui_right"):
		volume_slider.value += 5  # or whatever step you prefer
