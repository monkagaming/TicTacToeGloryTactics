extends Control

@export var tween_intensity: float
@export var tween_duration: float

var current_player = "X"  # Player is "X", AI is "O"
var cells = []  # Store references to buttons
var is_ai_turn = false  # Track if it's AI's turn
var small_board_wins = []  # Track wins for small boards
var overall_winner = ""  # Track overall winner
var x_win_labels = [] # Declare labels for each column
var o_win_labels = [] # Declare labels for each column
var tie_labels = []  # Array to hold tie labels for each column
var stats: Dictionary = load_stats()  # Load or initialize stats at the start
var active_column = -1  # Initialize with -1 to allow any board on the first move
var ai_difficulty = "Hard"  # Can be "Easy", "Medium", or "Hard"
var player_goes_first: bool = true
var x_first_count = 0
var o_first_count = 0
var focusable_buttons: Array = []
var current_focus_index: int = 0

@onready var winner_label = $WinnerLabel  # General winner label
@onready var ai_home_button = $AIHomeButton  # Reference to the AIHomeButton
@onready var ai_rematch_button = $AIRematchUltimateButton  # Reference to the rematch button
@onready var stating_labels = [
	$Stating1, $Stating2, $Stating3, $Stating4, $Stating5, $Stating6, $Stating7, $Stating8, $Stating9
]
@onready var rematch: Button = $AIRematchUltimateButton
@onready var homepage: Button = $Miniboardhomepage
@onready var aihome: Button = $AIHomeButton

func _ready():
	if has_node("CanvasLayer/Control/FPS_COUNTER_AIminiboard"):
		$CanvasLayer/Control/FPS_COUNTER_AIminiboard.add_to_group("fps_counters")
		$CanvasLayer/Control/FPS_COUNTER_AIminiboard.visible = FpsManager.fps_enabled
	
	for label in stating_labels:
		label.visible = false
	
	cells.clear()
	small_board_wins = [null, null, null, null, null, null, null, null, null]  # Initialize small board wins
	winner_label.visible = false
	ai_home_button.visible = false  # Hide the AIHomeButton initially
	ai_rematch_button.visible = false  # Hide rematch button initially

	# Initialize labels for each column
	for i in range(1, 10):
		x_win_labels.append(get_node("XWinLabelColumn" + str(i)))
		o_win_labels.append(get_node("OWinLabelColumn" + str(i)))
		tie_labels.append(get_node("ItsATieLabelColumn" + str(i)))
		x_win_labels[i - 1].visible = false
		o_win_labels[i - 1].visible = false
		tie_labels[i - 1].visible = false
	
	# Initialize cells for columns and connect all buttons
	for column_index in range(1, 10):  # Columns 1 to 9
		var grid_container: GridContainer = get_node("GridContainerColumn" + str(column_index))
		for cell_index in range(9):  # Cells 1 to 9 in each column
			var cell: Button = grid_container.get_child(cell_index)
			cells.append(cell)
			cell.connect("pressed", Callable(self, "_on_AICell_pressed").bind(column_index - 1, cell_index))
			focusable_buttons.append(cell)  # Add each cell to focusable buttons

	# Add specific buttons to focusable buttons
	focusable_buttons.append_array([ai_rematch_button, homepage, ai_home_button])

	for button in focusable_buttons:
		button.focus_mode = Control.FOCUS_ALL

	# Set initial focus
	set_initial_focus()

	# Determine who goes first
	player_goes_first = randf() < 0.5
	current_player = "X" if player_goes_first else "O"
	
	# Update UI to show who's playing
	$XIsPlaying.visible = player_goes_first
	$OIsPlaying.visible = !player_goes_first
	
	# If AI goes first, trigger its turn
	if !player_goes_first:
		call_deferred("ai_turn")

	var button10_click_player: AudioStreamPlayer = $Button10ClickPlayer
	button10_click_player.stream = load("res://Sounds/click.ogg")

	# Connect input events
	set_process_input(true)

func set_initial_focus():
	if not focusable_buttons.is_empty():
		focusable_buttons[0].grab_focus()
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
		if focusable_buttons[current_focus_index].has_focus():
			focusable_buttons[current_focus_index].emit_signal("pressed")
			get_viewport().set_input_as_handled()  # Prevent double input
			
	elif Input.is_action_pressed("ui_cancel"):  # Check for cancel action
		_on_miniboardhomepage_pressed() # Call the back button function

