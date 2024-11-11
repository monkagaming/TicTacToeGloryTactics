extends Control

@export var tween_intensity: float
@export var tween_duration: float

var current_player = "X"  # Keep track of the current player
var cells = []  # Store references to buttons
var small_board_wins = []  # Track wins for small boards
var overall_winner = ""  # Track overall winner
var is_initialized = false  # Track if the board is initialized
var stats: Dictionary = load_stats()  # Load or initialize stats at the start
var active_column = -1  # Initialize with -1 to allow any board on the first move
var focusable_buttons: Array = []
var current_focus_index: int = 0

@onready var winner_label = $WinnerLabel  # General winner label
@onready var home_button = $HomeTownButton  # Reference to the HomeButton
@onready var rematch_button = $RematchYourselfButton  # Reference to the Rematch button
@onready var state_labels = [
	$State1, $State2, $State3, $State4, $State5, $State6, $State7, $State8, $State9
]
@onready var x_playing_label = $XIsPlaying
@onready var o_playing_label = $OIsPlaying
@onready var rematch: Button = $RematchYourselfButton
@onready var hometown: Button = $HomeTownButton
@onready var minihome: Button = $MiniHomePage

# Declare the variable for your AudioStreamPlayer
var button5_click_player: AudioStreamPlayer = null  # Reference to the AudioStreamPlayer for Button5

# Declare labels for each column
var x_win_labels = []
var o_win_labels = []
var tie_labels = []  # Array to hold tie labels for each column

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

func _ready():
	if has_node("CanvasLayer/Control/FPS_COUNTER_MINIBOARD"):
		$CanvasLayer/Control/FPS_COUNTER_MINIBOARD.add_to_group("fps_counters")
		$CanvasLayer/Control/FPS_COUNTER_MINIBOARD.visible = FpsManager.fps_enabled
		
	for label in state_labels:
		label.visible = false

	if is_initialized:  # Prevent re-initialization
		return
	is_initialized = true  # Mark as initialized
	
	stats = load_stats()  # Load existing stats

	# Initialize AudioStreamPlayer reference and set the sound stream
	button5_click_player = $Button5ClickPlayer  # Make sure this node exists in the scene
	button5_click_player.stream = load("res://Sounds/click.ogg")  # Set the path to your sound file

	cells.clear()
	small_board_wins = [null, null, null, null, null, null, null, null, null]  # Initialize small board wins
	winner_label.visible = false
	home_button.visible = false  # Hide the HomeButton initially
	rematch_button.visible = false  # Hide the Rematch button initially

	# Initialize labels for each column
	for i in range(1, 10):
		# Use 'get_node_safe' or check if the node exists
		var x_label = get_node("XWinLabelColumn" + str(i))
		var o_label = get_node("OWinLabelColumn" + str(i))
		var tie_label = get_node("ItsATieLabelColumn" + str(i))

		if x_label and o_label and tie_label:
			x_win_labels.append(x_label)
			o_win_labels.append(o_label)
			tie_labels.append(tie_label)
			x_win_labels[i - 1].visible = false
			o_win_labels[i - 1].visible = false
			tie_labels[i - 1].visible = false
		else:
			print("One or more labels not found for column: ", i)

	# Initialize cells for columns, connect all buttons, and apply colors
	for column_index in range(1, 10):  # Columns 1 to 9
		var grid_container: GridContainer = get_node("GridContainerColumn" + str(column_index))
		for cell_index in range(9):  # Cells 1 to 9 in each column
			var cell: Button = grid_container.get_child(cell_index)
			cells.append(cell)
			cell.connect("pressed", Callable(self, "_on_Cell_pressed").bind(column_index - 1, cell_index))
			update_cell_color(cell)  # Apply color to existing cells
			focusable_buttons.append(cell)  # Add each cell to focusable buttons

	# Add specific buttons to focusable buttons
	focusable_buttons.append_array([rematch_button, home_button, minihome])

	for button in focusable_buttons:
		button.focus_mode = Control.FOCUS_ALL

	# Set initial focus
	set_initial_focus()

	x_playing_label.visible = true  # X goes first
	o_playing_label.visible = false
	
	if $ResetGameButton:
		if not $ResetGameButton.is_connected("pressed", Callable(self, "_on_ResetGame_pressed")):
			$ResetGameButton.connect("pressed", Callable(self, "_on_ResetGame_pressed"))

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

func update_state_labels() -> void:
		for i in range(state_labels.size()):
			state_labels[i].visible = (i == active_column and not is_column_full(i))
		
		if active_column != -1 and not is_column_full(active_column):
			# Move focus to the first empty cell in the active column
			var grid_container: GridContainer = get_node("GridContainerColumn" + str(active_column + 1))
			for i in range(9):
				var cell: Button = grid_container.get_child(i)
				if cell.text == "":
					cell.grab_focus()
					current_focus_index = focusable_buttons.find(cell)
					break
		else:
			# If the active column is full, find the next available column
			active_column = find_next_unwon_column()
			if active_column != -1:
				update_state_labels()  # Recursively update labels and focus

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
		

