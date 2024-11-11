extends Control

const Cell = preload("res://Scenes/cell.tscn")

@export var tween_intensity: float
@export var tween_duration: float

# Game variables
var current_player: String = "X"
var board: Array = []  # Array to store the state of the board
var cells: Array = []  # Store references to the 9 cells
var stats: Dictionary = load_stats()
var is_game_end: bool = false
var focusable_cells: Array = []
var current_focus_index: int = 0

@onready var x_playing_label = $XIsPlaying
@onready var o_playing_label = $OIsPlaying
@onready var home: Button = $NormalBackHome
@onready var rematch: Button = $SimpleRematchButton
@onready var aihomepage: Button = $SimpleHomePage
@onready var cells_container = $Cells

func _ready():
	if has_node("CanvasLayer/Control/FPS_COUNTER_simple_tic_tac_toe"):
		$CanvasLayer/Control/FPS_COUNTER_simple_tic_tac_toe.add_to_group("fps_counters")
		$CanvasLayer/Control/FPS_COUNTER_simple_tic_tac_toe.visible = FpsManager.fps_enabled
	
	setup_game()
	reset_game()
	
	var button6_click_player: AudioStreamPlayer = $Button6ClickPlayer
	button6_click_player.stream = load("res://Sounds/click.ogg")
	
func setup_game():
	# Initialize board array
	board = ["", "", "", "", "", "", "", "", ""]
	
	# Clear any existing cells
	for cell in cells:
		if is_instance_valid(cell):
			cell.queue_free()
	cells.clear()
	focusable_cells.clear()
	
	# Create new cells
	for i in range(9):
		var cell = Cell.instantiate()
		cell.main = self
		cells_container.add_child(cell)
		cells.append(cell)
		focusable_cells.append(cell)
		cell.cell_updated.connect(_on_cell_updated)

func check_match():
	# Check rows
	for h in range(3):
		if cells[0+3*h].cell_value == "X" and cells[1+3*h].cell_value == "X" and cells[2+3*h].cell_value == "X":
			return ["X", 1+3*h, 2+3*h, 3+3*h]
		if cells[0+3*h].cell_value == "O" and cells[1+3*h].cell_value == "O" and cells[2+3*h].cell_value == "O":
			return ["O", 1+3*h, 2+3*h, 3+3*h]
	
	# Check columns
	for v in range(3):
		if cells[0+v].cell_value == "X" and cells[3+v].cell_value == "X" and cells[6+v].cell_value == "X":
			return ["X", 1+v, 4+v, 7+v]
		if cells[0+v].cell_value == "O" and cells[3+v].cell_value == "O" and cells[6+v].cell_value == "O":
			return ["O", 1+v, 4+v, 7+v]
	
	# Check diagonals
	if cells[0].cell_value == "X" and cells[4].cell_value == "X" and cells[8].cell_value == "X":
		return ["X", 1, 5, 9]
	if cells[0].cell_value == "O" and cells[4].cell_value == "O" and cells[8].cell_value == "O":
		return ["O", 1, 5, 9]
	if cells[2].cell_value == "X" and cells[4].cell_value == "X" and cells[6].cell_value == "X":
		return ["X", 3, 5, 7]
	if cells[2].cell_value == "O" and cells[4].cell_value == "O" and cells[6].cell_value == "O":
		return ["O", 3, 5, 7]
	
	# Check for draw
	var full = true
	for cell in cells:
		if cell.cell_value == "":
			full = false
			break
	
	if full:
		return ["Draw", 0, 0, 0]
	
	return null

func start_win_animation(match_result: Array):
	var color = Color.BLUE if match_result[0] == "X" else Color.RED
	for c in range(3):
		cells[match_result[c+1]-1].glow(color)

func _on_cell_updated(cell: Button):
	if is_game_end:
		return
	
	var index = cells.find(cell)
	if index != -1:
		board[index] = cell.cell_value
		
		var match_result = check_match()
		if match_result is Array and match_result.size() > 0:
			is_game_end = true
			if match_result[0] != "Draw":
				start_win_animation(match_result)
				show_winner_popup(match_result[0])
			else:
				show_winner_popup("Draw")
			return
		
		# Switch players
		current_player = "O" if current_player == "X" else "X"
		update_playing_labels()

func update_playing_labels():
	x_playing_label.visible = (current_player == "X")
	o_playing_label.visible = (current_player == "O")