func change_focus(dx: int, dy: int):
	var grid_size = 3  # 3x3 grid for each small board
	@warning_ignore("integer_division")
	var current_grid = int(current_focus_index / (grid_size * grid_size))
	var position_in_grid = current_focus_index % (grid_size * grid_size)
	@warning_ignore("integer_division")
	var row = int(position_in_grid / grid_size)
	var col = position_in_grid % grid_size
	
	row += dy
	col += dx
	
	if row < 0:
		if current_grid >= 3:
			current_grid -= 3
			row = 2
		else:
			row = 0
	elif row > 2:
		if current_grid < 6:
			current_grid += 3
			row = 0
		else:
			row = 2
	
	if col < 0:
		if current_grid % 3 > 0:
			current_grid -= 1
			col = 2
		else:
			col = 0
	elif col > 2:
		if current_grid % 3 < 2:
			current_grid += 1
			col = 0
		else:
			col = 2
	
	var new_index = (current_grid * grid_size * grid_size) + (row * grid_size) + col
	new_index = clamp(new_index, 0, focusable_buttons.size() - 1)
	
	if new_index != current_focus_index:
		current_focus_index = new_index
		focusable_buttons[current_focus_index].grab_focus()

func update_stating_labels() -> void:
	for i in range(stating_labels.size()):
		stating_labels[i].visible = (i == active_column and is_column_playable(i))
	
	if active_column != -1 and is_column_playable(active_column):
		# Move focus to the first empty cell in the active column
		var grid_container: GridContainer = get_node("GridContainerColumn" + str(active_column + 1))
		for i in range(9):
			var cell: Button = grid_container.get_child(i)
			if cell.text == "":
				cell.grab_focus()
				current_focus_index = focusable_buttons.find(cell)
				break
	else:
		# If the active column is full or not playable, find the next available column
		active_column = find_next_unwon_column()
		if active_column != -1:
			update_stating_labels()  # Recursively update labels and focus

func _process(_delta: float) -> void:
	for button in focusable_buttons:
		button_hovered(button)

func start_tween(object: Object, property: String, final_val: Variant, duration: float):
	var tween = create_tween()
	tween.tween_property(object, property, final_val, duration)

func button_hovered(button: Button):
	button.pivot_offset = button.size / 2
	if button.is_hovered() or button.has_focus():
		start_tween(button, "scale", Vector2.ONE * tween_intensity, tween_duration)
	else: 
		start_tween(button, "scale", Vector2.ONE, tween_duration)

func _connect_button(button: Button, handler: String):
	if button and !button.is_connected("pressed", Callable(self, handler)):
		button.connect("pressed", Callable(self, handler))
	else:
		print(button.name + " not found or already connected.")
	
# Function to save stats
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
			"Simple_Tic_Tac_Toe_Won": 0,
			"Simple_Tic_Tac_Toe_AI_Lost": 0,
			"Simple_Tic_Tac_Toe_Lost": 0
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
	if not stats.has("Ultimate_Tic_Tac_Toe_AI_Won"):
		stats["Ultimate_Tic_Tac_Toe_AI_Won"] = 0
	if not stats.has("Ultimate_Tic_Tac_Toe_AI_Lost"):
		stats["Ultimate_Tic_Tac_Toe_AI_Lost"] = 0

	# Update stats based on win/loss and player
	if player == "X":
		if is_win:
			stats["Ultimate_Tic_Tac_Toe_AI_Won"] += 1
	elif player == "O":
		if is_win:
			stats["Ultimate_Tic_Tac_Toe_AI_Lost"] += 1

	save_stats(stats)
	
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

#handler for cells 1-81
func _on_AICell_pressed(column_index: int, cell_index: int) -> void:
	if current_player != "X" or overall_winner != "" or (active_column != -1 and column_index != active_column) or not is_column_playable(column_index):
		print("Invalid move attempt")
		return

	var cell: Button = get_node("GridContainerColumn" + str(column_index + 1)).get_child(cell_index)

	if cell.text == "":
		make_move(cell, column_index, cell_index)

