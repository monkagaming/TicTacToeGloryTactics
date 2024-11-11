extends Popup

@export var tween_intensity: float
@export var tween_duration: float

var stats: Dictionary = {}  # To store the stats
var stats_file_path = "user://Stats.cfg"  # Use consistent filename

@onready var xopen: Button = $VBoxContainer/XOpen
@onready var discordopen: Button = $VBoxContainer/DiscordOpen
@onready var reset: Button = $VBoxContainer/ResetButton
@onready var close: Button = $VBoxContainer/CloseButton

var focusable_buttons: Array = []  # List of buttons in focus order
var current_focus_index: int = 0

func _ready():
	
	# Set the background color of ColorRect to gray
	$ColorRect.color = Color(0.2, 0.2, 0.2)  # RGB values for gray (normalized between 0 and 1)
	
	# Set the ColorRect size to the desired dimensions
	$ColorRect.size = Vector2(300, 500)  # Set to the desired size

	# Set focus mode for all buttons and add them to the focusable_buttons array
	focusable_buttons = [xopen, discordopen, reset, close]
	for button in focusable_buttons:
		button.focus_mode = Control.FOCUS_ALL
	
	# Set the initial focus when popup is ready
	if not focusable_buttons.is_empty():
		focusable_buttons[0].grab_focus()
		current_focus_index = 0

	load_stats()  # Load stats when ready
	display_stats()  # Display stats on the label
	
	# Set up signals for buttons
	if not reset.is_connected("pressed", Callable(self, "_on_ResetButton_pressed")):
		reset.connect("pressed", Callable(self, "_on_ResetButton_pressed"))

	grab_focus()  # Ensure this Popup gets focus when opened

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

func change_focus(_dx: int, dy: int):
	if dy != 0:  # Vertical movement
		current_focus_index += dy
		current_focus_index = clamp(current_focus_index, 0, focusable_buttons.size() - 1)
	# Grab focus on the newly selected button
	focusable_buttons[current_focus_index].grab_focus()

func _process(_delta: float) -> void:
	button_hovered(xopen)
	button_hovered(discordopen)
	button_hovered(reset)
	button_hovered(close)

func start_tween(object: Object, property: String, final_val: Variant, duration: float):
	var tween = create_tween()
	tween.tween_property(object, property, final_val, duration)

func button_hovered(button: Button):
	button.pivot_offset = button.size / 2
	if button.is_hovered():
		start_tween(button, "scale", Vector2.ONE * tween_intensity, tween_duration)
	else: 
		start_tween(button, "scale", Vector2.ONE, tween_duration)

func load_stats():
	var file = FileAccess.open("user://Stats.cfg", FileAccess.READ)  # Use consistent file name
	if file:
		stats.clear()  # Clear current stats before loading new ones
		while not file.eof_reached():
			var line = file.get_line()
			if line.begins_with("["):
				continue  # Skip section headers
			var key_value = line.split("=")
			if key_value.size() == 2:
				stats[key_value[0].strip_edges()] = int(key_value[1].strip_edges())
		file.close()
	else:
		print("Failed to open stats file for reading.")

func display_stats():
	var stats_text = "**WON**\n"
	stats_text += "Ultimate Tic Tac Toe AI Won: %d\n" % stats.get("Ultimate_Tic_Tac_Toe_AI_Won", 0)
	stats_text += "Ultimate Tic Tac Toe Yourself Won: %d\n" % stats.get("Ultimate_Tic_Tac_Toe_Yourself_Won", 0)
	stats_text += "Simple Tic Tac Toe AI Won: %d\n" % stats.get("Simple_Tic_Tac_Toe_AI_Won", 0)
	stats_text += "Simple Tic Tac Toe Yourself Won: %d\n\n" % stats.get("Simple_Tic_Tac_Toe_Yourself_Won", 0)
	stats_text += "**LOST**\n"
	stats_text += "Ultimate Tic Tac Toe AI Lost: %d\n" % stats.get("Ultimate_Tic_Tac_Toe_AI_Lost", 0)
	stats_text += "Ultimate Tic Tac Toe Yourself Lost: %d\n" % stats.get("Ultimate_Tic_Tac_Toe_Yourself_Lost", 0)
	stats_text += "Simple Tic Tac Toe AI Lost: %d\n" % stats.get("Simple_Tic_Tac_Toe_AI_Lost", 0)
	stats_text += "Simple Tic Tac Toe Yourself Lost: %d\n" % stats.get("Simple_Tic_Tac_Toe_Yourself_Lost", 0)

	$VBoxContainer/StatsLabel.text = stats_text  # Display stats on StatsLabel within VBoxContainer

