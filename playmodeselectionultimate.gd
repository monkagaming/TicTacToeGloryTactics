extends Control

@export var tween_intensity: float
@export var tween_duration: float

@onready var ai: Button = $AIModeButton
@onready var yourself: Button = $YourselfButton
@onready var back: Button = $BackToUltimateOrSimple

var button3_click_player: AudioStreamPlayer = null

var focusable_buttons: Array = []
var current_focus_index: int = 0

func _ready():
	if has_node("CanvasLayer/Control/FPS_COUNTER_PlayModeSelectionUltimate"):
		$CanvasLayer/Control/FPS_COUNTER_PlayModeSelectionUltimate.add_to_group("fps_counters")
		$CanvasLayer/Control/FPS_COUNTER_PlayModeSelectionUltimate.visible = FpsManager.fps_enabled
	
	print("PlayModeSelectionUltimate is ready")

	button3_click_player = $Button3ClickPlayer
	button3_click_player.stream = load("res://Sounds/click.ogg")

	# Set up focusable buttons
	focusable_buttons = [ai, yourself, back]
	for button in focusable_buttons:
		button.focus_mode = Control.FOCUS_ALL

	# Set initial focus
	set_initial_focus()

	# Connect input events
	set_process_input(true)

func set_initial_focus():
	if not focusable_buttons.is_empty():
		focusable_buttons[0].grab_focus()
		current_focus_index = 0

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_down"):
		change_focus(1)  # Move down
		get_viewport().set_input_as_handled()
		
	elif event.is_action_pressed("ui_up"):
		change_focus(-1)  # Move up
		get_viewport().set_input_as_handled()
		
	elif event.is_action_pressed("ui_accept"):
		if focusable_buttons[current_focus_index].has_focus():
			focusable_buttons[current_focus_index].emit_signal("pressed")
			get_viewport().set_input_as_handled()  # Prevent double input
			
	elif event.is_action_pressed("ui_cancel"):  # Check for cancel action
		_on_BackToUltimateOrSimple_pressed()  # Call the back button function

func change_focus(direction):
	current_focus_index = (current_focus_index + direction) % focusable_buttons.size()
	if current_focus_index < 0:
		current_focus_index = focusable_buttons.size() - 1
		
	# Grab focus on the newly selected button
	focusable_buttons[current_focus_index].grab_focus()

func _process(_delta: float) -> void:
	for button in focusable_buttons:
		button_hovered(button)

func button_hovered(button: Button):
	button.pivot_offset = button.size / 2
	if button.is_hovered() or button.has_focus():
		start_tween(button, "scale", Vector2.ONE * tween_intensity, tween_duration)
	else: 
		start_tween(button, "scale", Vector2.ONE, tween_duration)

func start_tween(object: Object, property: String, final_val: Variant, duration: float):
	var tween = create_tween()
	tween.tween_property(object, property, final_val, duration)

func _play_button_click_sound():
	print("Playing button click sound")
	button3_click_player.play()

func _on_AIModeButton_pressed():
	_play_button_click_sound()
	print("AIModeButton pressed")
	await get_tree().create_timer(0.1).timeout
	Transition.load_scene("res://Scenes/AIDifficultySelectionUltimate.tscn")

func _on_yourself_pressed():
	_play_button_click_sound()
	print("YourselfButton pressed")
	await get_tree().create_timer(0.1).timeout
	Transition.load_scene("res://Scenes/miniboard.tscn")

func _on_BackToUltimateOrSimple_pressed() -> void:
	_play_button_click_sound()
	print("BackToUltimateOrSimple Button pressed")
	await get_tree().create_timer(0.1).timeout
	Transition.load_scene("res://Scenes/ultimate_or_simple.tscn")