func make_move(cell: Button, column_index: int, _cell_index: int):
	cell.text = current_player
	print("Player X moved")
	stating_labels[column_index].visible = false

	# Update active_column to the column the player just moved in
	active_column = column_index

	if check_winner(column_index, current_player):
		small_board_wins[column_index] = current_player
		update_column_win_label(column_index)
		lock_column(column_index)
		if check_overall_winner():
			display_winner(current_player)
			lock_game()
			return

	if is_column_full(column_index):
		tie_labels[column_index].visible = true
		lock_column(column_index)

	# Switch to AI's turn
	current_player = "O"
	is_ai_turn = true
	$XIsPlaying.visible = false
	$OIsPlaying.visible = true
	
	print("Triggering AI turn")
	call_deferred("trigger_ai_turn")

func trigger_ai_turn():
	print("AI turn started")
	var ai_column = await ai_turn()
	print("AI turn completed, played in column: ", ai_column + 1)
	
	# Recheck valid columns after AI's turn
	active_column = find_next_unwon_column()
	update_stating_labels()

	# If the AI won the game, we don't need to continue
	if overall_winner != "":
		return

	# If the AI played in the same column as the player, we need to find a new active column
	if ai_column == -1 or not is_column_playable(ai_column):
		active_column = find_next_unwon_column()
		update_stating_labels()

	# Switch back to player's turn
	current_player = "X"
	is_ai_turn = false
	$XIsPlaying.visible = true
	$OIsPlaying.visible = false

func find_next_unwon_column() -> int:
	var columns = [0, 1, 2, 3, 4, 5, 6, 7, 8]
	columns.shuffle()

	for i in columns:
		if is_column_playable(i):
			return i
	return -1

func is_column_full(column_index: int) -> bool:
	var grid_container: GridContainer = get_node("GridContainerColumn" + str(column_index + 1))
	for i in range(9):
		var cell: Button = grid_container.get_child(i)
		if cell.text == "":
			return false  # Return false if any cell is empty
	return true  # Return true if all cells are filled

func update_column_win_label(column_index: int) -> void:
	# Show the appropriate win label for the column
	if small_board_wins[column_index] == "X":
		x_win_labels[column_index].visible = true
	elif small_board_wins[column_index] == "O":
		o_win_labels[column_index].visible = true

func lock_column(column_index: int) -> void:
	# Ensure the column index is valid (0-8 for 1-9 in the UI)
	if column_index < 0 or column_index >= 9:
		return
	var grid_container: GridContainer = get_node("GridContainerColumn" + str(column_index + 1))
	for i in range(9):
		var cell: Button = grid_container.get_child(i)
		cell.disabled = true  # Lock the buttons in this column

func lock_game() -> void:
	for column_index in range(9):  # Only loop through valid column indices (0-8)
		lock_column(column_index)  # Lock all columns

func ai_turn() -> int:
	print("AI turn function called")
	if current_player != "O" or overall_winner != "":
		print("AI turn aborted: not O's turn or game over")
		return -1
	
	await get_tree().create_timer(0.35).timeout  # Delay for AI's move

	var column_to_play = find_valid_column_for_ai()
	print("AI choosing column: ", column_to_play + 1)

	if column_to_play == -1:
		print("No valid moves available. Game might be over.")
		check_for_overall_tie()
		return -1

	var move_made = false
	match ai_difficulty:
		"Easy":
			move_made = play_easy_move(column_to_play)
		"Medium":
			move_made = play_medium_move(column_to_play)
		"Hard":
			move_made = play_hard_move(column_to_play)

	if !move_made:
		print("AI failed to make a move")
		return -1

	print("AI played in column: ", column_to_play + 1)

	# Check if AI wins the small board
	if check_winner(column_to_play, "O"):
		small_board_wins[column_to_play] = "O"
		update_column_win_label(column_to_play)
		lock_column(column_to_play)
		if check_overall_winner():
			display_winner("O")
			lock_game()
			return column_to_play

	# Switch turn to player
	current_player = "X"
	is_ai_turn = false
	$XIsPlaying.visible = true
	$OIsPlaying.visible = false

	# Update active column for the player's next move
	active_column = find_next_unwon_column()
	update_stating_labels()
	
	return column_to_play

func play_easy_move(column_index: int) -> bool:
	return play_random_move(column_index)

func play_medium_move(column_index: int) -> bool:
	if can_win(column_index, "O"):
		return take_winning_move(column_index)
	elif block_player(column_index):
		return true
	else:
		return play_random_move(column_index)

