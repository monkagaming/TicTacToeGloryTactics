extends Node

var is_fullscreen = false

func toggle_fullscreen():
	is_fullscreen = !is_fullscreen
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func set_fullscreen(value: bool):
	if value != is_fullscreen:
		toggle_fullscreen()
