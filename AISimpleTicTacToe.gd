extends Control

const Cell = preload("res://Scenes/cell.tscn")

@export var tween_intensity: float
@export var tween_duration: float
@export_enum("Human", "AI") var play_with : String = "Human"

# Game variables
var current_player: String = "X"  # Player is always X
var board: Array = []
var cells: Array = []
var ai_difficulty: String = "Hard"
var stats: Dictionary = load_stats()
var is_game_end: bool = false
var focusable_cells: Array = []
var current_focus_index: int = 0

@onready var x_playing_label = $XIsPlaying
@onready var o_playing_label = $OIsPlaying
@onready var home: Button = $HomeButton
@onready var rematch: Button = $SimpleRematchButton34
@onready var aihomepage: Button = $AIHomePageButton
@onready var cells_container = $Cells

func _ready():
	if has_node("CanvasLayer/Control/FPS_COUNTER_AISimpleTicTacToe"):
		$CanvasLayer/Control/FPS_COUNTER_AISimpleTicTacToe.add_to_group("fps_counters")
		$CanvasLayer/Control/FPS_COUNTER_AISimpleTicTacToe.visible = FpsManager.fps_enabled
	
	setup_game()
	reset_game()

	match Global.ai_difficulty:
		"Easy": ai_difficulty = "Easy"
		"Medium": ai_difficulty = "Medium"
		"Hard": ai_difficulty = "Hard"

	var button7_click_player: AudioStreamPlayer = $Button7ClickPlayer
	button7_click_player.stream = load("res://Sounds/click.ogg")
	
func setup_game():
	board = ["", "", "", "", "", "", "", "", ""]
	
	for cell in cells:
		if is_instance_valid(cell):
			cell.queue_free()
	cells.clear()
	focusable_cells.clear()
	
	for i in range(9):
		var cell = Cell.instantiate()
		cell.main = self
		cells_container.add_child(cell)
		cells.append(cell)
		focusable_cells.append(cell)
		cell.cell_updated.connect(_on_cell_updated)

func check_match():
	for h in range(3):
		if cells[0+3*h].cell_value == "X" and cells[1+3*h].cell_value == "X" and cells[2+3*h].cell_value == "X":
			return ["X", 1+3*h, 2+3*h, 3+3*h]
		if cells[0+3*h].cell_value == "O" and cells[1+3*h].cell_value == "O" and cells[2+3*h].cell_value == "O":
			return ["O", 1+3*h, 2+3*h, 3+3*h]
	
	for v in range(3):
		if cells[0+v].cell_value == "X" and cells[3+v].cell_value == "X" and cells[6+v].cell_value == "X":
			return ["X", 1+v, 4+v, 7+v]
		if cells[0+v].cell_value == "O" and cells[3+v].cell_value == "O" and cells[6+v].cell_value == "O":
			return ["O", 1+v, 4+v, 7+v]
	
	if cells[0].cell_value == "X" and cells[4].cell_value == "X" and cells[8].cell_value == "X":
		return ["X", 1, 5, 9]
	if cells[0].cell_value == "O" and cells[4].cell_value == "O" and cells[8].cell_value == "O":
		return ["O", 1, 5, 9]
	if cells[2].cell_value == "X" and cells[4].cell_value == "X" and cells[6].cell_value == "X":
		return ["X", 3, 5, 7]
	if cells[2].cell_value == "O" and cells[4].cell_value == "O" and cells[6].cell_value == "O":
		return ["O", 3, 5, 7]

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
	if index == -1 or board[index] != "":
		return
		
	# Player's move (X)
	make_move(index, "X")
	
	if check_game_end():
		return
	ai_turn()

func check_game_end() -> bool:
	var match_result = check_match()
	if match_result is Array and match_result.size() > 0:
		is_game_end = true
		if match_result[0] != "Draw":
			start_win_animation(match_result)
			show_winner_popup(match_result[0])
		else:
			show_winner_popup("Draw")
		return true
	return false

func set_initial_focus():
	if not focusable_cells.is_empty():
		focusable_cells[0].grab_focus()
		current_focus_index = 0

func _input(_event):
	if is_game_end:
		# Allow button navigation when the game has ended
		if Input.is_action_just_pressed("ui_down"):
			change_focus(0, 1)  # Move focus down
			get_viewport().set_input_as_handled()
		elif Input.is_action_just_pressed("ui_up"):
			change_focus(0, -1)  # Move focus up
			get_viewport().set_input_as_handled()
		elif Input.is_action_just_pressed("ui_accept"):
			if focusable_cells[current_focus_index].has_focus():
				focusable_cells[current_focus_index].emit_signal("pressed")
				get_viewport().set_input_as_handled()
	elif Input.is_action_pressed("ui_cancel"):  # Check for cancel action
		_on_home_pressed()  # Call the back button function
	else:
		# Allow navigation within the Tic Tac Toe board
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
	if not stats.has("Simple_Tic_Tac_Toe_AI_Won"):
		stats["Simple_Tic_Tac_Toe_AI_Won"] = 0
	if not stats.has("Simple_Tic_Tac_Toe_AI_Lost"):
		stats["Simple_Tic_Tac_Toe_AI_Lost"] = 0

	# Update stats based on win/loss and player
	if player == "X":
		if is_win:
			stats["Simple_Tic_Tac_Toe_AI_Won"] += 1
	elif player == "O":
		if is_win:
			stats["Simple_Tic_Tac_Toe_AI_Lost"] += 1

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
	
	$WinnerLabel.hide()
	$HomeButton.hide()
	$SimpleRematchButton34.hide()

