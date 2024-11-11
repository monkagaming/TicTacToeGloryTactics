extends Control

@export var tween_intensity: float
@export var tween_duration: float

@onready var easy: Button = $EasyButton2
@onready var medium: Button = $MediumButton2
@onready var hard: Button = $HardButton2
@onready var back: Button = $BackToTheSimplePlayMode

var button9_click_player: AudioStreamPlayer

var focusable_buttons: Array = []
var current_focus_index: int = 0

func _ready():
	if has_node("CanvasLayer/Control/FPS_COUNTER_AIDifficultySelectionSimple"):
		$CanvasLayer/Control/FPS_COUNTER_AIDifficultySelectionSimple.add_to_group("fps_counters")
		$CanvasLayer/Control/FPS_COUNTER_AIDifficultySelectionSimple.visible = FpsManager.fps_enabled
	
	button9_click_player = $Button9ClickPlayer
	button9_click_player.stream = load("res://Sounds/click.ogg")

	# Set up focusable buttons
	focusable_buttons = [easy, medium, hard, back]
	for button in focusable_buttons:
		button.focus_mode = Control.FOCUS_ALL

	# Connect button signals
	connect_buttons()

	# Set initial focus
	set_initial_focus()

	# Connect input events
	set_process_input(true)

func connect_buttons():
	if not easy.is_connected("pressed", Callable(self, "_on_easy_button_pressed")):
		easy.connect("pressed", Callable(self, "_on_easy_button_pressed"))
	
	if not medium.is_connected("pressed", Callable(self, "_on_medium_button_pressed")):
		medium.connect("pressed", Callable(self, "_on_medium_button_pressed"))
	
	if not hard.is_connected("pressed", Callable(self, "_on_hard_button_pressed")):
		hard.connect("pressed", Callable(self, "_on_hard_button_pressed"))
	
	if not back.is_connected("pressed", Callable(self, "_on_BackToTheSimplePlayMode_pressed")):
		back.connect("pressed", Callable(self, "_on_BackToTheSimplePlayMode_pressed"))

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
		change_focus(-1, 0)  # Move left (if applicable)
		get_viewport().set_input_as_handled()
		
	elif event.is_action_pressed("ui_right"):
		change_focus(1, 0)  # Move right (if applicable)
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("ui_accept"):
		if focusable_buttons[current_focus_index].has_focus():
			focusable_buttons[current_focus_index].emit_signal("pressed")
			get_viewport().set_input_as_handled()  # Prevent double input
			
	elif event.is_action_pressed("ui_cancel"):  # Check for cancel action
		_on_BackToTheSimplePlayMode_pressed()  # Call the back button function

func change_focus(dx: int, dy: int):
	if dy != 0:  # Vertical movement
		current_focus_index += dy
		
		# Clamp vertical movement within bounds
		current_focus_index = clamp(current_focus_index, 0, focusable_buttons.size() - 1)
		
	elif dx != 0:  # Horizontal movement (if applicable)
		current_focus_index += dx
		
		# Clamp horizontal movement within bounds (if you have horizontal buttons)
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
	button9_click_player.play()

func _on_easy_button_pressed() -> void:
	_play_button_click_sound()
	await get_tree().create_timer(0.1).timeout
	print("Easy difficulty selected")
	start_game("easy")

func _on_medium_button_pressed() -> void:
	_play_button_click_sound()
	await get_tree().create_timer(0.1).timeout
	print("Medium difficulty selected")
	start_game("medium")

func _on_hard_button_pressed() -> void:
	_play_button_click_sound()
	await get_tree().create_timer(0.1).timeout
	print("Hard difficulty selected")
	start_game("hard")

func _on_BackToTheSimplePlayMode_pressed() -> void:
	_play_button_click_sound()
	await get_tree().create_timer(0.1).timeout
	Transition.load_scene("res://Scenes/PlayModeSelectionSimple.tscn")

func start_game(difficulty: String) -> void:
	Global.ai_difficulty = difficulty  # Set the global AI difficulty
	print("Starting game with difficulty: ", difficulty)
	Transition.load_scene("res://Scenes/AISimpleTicTacToe.tscn")