func play_hard_move(column_index: int) -> bool:
	if can_win(column_index, "O"):
		return take_winning_move(column_index)
	elif block_player(column_index):
		return true
	elif can_create_fork(column_index, "O"):
		return create_fork(column_index, "O")
	elif can_block_fork(column_index):
		return create_fork(column_index, "O")  # Block fork by creating our own fork
	elif can_play_center(column_index):
		return play_center(column_index)
	elif can_play_opposite_corner(column_index):
		return play_opposite_corner(column_index)
	elif can_play_empty_corner(column_index):
		return play_empty_corner(column_index)
	elif can_play_empty_side(column_index):
		return play_empty_side(column_index)
	else:
		return play_random_move(column_index)

func take_winning_move(column_index: int) -> bool:
	var grid_container: GridContainer = get_node("GridContainerColumn" + str(column_index + 1))
	for i in range(9):
		var cell: Button = grid_container.get_child(i)
		if cell.text == "":
			cell.text = "O"  # AI makes the winning move
			return true
	return false

func block_player(column_index: int) -> bool:
	var grid_container: GridContainer = get_node("GridContainerColumn" + str(column_index + 1))
	for i in range(9):
		var cell: Button = grid_container.get_child(i)
		if cell.text == "":
			if can_win(column_index, "X"):  # Check if player can win
				cell.text = "O"  # Block the player
				return true  # Block successful
	return false  # No blocking move necessary

func play_random_move(column_index: int) -> bool:
	var grid_container: GridContainer = get_node("GridContainerColumn" + str(column_index + 1))
	var empty_cells = []
	for i in range(9):
		var cell: Button = grid_container.get_child(i)
		if cell.text == "":
			empty_cells.append(cell)  # Add empty cells to the list
	if empty_cells.size() > 0:
		var random_cell: Button = empty_cells[randi() % empty_cells.size()]
		random_cell.text = "O"  # AI plays randomly
		return true
	return false

func check_for_overall_tie() -> void:
	for i in range(9):
		if is_column_playable(i):
			return  # If any column is playable, the game is not a tie
	
	# If we've reached here, no columns are playable
	display_winner("Tie")
	lock_game()

# Function to switch turns
func switch_turn():
	current_player = "O" if current_player == "X" else "X"
	$XIsPlaying.visible = (current_player == "X")
	$OIsPlaying.visible = (current_player == "O")

# Call this function each time a turn is completed
func _on_turn_completed():
	switch_turn()

func check_winner(column_index: int, player: String) -> bool:
	var grid_container: GridContainer = get_node("GridContainerColumn" + str(column_index + 1))
	print("Checking winner for player: ", player)
	
	# Check rows
	for i in range(3):
		if grid_container.get_child(i * 3).text == player and \
		   grid_container.get_child(i * 3 + 1).text == player and \
		   grid_container.get_child(i * 3 + 2).text == player:
			return true
	
	# Check columns
	for i in range(3):
		if grid_container.get_child(i).text == player and \
		   grid_container.get_child(i + 3).text == player and \
		   grid_container.get_child(i + 6).text == player:
			return true
	
	# Check diagonals
	if (grid_container.get_child(0).text == player and \
		grid_container.get_child(4).text == player and \
		grid_container.get_child(8).text == player) or \
	   (grid_container.get_child(2).text == player and \
		grid_container.get_child(4).text == player and \
		grid_container.get_child(6).text == player):
		return true
	
	return false

func check_overall_winner() -> bool:
	for player in ["X", "O"]:
		# Check rows
		for i in range(3):
			if small_board_wins[i * 3] == player and \
			   small_board_wins[i * 3 + 1] == player and \
			   small_board_wins[i * 3 + 2] == player:
				return true
		
		# Check columns
		for i in range(3):
			if small_board_wins[i] == player and \
			   small_board_wins[i + 3] == player and \
			   small_board_wins[i + 6] == player:
				return true
		
		# Check diagonals
		if (small_board_wins[0] == player and \
			small_board_wins[4] == player and \
			small_board_wins[8] == player) or \
		   (small_board_wins[2] == player and \
			small_board_wins[4] == player and \
			small_board_wins[6] == player):
			return true
	
	return false