func set_initial_focus():
	if not focusable_cells.is_empty():
		focusable_cells[0].grab_focus()
		current_focus_index = 0

func _input(_event):
	if Input.is_action_just_pressed("ui_right"):
		change_focus(1, 0)
		get_viewport().set_input_as_handled()
	elif Input.is_action_just_pressed("ui_left"):
		change_focus(-1, 0)
		get_viewport().set_input_as_handled()
	elif Input.is_action_just_pressed("ui_down"):
		change_focus(0, 1)
		get_viewport().set_input_as_handled()
	elif Input.is_action_just_pressed("ui_up"):
		change_focus(0, -1)
		get_viewport().set_input_as_handled()
	elif Input.is_action_just_pressed("ui_accept"):
		if focusable_cells[current_focus_index].has_focus():
			focusable_cells[current_focus_index].emit_signal("pressed")
			get_viewport().set_input_as_handled()
	elif Input.is_action_pressed("ui_cancel"):
		_on_normalbackhome_pressed()

func change_focus(dx: int, dy: int):
	var grid_size = 3  # 3x3 grid
	var position_in_grid = current_focus_index % (grid_size * grid_size)
	@warning_ignore("integer_division")
	var row = position_in_grid / grid_size
	var col = position_in_grid % grid_size
	
	row += dy
	col += dx
	
	if row < 0:
		row = 2
	elif row > 2:
		row = 0
	
	if col < 0:
		col = 2
	elif col > 2:
		col = 0
	
	var new_index = (row * grid_size) + col
	
	if new_index >= cells.size():
		new_index = clamp(new_index, 0, focusable_cells.size() - 1)
	
	if new_index != current_focus_index:
		current_focus_index = new_index
		focusable_cells[current_focus_index].grab_focus()

func _process(_delta: float):
	button_hovered(rematch)
	button_hovered(home)
	button_hovered(aihomepage)

	
func start_tween(object: Object, property: String, final_val: Variant, duration: float):
	var tween = create_tween()
	tween.tween_property(object, property, final_val, duration)

func button_hovered(button: Button):
	button.pivot_offset = button.size / 2
	if button.is_hovered():
		start_tween(button, "scale", Vector2.ONE * tween_intensity, tween_duration)
	else: 
		start_tween(button, "scale", Vector2.ONE, tween_duration)
func _connect_button(button: Button, handler: String):
	if button and !button.is_connected("pressed", Callable(self, handler)):
		button.connect("pressed", Callable(self, handler))
	else:
		print(button.name + " not found or already connected.")

func load_stats() -> Dictionary:
	var file_path = "user://Stats.cfg"
	if not FileAccess.file_exists(file_path):
		print("Stats file does not exist. Initializing with default values.")
		return {
			"Ultimate_Tic_Tac_Toe_Yourself_Won": 0,
			"Ultimate_Tic_Tac_Toe_Yourself_Lost": 0,
			"Ultimate_Tic_Tac_Toe_AI_Won": 0,
			"Ultimate_Tic_Tac_Toe_AI_Lost": 0,
			"Simple_Tic_Tac_Toe_AI_Won": 0,
			"Simple_Tic_Tac_Toe_Yourself_Won": 0,
			"Simple_Tic_Tac_Toe_AI_Lost": 0,
			"Simple_Tic_Tac_Toe_Yourself_Lost": 0
		}

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var local_stats = {}  # Renamed the local variable
		while not file.eof_reached():
			var line = file.get_line().strip_edges()
			var parts = line.split("=")
			if parts.size() == 2:
				local_stats[parts[0]] = int(parts[1])  # Convert the value to an int
		file.close()
		return local_stats  # Return the renamed variable
	else:
		print("Failed to open file for reading.")
		return {}

func update_stats(is_win: bool, player: String):
	print("Updating stats - is_win:", is_win, "player:", player)  # Debugging output
	# Ensure the necessary keys are present in the stats dictionary
	if not stats.has("Simple_Tic_Tac_Toe_Yourself_Won"):
		stats["Simple_Tic_Tac_Toe_Yourself_Won"] = 0
	if not stats.has("Simple_Tic_Tac_Toe_Yourself_Lost"):
		stats["Simple_Tic_Tac_Toe_Yourself_Lost"] = 0

	# Update stats based on win/loss and player
	if player == "X":
		if is_win:
			stats["Simple_Tic_Tac_Toe_Yourself_Won"] += 1
	elif player == "O":
		if is_win:
			stats["Simple_Tic_Tac_Toe_Yourself_Lost"] += 1

	save_stats(stats)

