extends Control

var credits_popup: Popup = null
var button_click_player: AudioStreamPlayer = null  # Reference to the AudioStreamPlayer

@export var tween_intensity: float
@export var tween_duration: float

@onready var play: Button = $MarginContainer/VBoxContainer/PlayButton
@onready var settings: Button = $MarginContainer/VBoxContainer/SettingsButton
@onready var stats: Button = $MarginContainer/VBoxContainer/StatsButton
@onready var leaderboard: Button = $MarginContainer/VBoxContainer/LeaderboardButton
@onready var credits: Button = $MarginContainer/VBoxContainer/CreditsButton
@onready var skip_track: Button = $SkipTrack
@onready var exit: Button = $MarginContainer/VBoxContainer/ExitButton
@onready var margin_container = $MarginContainer
@onready var main_container = $MarginContainer/VBoxContainer


var CreditsScene = preload("res://Scenes/Credits.tscn")

enum INPUT_SCHEMES { KEYBOARD_AND_MOUSE, GAMEPAD, TOUCH_SCREEN }
static var INPUT_SCHEME: INPUT_SCHEMES = INPUT_SCHEMES.KEYBOARD_AND_MOUSE

var focusable_buttons: Array = []
var current_focus_index: int = 0

func _ready():
	get_window().grab_focus()
	if not $MarginContainer/VBoxContainer/LeaderboardButton.is_connected("pressed", Callable(self, "_on_Leaderboard_pressed")):
		$MarginContainer/VBoxContainer/LeaderboardButton.connect("pressed", Callable(self, "_on_Leaderboard_pressed"))
	
	if not credits.is_connected("pressed", Callable(self, "_on_CreditsButton_pressed")):
		credits.connect("pressed", Callable(self, "_on_CreditsButton_pressed"))

	print("UI: Checking music status")
	MusicManager.ensure_playing()
	
	# Set up the layout
	setup_layout()

	# Initialize AudioStreamPlayer reference and set the sound stream
	button_click_player = $ButtonClickPlayer
	button_click_player.stream = load("res://Sounds/click.ogg")

	# Register the music player with AudioManager
	AudioManager.register_music_player(MusicManager.music_player)

	# Register the button click player with AudioManager
	if button_click_player:
		AudioManager.register_sfx_player(button_click_player)

	# Load and apply audio settings
	AudioManager.load_and_apply_settings()

	if $SubscribeLabel:
		$SubscribeLabel.connect("gui_input", Callable(self, "_on_SubscribeLabel_clicked"))

	if $DiscordLabel:
		$DiscordLabel.connect("gui_input", Callable(self, "_on_DiscordLabel_clicked"))
	
	if $MakeSureLabel:
		$MakeSureLabel.connect("gui_input", Callable(self, "_on_MakeSureLabel_clicked"))

	# Connect the SkipTrack button
	if not skip_track.is_connected("pressed", Callable(self, "_on_SkipTrack_pressed")):
		skip_track.connect("pressed", Callable(self, "_on_SkipTrack_pressed"))
		

	# Initialize FPS counter
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		var fps_counter_enabled = config.get_value("video", "fps_counter", true)
		FpsManager.toggle_fps(fps_counter_enabled)
		
		get_tree().root.connect("ready", Callable(self, "_on_scene_changed"))
	InputManager.load_input_settings()  # Load input settings at startup

	if InputManager.INPUT_SCHEME == InputManager.INPUT_SCHEMES.KEYBOARD_AND_MOUSE:
		print("Keyboard and Mouse scheme loaded.")
	elif InputManager.INPUT_SCHEME == InputManager.INPUT_SCHEMES.GAMEPAD:
		print("Gamepad scheme loaded.")
		
	# Set up focusable buttons in the desired order
	focusable_buttons = [play, settings, stats, leaderboard, exit, credits, skip_track]
	for button in focusable_buttons:
		button.focus_mode = Control.FOCUS_ALL
		
	get_tree().root.size_changed.connect(self.on_window_resized)
	# Set initial focus
	set_initial_focus()

func setup_layout():
	# Set margins for the MarginContainer
	margin_container.add_theme_constant_override("margin_top", 20)
	margin_container.add_theme_constant_override("margin_bottom", 20)
	margin_container.add_theme_constant_override("margin_left", 20)
	margin_container.add_theme_constant_override("margin_right", 20)
	
	# Set the main container to expand
	main_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func on_window_resized():
	# This function will be called whenever the window is resized
	# You can add any additional resizing logic here if needed
	pass

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
	elif event.is_action_pressed("ui_accept"):
		if focusable_buttons[current_focus_index].has_focus():
			focusable_buttons[current_focus_index].emit_signal("pressed")
			get_viewport().set_input_as_handled()  # Prevent double input

