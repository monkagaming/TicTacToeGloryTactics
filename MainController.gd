extends Node

# Called when the scene is loaded
func _ready():
	# Preload and instance your UI scene
	var ui_scene = preload("res://Scenes/UI.tscn").instance()
	add_child(ui_scene)

	# Connect Play Button in the instantiated UI scene
	var play_button = ui_scene.get_node("PlayButton")
	play_button.connect("pressed", Callable(self, "_on_PlayButton_pressed"))

# Function for Play Button
func _on_PlayButton_pressed():
	print("Play Button Pressed")
	# Ensure music continues playing; don't create a new instance
	get_tree().change_scene("res://Scenes/play_selection.tscn")