# Function to play button click sound
func _play_button_click_sound():
	print("Playing button click sound")  # Debugging statement
	button5_click_player.play()  # Play the button click sound

# Single handler for all Cells (1-81)
func _on_Cell_pressed(column_index: int, cell_index: int) -> void:
	# Ignore input if game is won, move is in the wrong column, or column is already won
	if overall_winner != "" or (active_column != -1 and active_column != column_index) or small_board_wins[column_index] != null:
		return 

	var cell: Button = get_node("GridContainerColumn" + str(column_index + 1)).get_child(cell_index)
	
	# Check if the cell is already occupied
	if cell.text != "":
		state_labels[column_index].visible = true  # Indicate where to play if cell is occupied
		return

	# Mark the cell with the current player's symbol
	cell.text = current_player
	
	# Update the cell color using the update_cell_color function
	update_cell_color(cell)
	
	# Force the cell to redraw
	cell.queue_redraw()
	
	if check_winner(column_index):
		small_board_wins[column_index] = current_player
		update_column_win_label(column_index)
		lock_column(column_index)

		# Check for the overall winner
		if check_overall_winner():
			display_winner(current_player)
			lock_game()
			return
	else:
		state_labels[column_index].visible = false  # Hide state label after a move

	# Update the active column
	active_column = cell_index if small_board_wins[cell_index] == null else find_next_unwon_column()
	update_state_labels()
	
	# Hide all state labels and show the one for the next valid active column
	for label in state_labels:
		label.visible = false
	if active_column != -1:
		state_labels[active_column].visible = true
	else:
		active_column = find_next_unwon_column()
		if active_column != -1:
			state_labels[active_column].visible = true

	# Switch to the next player
	current_player = "O" if current_player == "X" else "X"
	
	# Update player turn labels
	x_playing_label.visible = (current_player == "X")
	o_playing_label.visible = (current_player == "O")
	
func update_cell_color(cell: Button) -> void:
	if cell.text != "":
		var color = ColorManager.get_player_color(cell.text)
		cell.add_theme_color_override("font_color", color)

func find_next_unwon_column() -> int:
	# Create a list of column indices and shuffle them
	var columns = [0, 1, 2, 3, 4, 5, 6, 7, 8]
	columns.shuffle()

	# Iterate through the randomized columns to find an available one
	for i in columns:
		if small_board_wins[i] == null:
			return i
	return -1  # Returns -1 if no unwon column is found


func update_stats(is_win: bool, player: String):
	print("Updating stats - is_win:", is_win, "player:", player)  # Debugging output
	# Ensure the necessary keys are present in the stats dictionary
	if not stats.has("Ultimate_Tic_Tac_Toe_Yourself_Won"):
		stats["Ultimate_Tic_Tac_Toe_Yourself_Won"] = 0
	if not stats.has("Ultimate_Tic_Tac_Toe_Yourself_Lost"):
		stats["Ultimate_Tic_Tac_Toe_Yourself_Lost"] = 0

	# Update stats based on win/loss and player
	if player == "X":
		if is_win:
			stats["Ultimate_Tic_Tac_Toe_Yourself_Won"] += 1
	elif player == "O":
		if is_win:
			stats["Ultimate_Tic_Tac_Toe_Yourself_Lost"] += 1

	save_stats(stats)

func display_winner(player: String) -> void:
	if player == "X":
		update_stats(true, "X")  # Player wins
		update_stats(false, "O")  # AI loses
		winner_label.text = "X wins!"
	elif player == "O":
		update_stats(false, "X")  # Player loses
		update_stats(true, "O")  # AI wins
		winner_label.text = "O wins!"
	else:
		# It's a tie
		update_stats(false, "X")
		update_stats(false, "O")
		winner_label.text = "It's a Tie!"

	for label in x_win_labels:
		label.visible = false
	for label in o_win_labels:
		label.visible = false
	
	winner_label.visible = true
	home_button.visible = true
	rematch_button.visible = true

	lock_game()
	overall_winner = player

	for column_index in range(1, 10):
		var grid_container: GridContainer = get_node("GridContainerColumn" + str(column_index))
		for cell_index in range(9):
			var cell: Button = grid_container.get_child(cell_index)
			update_cell_color(cell)
			cell.queue_redraw()  # Force redraw of the cell
			
			# Set focus to the appropriate button based on the winner
	if overall_winner == "X":
		rematch_button.grab_focus()  # Focus on rematch button
	else:
		home_button.grab_focus()  # Focus on home button

func end_game(is_player_win: bool):
	if is_player_win:  # If the player won
		update_stats(true, "X")  # Call with is_win true
	else:  # Player lost
		update_stats(false, "X")  # Call with is_win false 