func reset_game():
	is_game_end = false
	board = ["", "", "", "", "", "", "", "", ""]
	randomize_starting_player()

	for cell in cells:
		cell.cell_value = ""
		cell.text = ""
		cell.self_modulate = Color.WHITE
		cell.disabled = false
	
	$SimpleWinnerLabel.hide()
	$SimpleHomePage.hide()
	$SimpleRematchButton.hide()
	update_playing_labels()

func make_move(index: int, player: String):
	# Make a move on the board and update the UI
	board[index] = player
	cells[index].cell_value = player
	cells[index].text = player
	cells[index].disabled = true
	
	# Ensure "O" is visible
	if player == "O":
		cells[index].self_modulate = Color(1, 0, 0)  # Set color for "O"
	else:
		cells[index].self_modulate = Color(0, 0, 1)  # Set color for "X"

func complete_turn():
	# Check for win/tie after each turn
	var match_result = check_match()

	if match_result is Array:  # First, check if match_result is a valid array
		is_game_end = true
		if match_result.size() >= 1:  # Ensure the array has at least one element
			var result_type = match_result[0]  # Safely access the first element
			if result_type != "Draw":
				start_win_animation(match_result)
				show_winner_popup(result_type)
			else:
				show_winner_popup("Draw")
		disable_all_buttons()

func show_winner_popup(winner: String):
	if winner == "Draw":
		$SimpleWinnerLabel.text = "It's a Draw!"
	else:
		$SimpleWinnerLabel.text = winner + " wins!"
		
		# Update stats based on the winner
		if winner == "X":
			update_stats(true, "X")
			update_stats(false, "O")
		else:  # winner == "O"
			update_stats(false, "X")
			update_stats(true, "O")
	
	$SimpleWinnerLabel.show()
	$SimpleHomePage.show()
	$SimpleRematchButton.show()
	x_playing_label.visible = false
	o_playing_label.visible = false

	# Set focus to the appropriate button based on the winner
	if winner == "X":
		$SimpleRematchButton.grab_focus()  # Focus on rematch button
	else:
		$SimpleHomePage.grab_focus()  # Focus on home button

func save_stats(new_stats: Dictionary) -> void:
	var file_path = "user://Stats.cfg"
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		for key in new_stats.keys():
			var line = key + "=" + str(new_stats[key])  # Create the line for each key-value pair
			file.store_line(line)  # Store the line in the file
		file.close()
	else:
		print("Failed to open file for writing.")

# Disables all buttons after the game ends
func disable_all_buttons():
	for cell in cells:
		cell.disabled = true

# Checks for win conditions
func check_for_win() -> bool:
	var win_conditions = [
		[0, 1, 2], [3, 4, 5], [6, 7, 8],  # Rows
		[0, 3, 6], [1, 4, 7], [2, 5, 8],  # Columns
		[0, 4, 8], [2, 4, 6]  # Diagonals
	]
	
	for condition in win_conditions:
		if board[condition[0]] == current_player and board[condition[1]] == current_player and board[condition[2]] == current_player:
			return true
	return false


# Called when the AI Home Page button is pressed, directs to UI.tscn
# Called when the SimpleHomePage button is pressed, directs to UI.tscn
func _on_simplehomepage_pressed() -> void:
	$Button6ClickPlayer.play()  # Play the button click sound
	await get_tree().create_timer(0.1).timeout  # Wait for a short duration
	Transition.load_scene("res://Scenes/UI.tscn")

# Called when the NormalBackHome button is pressed, directs to UI.tscn
func _on_normalbackhome_pressed() -> void:
	$Button6ClickPlayer.play()  # Play the button click sound
	await get_tree().create_timer(0.1).timeout  # Wait for a short duration
	Transition.load_scene("res://Scenes/UI.tscn")
	# get_tree().change_scene_to_file("UI.tscn")  # Change scene

# Function for the rematch button
func _on_simplerematchbutton_pressed() -> void:
	$Button6ClickPlayer.play()  # Play the button click sound
	await get_tree().create_timer(0.1).timeout  # Wait for a short duration
	reset_game()  # Reset the game state
	$SimpleRematchButton.hide()  # Hide the rematch button after pressing it

func check_for_tie() -> bool:
	return "" not in board

func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()

func randomize_starting_player():
	current_player = "X" if randf() < 0.5 else "O"
	update_playing_labels()
