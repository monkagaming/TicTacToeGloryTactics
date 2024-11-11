extends Popup

@export var tween_intensity: float
@export var tween_duration: float

@onready var close: Button = $VBoxContainer/CloseButton

func _ready():
	# Set the background color of ColorRect to gray
	$ColorRect.color = Color(0.2, 0.2, 0.2)  # RGB values for gray (normalized between 0 and 1)
	
	# Set the ColorRect size to the desired dimensions
	$ColorRect.size = Vector2(300, 500)  # Set to the desired size
	
	# Set default text for the label
	$VBoxContainer/LeaderboardLabel.text = "Coming Soon! The leaderboard 
	will be refreshed with each update."
	
	# Center the popup on screen
	popup_centered()

	# Grab focus on the CloseButton after popup is centered
	close.grab_focus()
	
	# Connect the close button's pressed signal to the close function if not already connected
	if not $VBoxContainer/CloseButton.is_connected("pressed", Callable(self, "_on_CloseButton_pressed")):
		$VBoxContainer/CloseButton.connect("pressed", Callable(self, "_on_CloseButton_pressed"))

func _process(_delta: float) -> void:
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

func _on_CloseButton_pressed() -> void:
	queue_free()  # Close the popup by freeing it