func change_focus(dx: int, dy: int):
	if dy != 0:  # Vertical movement
		current_focus_index += dy
		current_focus_index = clamp(current_focus_index, 0, focusable_buttons.size() - 1)
	else:  # Horizontal movement
		current_focus_index += dx
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

func _on_SettingsButton_pressed():
	_play_button_click_sound()
	print("Settings Button Clicked!")

	# Instead of showing a Popup, we will transition to the Settings scene
	Transition.load_scene("res://Scenes/settings_tab_container.tscn")

# Function to play button click sound
func _play_button_click_sound():
	var sfx_manager = get_node("/root/SFXManager")
	if sfx_manager:
		var click_sound = preload("res://Sounds/click.ogg")  # Adjust this path to match your project structure
		sfx_manager.play_sfx(click_sound)
	else:
		print("SFXManager not found!")

# Function to handle link clicks
func _on_link_clicked(meta: String):
	print("Clicked link: ", meta)  # Print the clicked link
	OS.shell_open(meta)  # Open the link in the default browser

func _on_PlayButton_pressed():
	print("Play Button sound trigger")
	_play_button_click_sound()  # Play the button click sound

	# Add a slight delay if necessary
	await get_tree().create_timer(0.15).timeout

	print("Play Button Pressed")
	Transition.load_scene("res://Scenes/ultimate_or_simple.tscn")
	# get_tree().change_scene_to_file("res://ultimate_or_simple.tscn")

func _on_DiscordLabel_clicked(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("Discord Label Clicked!")  # Print message when Discord label is clicked
		OS.shell_open("https://discord.gg/hX9JeZD7Rx")  # Open Discord in default browser

# Function to handle when the SubscribeLabel is clicked
func _on_SubscribeLabel_clicked(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("Subscribe Label Clicked!")  # Print message when Subscribe label is clicked
		OS.shell_open("https://www.youtube.com/@monkagaming420")  # Open YouTube channel in the default browser

func _on_MakeSureLabel_clicked(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("Github Download Clicked")
		OS.shell_open("https://github.com/monkagaming/TicTacToeGloryTactics")

func _on_statsbutton_pressed() -> void:
	_play_button_click_sound()  # Play the button click sound
	print("Stats Button Clicked!")  # Log button click to the console

	# Load and instance the StatsPopUp.tscn
	var packed_scene = preload("res://Scenes/StatsPopUp.tscn")  # Preload the scene
	var stats_popup = packed_scene.instantiate()  # Instantiate the scene
	get_tree().current_scene.add_child(stats_popup)  # Add to the current scene
	stats_popup.popup_centered()  # Show it centered on the screen
	stats_popup.grab_focus()  # Grab focus for the popup after opening it

func _on_Leaderboard_pressed():
	var leaderboard_popup = preload("res://Scenes/leaderboard.tscn").instantiate()
	add_child(leaderboard_popup)
	# leaderboard_popup.set_leaderboard_text("")  # Change the text dynamically , use this later when I change it.
	leaderboard_popup.popup_centered()


func _on_SkipTrack_pressed():
	_play_button_click_sound()  # Play the button click sound
	print("Skip Track Button Clicked!")  # Log button click to the console
	MusicManager.skip_and_shuffle()

func _on_scene_changed():
	FpsManager.on_scene_changed()

func load_input_settings():
	var config = ConfigFile.new()
	if config.load("user://input_settings.cfg") == OK:
		INPUT_SCHEME = config.get_value("input", "scheme", INPUT_SCHEMES.KEYBOARD_AND_MOUSE)
	else:
		print("No input settings found, using default.")


func _on_exit_button_pressed() -> void:
	get_tree().quit()


func _on_CreditsButton_pressed():
	_play_button_click_sound()  # Play the button click sound

	# Load and instance the Credits scene
	if not credits_popup:
		var packed_scene = preload("res://Scenes/Credits.tscn")
		credits_popup = packed_scene.instantiate()  # Instantiate the Credits popup
		add_child(credits_popup)  # Add the popup to the current scene
	
	# Show the popup
	credits_popup.popup_centered()
	credits_popup.focus_first_element()  # Focus the first element in the popup
