extends Control

@export var tween_intensity: float
@export var tween_duration: float

var button4_click_player: AudioStreamPlayer = null
@onready var easy: Button = $EasyButton
@onready var medium: Button = $MediumButton
@onready var hard: Button = $HardButton
@onready var back: Button = $BackToPlayModeButton

var focusable_buttons: Array = []
var current_focus_index: int = 0

func _ready():
	if has_node("CanvasLayer/Control/FPS_COUNTER_AIDifficultySelectionUltimate"):
		$CanvasLayer/Control/FPS_COUNTER_AIDifficultySelectionUltimate.add_to_group("fps_counters")
		$CanvasLayer/Control/FPS_COUNTER_AIDifficultySelectionUltimate.visible = FpsManager.fps_enabled
	
	button4_click_player = $Button4ClickPlayer
	button4_click_player.stream = load("res://Sounds/click.ogg")

	# Set up focusable buttons
	focusable_buttons = [easy, medium, hard, back]
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
		change_focus(0, 1)  # Move down
		get_viewport().set_input_as_handled()
		
	elif event.is_action_pressed("ui_up"):
		change_focus(0, -1)  # Move up
		get_viewport().set_input_as_handled()
		
	elif event.is_action_pressed("ui_left"):
		change_focus(-1, 0)  # Move left
		get_viewport().set_input_as_handled()
		
	elif event.is_action_pressed("ui_right"):
		change_focus(1, 0)  # Move right
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("ui_accept"):
		if focusable_buttons[current_focus_index].has_focus():
			focusable_buttons[current_focus_index].emit_signal("pressed")
			get_viewport().set_input_as_handled()  # Prevent double input
			
	elif event.is_action_pressed("ui_cancel"):  # Check for cancel action
		_on_BackToPlayModeButton_pressed()  # Call the back button function

func change_focus(dx: int, dy: int):
	if dy != 0:  # Vertical movement
		current_focus_index += dy
		
		# Clamp vertical movement within bounds
		current_focus_index = clamp(current_focus_index, 0, focusable_buttons.size() - 1)
		
	elif dx != 0:  # Horizontal movement
		current_focus_index += dx
		
		# Clamp horizontal movement within bounds
		current_focus_index = clamp(current_focus_index, 0, focusable_buttons.size() - 1)

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
	button4_click_player.play()

func _on_EasyButton_pressed():
	_play_button_click_sound()
	print("Ultimate Tic Tac Toe AI Difficulty set to Easy.")
	await get_tree().create_timer(0.1).timeout
	start_game_with_difficulty("Easy")

func _on_MediumButton_pressed():
	_play_button_click_sound()
	print("Ultimate Tic Tac Toe AI Difficulty set to Medium.")
	await get_tree().create_timer(0.1).timeout
	start_game_with_difficulty("Medium")

func _on_HardButton_pressed():
	_play_button_click_sound()
	print("Ultimate Tic Tac Toe AI Difficulty set to Hard.")
	await get_tree().create_timer(0.1).timeout
	start_game_with_difficulty("Hard")

func start_game_with_difficulty(difficulty: String):
	get_tree().root.set("ai_difficulty", difficulty)
	Transition.load_scene("res://Scenes/AIminiboard.tscn")

func _on_BackToPlayModeButton_pressed() -> void:
	_play_button_click_sound()
	print("Back to Play Mode Selection")
	await get_tree().create_timer(0.1).timeout
	Transition.load_scene("res://Scenes/PlayModeSelectionUltimate.tscn")
