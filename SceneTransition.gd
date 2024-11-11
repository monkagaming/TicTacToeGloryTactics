extends CanvasLayer

@onready var animation_player = $AnimationPlayer
@onready var transition_rect = $TransitionRect

func _ready():
	transition_rect.visible = false

func load_scene(target_scene: String):
	animation_player.play("fade")
	await animation_player.animation_finished
	get_tree().change_scene_to_file(target_scene)
	animation_player.play_backwards("fade")


func reload_scene():
	animation_player.play("fade")
	await animation_player.animation_finished
	get_tree().reload_current_scene()
	animation_player.play_backwards("fade")