# AI turn logic
func ai_turn():
	if is_game_end:
		return

	var move_index: int
	match ai_difficulty:
		"Easy":
			move_index = get_easy_move()
		"Medium":
			move_index = get_medium_move()
		"Hard":
			move_index = get_hard_move()
	
	if move_index != -1:
		make_move(move_index, "O")
		check_game_end()

func get_easy_move() -> int:
	var empty_cells = []
	for i in range(9):
		if board[i] == "":
			empty_cells.append(i)
	return empty_cells[randi() % empty_cells.size()] if !empty_cells.is_empty() else -1

func get_medium_move() -> int:
	# Try to block player win first
	var blocking_move = find_winning_move("X")
	if blocking_move != -1:
		return blocking_move
	return get_easy_move()

func get_hard_move() -> int:
	# Try to win first
	var winning_move = find_winning_move("O")
	if winning_move != -1:
		return winning_move
	
	# Try to block player
	var blocking_move = find_winning_move("X")
	if blocking_move != -1:
		return blocking_move
	
	# Take center if available
	if board[4] == "":
		return 4
		
	return get_easy_move()

func find_winning_move(player: String) -> int:
	for i in range(9):
		if board[i] == "":
			board[i] = player
			if check_match() != null:
				board[i] = ""
				return i
			board[i] = ""
	return -1

func get_ai_move() -> int:
	# Example AI logic: choose a random empty cell
	var empty_cells = []
	for i in range(board.size()):
		if board[i] == "":
			empty_cells.append(i)
	
	if empty_cells.size() > 0:
		return empty_cells[randi() % empty_cells.size()]
	
	return -1  # Return -1 if no valid moves are available


# AI turn for Hard mode
func easy_ai_turn():
	# Pick a random empty cell
	var empty_cells = []
	for i in range(9):
		if board[i] == "":
			empty_cells.append(i)
	if not empty_cells.is_empty():
		var random_index = randi() % empty_cells.size()
		make_move(empty_cells[random_index], "O")

func medium_ai_turn():
	# Attempt to block the player if they are about to win
	if not block_player("X"):  # Try to block "X"
		easy_ai_turn()  # Otherwise, pick randomly

func block_player(player: String) -> bool:
	# Block the opponent if they are about to win
	for i in range(9):
		if board[i] == "":
			board[i] = player
			if check_match() != null:  # Check if this move wins for the opponent
				make_move(i, "O")  # Block the player
				board[i] = ""  # Reset the board slot
				return true
			board[i] = ""  # Reset the board slot
	return false

func hard_ai_turn():
	# Try to win first
	if try_to_win("O"):  # If AI can win, do it
		return
	
	# Block the player if they are about to win
	if block_player("X"):  # Try to block "X"
		return
	
	# If no immediate threats or wins, pick randomly
	easy_ai_turn()

func try_to_win(player: String) -> bool:
	# Attempt to win if there's an opportunity
	for i in range(9):
		if board[i] == "":
			board[i] = player
			if check_match() != null:  # Check if this move wins for the AI
				make_move(i, "O")  # Make the winning move
				board[i] = ""  # Reset the board slot (not needed here but keeps consistency)
				return true
			board[i] = ""  # Reset the board slot
	return false

func make_move(index: int, player: String):
	board[index] = player
	if player == "X":
		cells[index].draw_x()
		x_playing_label.visible = false
		o_playing_label.visible = true
	else:
		cells[index].draw_o()
		x_playing_label.visible = true
		o_playing_label.visible = false

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

# Block player if they are one move away from winning
func block_player_if_winning() -> bool:
	for i in range(board.size()):
		if board[i] == "":
			board[i] = "X"  # Pretend to be the player
			if check_for_win():
				board[i] = "O"  # Block the player
				cells[i].draw_o()  # Use draw_o() instead of setting text
				current_player = "X"  # Switch back to player X
				return true
			board[i] = ""  # Reset the board slot
	return false

# Choose a random available spot for AI's turn
func choose_random_spot():
	var empty_indices = []
	for i in range(board.size()):
		if board[i] == "":
			empty_indices.append(i)
	if empty_indices.size() > 0:
		var random_index = empty_indices[randi() % empty_indices.size()]
		board[random_index] = "O"  # AI makes a move
		cells[random_index].draw_o()  # Use draw_o() instead of setting text
		
		# Check for win condition
		if check_for_win():
			show_winner_popup(current_player)
			return  # End the function here
		
		# Switch back to player X
		current_player = "X"

# Show winner popup (updated to show SimpleRematchButton34)
func show_winner_popup(winner: String):
	if winner == "Draw":
		$WinnerLabel.text = "It's a Draw!"
	else:
		$WinnerLabel.text = winner + " wins!"
	
	if winner == "X":
		update_stats(true, "X")
		update_stats(false, "O")
	elif winner == "O":
		update_stats(false, "X")
		update_stats(true, "O")
	
	$WinnerLabel.show()
	$HomeButton.show()
	$SimpleRematchButton34.show()
	x_playing_label.visible = false
	o_playing_label.visible = false
	
	# Set focus to the rematch button
	$SimpleRematchButton34.grab_focus()

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
func _on_aihomepagebutton_pressed() -> void:
	$Button7ClickPlayer.play()
	await get_tree().create_timer(0.1).timeout
	Transition.load_scene("res://Scenes/UI.tscn")

func _on_simplerematchbutton34_pressed():
	$Button7ClickPlayer.play()
	await get_tree().create_timer(0.1).timeout
	reset_game()

func _on_home_pressed():
	$Button7ClickPlayer.play()
	await get_tree().create_timer(0.1).timeout
	Transition.load_scene("res://Scenes/UI.tscn")

func check_for_tie() -> bool:
	return "" not in board


func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()

func randomize_starting_player():
	# Always start with "X"
	current_player = "X"
	x_playing_label.visible = true
	o_playing_label.visible = false
