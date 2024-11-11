extends Control

@export var tween_intensity: float
@export var tween_duration: float

@onready var ultimate: Button = $UltimateTicTacToeButton
@onready var simple: Button = $SimpleTicTacToeButton
@onready var back: Button = $BackToUIButton
@onready var tutorial: Button = $TutorialButton

var button2_click_player: AudioStreamPlayer = null
var focusable_buttons: Array = []
var current_focus_index: int = 0

func _ready():
	get_window().grab_focus()
	if has_node("CanvasLayer/Control/FPS_COUNTER_ULTIMATE_OR_SIMPLE"):
		$CanvasLayer/Control/FPS_COUNTER_ULTIMATE_OR_SIMPLE.add_to_group("fps_counters")
		$CanvasLayer/Control/FPS_COUNTER_ULTIMATE_OR_SIMPLE.visible = FpsManager.fps_enabled

	button2_click_player = $Button2ClickPlayer
	button2_click_player.stream = load("res://Sounds/click.ogg")

	connect_buttons()
	InputManager.load_input_settings()

	# Set up focusable buttons in the desired order
	focusable_buttons = [ultimate, simple, back, tutorial]
	for button in focusable_buttons:
		button.focus_mode = Control.FOCUS_ALL
		
	# Set initial focus
	set_initial_focus()

func connect_buttons():
	if not ultimate.is_connected("pressed", Callable(self, "_on_UltimateTicTacToeButton_pressed")):
		ultimate.connect("pressed", Callable(self, "_on_UltimateTicTacToeButton_pressed"))

	if not simple.is_connected("pressed", Callable(self, "_on_SimpleTicTacToeButton_pressed")):
		simple.connect("pressed", Callable(self, "_on_SimpleTicTacToeButton_pressed"))

	if not back.is_connected("pressed", Callable(self, "_on_BackToUI_pressed")):
		back.connect("pressed", Callable(self, "_on_BackToUI_pressed"))

	if not tutorial.is_connected("pressed", Callable(self, "_on_TutorialButton_pressed")):
		tutorial.connect("pressed", Callable(self, "_on_TutorialButton_pressed"))

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
		_on_BackToUI_pressed()  # Call the back button function

func change_focus(dx: int, dy: int):
	if dy != 0:  # Vertical movement
		current_focus_index += dy
		
		# Clamp vertical movement within bounds
		current_focus_index = clamp(current_focus_index, 0, focusable_buttons.size() - 1)
		
	elif dx != 0:  # Horizontal movement
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
	print("Playing button click sound")
	button2_click_player.play()

func _on_UltimateTicTacToeButton_pressed():
	_play_button_click_sound()
	print("Ultimate Tic Tac Toe Button Pressed")
	await get_tree().create_timer(0.1).timeout
	Transition.load_scene("res://Scenes/PlayModeSelectionUltimate.tscn")

func _on_SimpleTicTacToeButton_pressed():
	_play_button_click_sound()
	await get_tree().create_timer(0.1).timeout
	Transition.load_scene("res://Scenes/PlayModeSelectionSimple.tscn")

func _on_BackToUI_pressed():
	_play_button_click_sound()
	print("Back To UI Button Pressed")
	await get_tree().create_timer(0.1).timeout
	Transition.load_scene("res://Scenes/UI.tscn")

func _on_TutorialButton_pressed():
	_play_button_click_sound()
	print("Tutorial Button Pressed")
	var tutorial_url = "https://www.youtube.com/watch?v=F0SajUVSGKo"
	OS.shell_open(tutorial_url)
