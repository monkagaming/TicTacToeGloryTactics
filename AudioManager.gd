extends Node

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []

func _ready():
	load_and_apply_settings()

func load_and_apply_settings():
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		var volume = config.get_value("audio", "volume", 100)
		var is_muted = config.get_value("audio", "sfx_mute", false)
		
		# Apply volume to music
		if music_player and is_instance_valid(music_player):
			music_player.volume_db = volume / 100 * 60 - 60
		
		# Apply mute state to SFX and remove invalid players
		sfx_players = sfx_players.filter(func(player): return is_instance_valid(player))
		for player in sfx_players:
			player.volume_db = -80 if is_muted else 0

func register_music_player(player: AudioStreamPlayer):
	music_player = player
	load_and_apply_settings()

func register_sfx_player(player: AudioStreamPlayer):
	if player and is_instance_valid(player) and not sfx_players.has(player):
		sfx_players.append(player)
		load_and_apply_settings()