func display_winner(player: String) -> void:
	if player == "Tie":
		winner_label.text = "It's a Tie!"
	else:
		# Update stats for the winner and loser
		if player == "X":
			update_stats(true, "X")  # Player wins
			update_stats(false, "O")  # AI loses
		else:
			update_stats(false, "X")  # Player loses
			update_stats(true, "O")  # AI wins
		
		# Show the appropriate win label for the overall winner
		for i in range(9):
			if small_board_wins[i] == player:
				if player == "X":
					x_win_labels[i].visible = true
				else:
					o_win_labels[i].visible = true
		
		winner_label.text = player + " wins!"

	print(winner_label.text)  # Outputs the result to the console
	
	winner_label.visible = true
	ai_home_button.visible = true  # Show the AIHomeButton when a player wins
	ai_rematch_button.visible = true  # Make the rematch button visible
	
	# Move focus to the appropriate button based on the winner
	if player == "X":
		ai_rematch_button.grab_focus()  # Focus on rematch button for X
	else:
		ai_home_button.grab_focus()  # Focus on home button for O
	
	reset_game_state()

func reset_game_state() -> void:
	current_player = "X"  # Reset current player
	small_board_wins = [null, null, null, null, null, null, null, null, null]  # Reset small board wins
	overall_winner = ""  # Reset overall winner

# AI Strategies
func can_win(column_index: int, player: String) -> bool:
	var grid_container: GridContainer = get_node("GridContainerColumn" + str(column_index + 1))
	for i in range(9):
		var cell: Button = grid_container.get_child(i)
		if cell.text == "":
			cell.text = player  # Try to make a move for the current player
			if check_winner(column_index, player):  # Pass the player as an argument
				cell.text = ""  # Reset move
				return true  # Winning move found
			cell.text = ""  # Reset move
	return false  # No winning move found

func reset_game() -> void:
	# Reset game state
	small_board_wins = [null, null, null, null, null, null, null, null, null]
	overall_winner = ""
	
	# Randomly decide who goes first
	player_goes_first = randf() < 0.5
	current_player = "X" if player_goes_first else "O"
	
	# Update UI accordingly
	$XIsPlaying.visible = player_goes_first
	$OIsPlaying.visible = !player_goes_first
	
	# Clear all cell texts and other resets
	for column_index in range(1, 10):
		var grid_container: GridContainer = get_node("GridContainerColumn" + str(column_index))
		for cell_index in range(9):
			var cell: Button = grid_container.get_child(cell_index)
			cell.text = ""  # Clear the cell text
			cell.disabled = false  # Enable the button again
	
	winner_label.visible = false
	ai_home_button.visible = false
	ai_rematch_button.visible = false
	
	# Hide all win labels and tie labels
	for label in x_win_labels:
		label.visible = false
	for label in o_win_labels:
		label.visible = false
	for label in tie_labels:
		label.visible = false
	
	# If AI goes first, trigger its turn
	if current_player == "O":
		call_deferred("ai_turn")
	
func _on_aihomebutton_pressed() -> void:
	$Button10ClickPlayer.play()  # Play the button click sound
	await get_tree().create_timer(0.1).timeout  # Wait for a short duration
	print("AI Home button clicked")  # Log button click to the console
	Transition.load_scene("res://Scenes/UI.tscn")

func _on_miniboardhomepage_pressed() -> void:
	$Button10ClickPlayer.play()  # Play the button click sound
	await get_tree().create_timer(0.1).timeout  # Wait for a short duration
	print("Mini Board Home button clicked")  # Log button click to the console
	Transition.load_scene("res://Scenes/UI.tscn")

func _on_airematchultimatebutton_pressed() -> void:
	$Button10ClickPlayer.play()  # Play the button click sound
	await get_tree().create_timer(0.1).timeout  # Wait for a short duration
	print("AI Rematch Ultimate button clicked")  # Log button click to the console
	reset_game()  # Call your reset function
	ai_rematch_button.visible = false  # Hide the rematch button after it's clicked

func can_create_fork(column_index: int, player: String) -> bool:
	var grid_container: GridContainer = get_node("GridContainerColumn" + str(column_index + 1))
	var fork_opportunities = 0
	for i in range(9):
		if grid_container.get_child(i).text == "":
			grid_container.get_child(i).text = player
			if count_winning_lines(column_index, player) >= 2:
				fork_opportunities += 1
			grid_container.get_child(i).text = ""
	return fork_opportunities >= 2

func create_fork(column_index: int, player: String) -> bool:
	var grid_container: GridContainer = get_node("GridContainerColumn" + str(column_index + 1))
	for i in range(9):
		if grid_container.get_child(i).text == "":
			grid_container.get_child(i).text = player
			if count_winning_lines(column_index, player) >= 2:
				return true
			grid_container.get_child(i).text = ""
	return false

