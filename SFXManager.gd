extends Node

var sfx_volume: float = 1.0  # Range 0.0 to 1.0
var sfx_bus_name: String = "custombuslayout"

func set_sfx_volume(volume: float):
	sfx_volume = clamp(volume, 0.0, 1.0)
	var bus_index = AudioServer.get_bus_index(sfx_bus_name)
	if bus_index != -1:
		var volume_db = linear_to_db(sfx_volume)
		AudioServer.set_bus_volume_db(bus_index, volume_db)
		print("SFX volume set to: ", sfx_volume, " (", volume_db, "dB)")
	else:
		print("Error: SFX bus '", sfx_bus_name, "' not found")

func load_sfx_volume():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		sfx_volume = config.get_value("audio", "sfx_volume", 1.0)
		set_sfx_volume(sfx_volume)
	else:
		print("No settings file found, using default SFX volume.")

func _ready():
	load_sfx_volume()

func play_sfx(sound_effect: AudioStream):
	var audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	audio_player.stream = sound_effect
	audio_player.bus = sfx_bus_name
	audio_player.play()
	audio_player.connect("finished", Callable(audio_player, "queue_free"))
