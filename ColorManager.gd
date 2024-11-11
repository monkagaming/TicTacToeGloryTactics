extends Node

var x_color: Color = Color(1, 1, 1, 1)  # White
var o_color: Color = Color(1, 1, 1, 1)  # White

func set_player_color(player: String, color: Color):
	if player == "X":
		x_color = color
	elif player == "O":
		o_color = color

func get_player_color(player: String) -> Color:
	if player == "X":
		return x_color
	elif player == "O":
		return o_color
	else:
		return Color.WHITE  # Default color if player is neither X nor O
