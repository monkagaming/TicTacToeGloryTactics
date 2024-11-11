extends Node

var fps_enabled: bool = true

func toggle_fps(enabled: bool):
	fps_enabled = enabled
	update_fps_counters()

func update_fps_counters():
	for node in get_tree().get_nodes_in_group("fps_counters"):
		node.visible = fps_enabled

func _ready():
	call_deferred("update_fps_counters")

# Call this function when a new scene is loaded
func on_scene_changed():
	call_deferred("update_fps_counters")