func _on_ResetButton_pressed():
	reset_stats()  # Call the reset_stats function

func _on_CloseButton_pressed():
	queue_free()  # Close the popup when button is pressed

func reset_stats():
	# Reset all values in the dictionary to 0
	stats = {
		"Ultimate_Tic_Tac_Toe_AI_Won": 0,
		"Ultimate_Tic_Tac_Toe_Yourself_Won": 0,
		"Simple_Tic_Tac_Toe_AI_Won": 0,
		"Simple_Tic_Tac_Toe_Won": 0,
		"Ultimate_Tic_Tac_Toe_AI_Lost": 0,
		"Ultimate_Tic_Tac_Toe_Yourself_Lost": 0,
		"Simple_Tic_Tac_Toe_AI_Lost": 0,
		"Simple_Tic_Tac_Toe_Lost": 0
	}
	save_stats()  # Save the reset stats back to file
	display_stats()  # Refresh the display after reset

func save_stats():
	# Write current stats to the stats file
	var file = FileAccess.open(stats_file_path, FileAccess.WRITE)  # Use WRITE to overwrite
	if file:
		for key in stats.keys():
			file.store_line("%s=%d" % [key, stats[key]])
		file.close()
	else:
		print("Failed to open stats file for writing.")


func _on_XOpen_pressed():
	var stats_message = generate_stats_message()
	var x_url = "https://x.com/intent/tweet?text=%s" % url_encode(stats_message)
	OS.shell_open(x_url)  # Opens the URL in the default web browser
	
func generate_stats_message() -> String:
	# Create a formatted message with your stats
	var message = "Here are my stats!\n"
	message += "**WON**\n"
	message += "Ultimate TTT AI Won: %d\n" % stats.get("Ultimate_Tic_Tac_Toe_AI_Won", 0)
	message += "Ultimate TTT Yourself Won: %d\n" % stats.get("Ultimate_Tic_Tac_Toe_Yourself_Won", 0)
	message += "Simple TTT AI Won: %d\n" % stats.get("Simple_Tic_Tac_Toe_AI_Won", 0)
	message += "Simple TTT Yourself Won: %d\n\n" % stats.get("Simple_Tic_Tac_Toe_Yourself_Won", 0)
	message += "**LOST**\n"
	message += "Ultimate TTT AI Lost: %d\n" % stats.get("Ultimate_Tic_Tac_Toe_AI_Lost", 0)
	message += "Ultimate TTT Yourself Lost: %d\n" % stats.get("Ultimate_Tic_Tac_Toe_Yourself_Lost", 0)
	message += "Simple TTT AI Lost: %d\n" % stats.get("Simple_Tic_Tac_Toe_AI_Lost", 0)
	message += "Simple TTT Yourself Lost: %d\n" % stats.get("Simple_Tic_Tac_Toe_Yourself_Lost", 0)
	message += "#TicTacToeGloryTactics"
	return message

func url_encode(text: String) -> String:
	var encoded = ""
	for c in text:
		if c == " ":
			encoded += "%20"
		elif c == "\n":
			encoded += "%0A"
		elif c.is_valid_identifier() or c in "_-.~":  # Allowed characters in URLs
			encoded += c
		else:
			# Use `String.get_utf8_char()` to get the UTF-8 value of the character
			var ascii_value = c.to_utf8_buffer()[0]  # Get the ASCII value of the character (assuming single-byte UTF-8)
			encoded += "%" + String("%02X" % ascii_value)  # Format as hex with two digits
	return encoded

func _on_DiscordOpen_pressed() -> void:
	var discord_url = "https://discord.gg/hX9JeZD7Rx"
	OS.shell_open(discord_url)  # Opens the Discord link in the default web browser
