extends Node

var music_player: AudioStreamPlayer
var is_initialized: bool = false
var playlist: Array = []
var current_track_index: int = -1

func skip_and_shuffle():
	shuffle_playlist()
	play_next_track()

func _enter_tree():
	if not is_initialized:
		music_player = AudioStreamPlayer.new()
		add_child(music_player)
		is_initialized = true
		print("MusicManager: Initialized")
		
		# Initialize the playlist
		playlist = [
			"res://Music/vibes.ogg",
			"res://Music/Bobbin.ogg",
			"res://Music/Carefree.ogg",
			"res://Music/Lazy Day.ogg",
			"res://Music/Decay.ogg",
			"res://Music/DoneWithWork.ogg",
			"res://Music/Island.ogg",
			"res://Music/SunsetDream.ogg"
		]
		
		# Shuffle the playlist
		shuffle_playlist()
		
		# Connect the finished signal
		music_player.connect("finished", Callable(self, "_on_track_finished"))

func shuffle_playlist():
	randomize()  # Initialize random number generator
	playlist.shuffle()
	current_track_index = -1  # Reset the index
	print("MusicManager: Playlist shuffled")

func set_volume(volume_db: float):
	if music_player:
		music_player.volume_db = volume_db

func play_next_track():
	current_track_index = (current_track_index + 1) % playlist.size()
	if current_track_index == 0:
		shuffle_playlist()  # Reshuffle when we've gone through the whole list
	var next_track = load(playlist[current_track_index])
	music_player.stream = next_track
	music_player.play()
	print("MusicManager: Playing track - ", playlist[current_track_index])

func play():
	if not is_playing():
		play_next_track()
	else:
		print("MusicManager: Music already playing")

func stop():
	if music_player and music_player.playing:
		music_player.stop()
		print("MusicManager: Stopping music playback")

func is_playing() -> bool:
	return music_player and music_player.playing

func ensure_playing():
	if not is_playing():
		play()
	else:
		print("MusicManager: Music already playing, no action needed")

func _on_track_finished():
	play_next_track()