func can_block_fork(column_index: int) -> bool:
	return can_create_fork(column_index, "X")

func block_fork(column_index: int) -> bool:
	return create_fork(column_index, "O")

func can_play_center(column_index: int) -> bool:
	var grid_container: GridContainer = get_node("GridContainerColumn" + str(column_index + 1))
	return grid_container.get_child(4).text == ""

func play_center(column_index: int) -> bool:
	var grid_container: GridContainer = get_node("GridContainerColumn" + str(column_index + 1))
	if grid_container.get_child(4).text == "":
		grid_container.get_child(4).text = "O"
		return true
	return false

func can_play_opposite_corner(column_index: int) -> bool:
	var grid_container: GridContainer = get_node("GridContainerColumn" + str(column_index + 1))
	var corners = [0, 2, 6, 8]
	for i in corners:
		if grid_container.get_child(i).text == "X" and grid_container.get_child(8 - i).text == "":
			return true
	return false

func play_opposite_corner(column_index: int) -> bool:
	var grid_container: GridContainer = get_node("GridContainerColumn" + str(column_index + 1))
	var corners = [0, 2, 6, 8]
	for i in corners:
		if grid_container.get_child(i).text == "X" and grid_container.get_child(8 - i).text == "":
			grid_container.get_child(8 - i).text = "O"
			return true
	return false

func can_play_empty_corner(column_index: int) -> bool:
	var grid_container: GridContainer = get_node("GridContainerColumn" + str(column_index + 1))
	var corners = [0, 2, 6, 8]
	for i in corners:
		if grid_container.get_child(i).text == "":
			return true
	return false

func play_empty_corner(column_index: int) -> bool:
	var grid_container: GridContainer = get_node("GridContainerColumn" + str(column_index + 1))
	var corners = [0, 2, 6, 8]
	for i in corners:
		if grid_container.get_child(i).text == "":
			grid_container.get_child(i).text = "O"
			return true
	return false

func can_play_empty_side(column_index: int) -> bool:
	var grid_container: GridContainer = get_node("GridContainerColumn" + str(column_index + 1))
	var sides = [1, 3, 5, 7]
	for i in sides:
		if grid_container.get_child(i).text == "":
			return true
	return false

func play_empty_side(column_index: int) -> bool:
	var grid_container: GridContainer = get_node("GridContainerColumn" + str(column_index + 1))
	var sides = [1, 3, 5, 7]
	for i in sides:
		if grid_container.get_child(i).text == "":
			grid_container.get_child(i).text = "O"
			return true
	return false

func count_winning_lines(column_index: int, player: String) -> int:
	var count = 0
	var grid_container: GridContainer = get_node("GridContainerColumn" + str(column_index + 1))
	var lines = [
		[0, 1, 2], [3, 4, 5], [6, 7, 8],  # Rows
		[0, 3, 6], [1, 4, 7], [2, 5, 8],  # Columns
		[0, 4, 8], [2, 4, 6]  # Diagonals
	]
	for line in lines:
		var player_count = 0
		var empty_count = 0
		for i in line:
			if grid_container.get_child(i).text == player:
				player_count += 1
			elif grid_container.get_child(i).text == "":
				empty_count += 1
		if player_count == 2 and empty_count == 1:
			count += 1
	return count

func is_column_playable(column_index: int) -> bool:
	if small_board_wins[column_index] != null:
		return false  # Column has been won by a player
	
	var grid_container: GridContainer = get_node("GridContainerColumn" + str(column_index + 1))
	for i in range(9):
		if grid_container.get_child(i).text == "":
			return true  # Found an empty cell, column is playable
	
	return false  # All cells are filled, column is not playable

func find_valid_column_for_ai() -> int:
	var valid_columns = []
	var weights = []
	var total_weight = 0

	for i in range(9):
		if is_column_playable(i):
			valid_columns.append(i)
			# Give higher weight to columns different from the last player move
			var weight = 3 if i != active_column else 1
			weights.append(weight)
			total_weight += weight

	if valid_columns.size() > 0:
		var random_value = randf() * total_weight
		var cumulative_weight = 0
		for i in range(valid_columns.size()):
			cumulative_weight += weights[i]
			if random_value <= cumulative_weight:
				return valid_columns[i]
		
		# Fallback to last valid column if something goes wrong
		return valid_columns[valid_columns.size() - 1]
	else:
		return -1  # No valid columns available