func reset_game_state() -> void:
	current_player = "X"  # Reset current player
	small_board_wins = [null, null, null, null, null, null, null, null, null]  # Reset small board wins
	overall_winner = ""  # Reset overall winner
	active_column = -1  # Reset active column to allow any board for the next game


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
	var grid_container: GridContainer = get_node("GridContainerColumn" + str(column_index + 1))
	for i in range(9):
		var cell: Button = grid_container.get_child(i)
		cell.disabled = true
		# Ensure the color is maintained when locking
		update_cell_color(cell)

func lock_game() -> void:
	for column_index in range(9):
		lock_column(column_index)
	active_column = -1  # Reset active column to allow any board for rematch

func check_winner(column_index: int) -> bool:
	var grid_container: GridContainer = get_node("GridContainerColumn" + str(column_index + 1))

	# Check horizontal win
	for i in range(3):
		if grid_container.get_child(i * 3).text == current_player and \
		   grid_container.get_child(i * 3 + 1).text == current_player and \
		   grid_container.get_child(i * 3 + 2).text == current_player:
			return true

	# Check vertical win
	for i in range(3):
		if grid_container.get_child(i).text == current_player and \
		   grid_container.get_child(i + 3).text == current_player and \
		   grid_container.get_child(i + 6).text == current_player:
			return true

	# Check diagonal win
	if grid_container.get_child(0).text == current_player and \
	   grid_container.get_child(4).text == current_player and \
	   grid_container.get_child(8).text == current_player:
		return true

	if grid_container.get_child(2).text == current_player and \
	   grid_container.get_child(4).text == current_player and \
	   grid_container.get_child(6).text == current_player:
		return true

	return false


func check_overall_winner() -> bool:
	for i in range(3):
		if (small_board_wins[i * 3] == current_player and \
			small_board_wins[i * 3 + 1] == current_player and \
			small_board_wins[i * 3 + 2] == current_player) or \
		   (small_board_wins[i] == current_player and \
			small_board_wins[i + 3] == current_player and \
			small_board_wins[i + 6] == current_player):
			return true
	if (small_board_wins[0] == current_player and \
		small_board_wins[4] == current_player and \
		small_board_wins[8] == current_player) or \
	   (small_board_wins[2] == current_player and \
		small_board_wins[4] == current_player and \
		small_board_wins[6] == current_player):
		return true
	return false


func _on_hometown_button_pressed() -> void:
	button5_click_player.play()  # Play the button click sound
	print("HomeButton pressed")
	await get_tree().create_timer(0.1).timeout  # Add a delay
	Transition.load_scene("res://Scenes/UI.tscn")
	# get_tree().change_scene_to_file("res://UI.tscn")  # Update with your actual main menu scene path

func _on_minihomepage_pressed() -> void:
	button5_click_player.play()  # Play the button click sound
	print("MiniHomepage pressed")
	await get_tree().create_timer(0.1).timeout  # Add a delay
	Transition.load_scene("res://Scenes/UI.tscn")
	# get_tree().change_scene_to_file("res://UI.tscn")  # Update with your actual main menu scene path

func _on_rematchyourselfbutton_pressed() -> void:
	button5_click_player.play()  # Play the button click sound
	print("Rematch button pressed")
	await get_tree().create_timer(0.1).timeout  # Add a delay
	# Call functions to reset the game
	clear_board()
	reset_labels()
	reset_game_state()
	rematch_button.visible = false  # Hide the rematch button after pressing it
	home_button.visible = false # hide after pressed


func clear_board() -> void:
	for column_index in range(9):
		var grid_container: GridContainer = get_node("GridContainerColumn" + str(column_index + 1))
		for i in range(9):
			var cell: Button = grid_container.get_child(i)
			cell.text = ""
			cell.disabled = false  # Re-enable the cells
			cell.remove_theme_color_override("font_color")  # Reset color override if needed

func reset_labels() -> void:
	for label in x_win_labels:
		label.visible = false
	for label in o_win_labels:
		label.visible = false
	for label in tie_labels:
		label.visible = false
	winner_label.visible = false  # Hide the winner label

func _on_ResetGame_pressed() -> void:
	button5_click_player.play()  # Play the button click sound
	print("Reset Game button pressed")
	await get_tree().create_timer(0.1).timeout  # Add a delay
	reset_game()
	
func reset_game() -> void:
	# Clear the board
	clear_board()
	
	# Reset labels
	reset_labels()
	
	# Reset game state
	reset_game_state()
	
	# Hide rematch and home buttons
	rematch_button.visible = false
	home_button.visible = false
	
	# Reset player turn labels
	x_playing_label.visible = true
	o_playing_label.visible = false
	
	# Clear overall winner
	overall_winner = ""
	
	# Reset active column
	active_column = -1
	
	# Clear small board wins
	small_board_wins = [null, null, null, null, null, null, null, null, null]
	
	# Reset current player
	current_player = "X"
	
	# Update state labels
	update_state_labels()
	
	# Enable all cells
	for column_index in range(9):
		var grid_container: GridContainer = get_node("GridContainerColumn" + str(column_index + 1))
		for cell in grid_container.get_children():
			cell.disabled = false

	# Hide winner label
	winner_label.visible = false
