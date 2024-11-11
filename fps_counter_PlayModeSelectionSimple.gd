extends Control

func _ready():
	add_to_group("fps_counters")

func _process(_delta: float) -> void:
	$FPS_COUNTER_PlayModeSelectionSimple.text = str(Engine.get_frames_per_second())
