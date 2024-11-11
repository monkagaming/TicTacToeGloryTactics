extends Button

signal cell_updated(cell)
var main: Control
var cell_value: String = ""

@onready var background = $Background
@onready var border = $Border

func _ready():
	self_modulate.a = 0
	pressed.connect(_on_pressed)

func _on_pressed():
	draw_cell()

func draw_x():
	var tween = create_tween()
	self_modulate = Color("#00ffff")
	self_modulate.a = 0
	text = "X"
	cell_value = "X"
	tween.tween_property(self, "self_modulate:a", 1, 0.5)

func draw_o():
	var tween = create_tween()
	self_modulate = Color("#ff4200")
	self_modulate.a = 0
	text = "O"
	cell_value = "O"
	tween.tween_property(self, "self_modulate:a", 1, 0.5)

func draw_cell():
	if main == null or main.is_game_end or cell_value != "":
		return
	
	if main.current_player == "X":
		draw_x()
	else:
		draw_o()
	
	cell_updated.emit(self)

func glow(color: Color):
	var tween = create_tween()
	background.modulate = color
	background.modulate.a = 0
	tween.tween_property(background, "modulate:a", 1, 0.5)
