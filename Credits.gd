extends Popup

var rich_text_label: RichTextLabel
var close_button: Button

func _ready():
	# Set up the popup
	size = Vector2(550, 600)  # Increased height to accommodate the close button

	# Create a ColorRect for the background
	var color_rect = ColorRect.new()
	color_rect.color = Color(0.2, 0.2, 0.2)
	color_rect.size = size
	add_child(color_rect)

	# Create the RichTextLabel
	rich_text_label = RichTextLabel.new()
	rich_text_label.bbcode_enabled = true
	rich_text_label.size = Vector2(500, 500)
	rich_text_label.position = Vector2(25, 25)  # Adjust for some padding
	rich_text_label.focus_mode = Control.FOCUS_ALL  # Enable focus
	rich_text_label.text = """
	Game by [url=https://youtube.com/@monkagaming420]MonkaGaming420YT[/url]/Anthony

	Songs: 
	[url=https://www.youtube.com/watch?v=x-ObUKegl6g]Vibes - David Renda[/url]
	[url=https://www.youtube.com/watch?v=knxnwq2IudI]Bobbin - David Renda[/url]
	[url=https://www.youtube.com/watch?v=owrhKIN3Y90]Carefree - Kevin MacLeod[/url]
	[url=https://www.youtube.com/watch?v=w43ZLltyEtw]Decay - David Cutter Music[/url]
	[url=https://www.youtube.com/watch?v=tiLOCEvi_Gc]Done With Work - David Renda[/url]
	[url=https://www.youtube.com/watch?v=8K48ZglCAWU]Down Days - David Renda[/url]
	[url=https://www.youtube.com/watch?app=desktop&v=Aq3ROpi3GnE]Island - Jarico[/url]
	[url=https://www.youtube.com/watch?v=_Ux9TVKCNmM]Lazy Days - David Renda[/url]
	[url=https://www.youtube.com/watch?v=RX9x7Ua2kXQ]Sunset Dream - Cheel[/url]

	Click sound effect: [url=https://freesound.org/people/Breviceps/sounds/448081]Tic Toc UI Click[/url]

	Simple Tic Tac Toe picture credits: [url=https://projectbook.code.brettchalupa.com/games/img/ttt.webp]https://projectbook.code.brettchalupa.com/games/img/ttt.webp[/url]

	Super Tic Tac Toe credits: [url=https://upload.wikimedia.org/wikipedia/commons/7/7d/Super_tic-tac-toe_rules_example.png]https://upload.wikimedia.org/wikipedia/commons/7/7d/Super_tic-tac-toe_rules_example.png[/url]
	"""
	add_child(rich_text_label)

	# Connect the meta clicked signal
	rich_text_label.connect("meta_clicked", Callable(self, "_on_link_clicked"))

	# Create and add the Close Button
	close_button = Button.new()
	close_button.text = "Close"
	close_button.size = Vector2(100, 40)
	close_button.position = Vector2(size.x / 2.0 - 50, size.y - 60)
	close_button.focus_mode = Control.FOCUS_ALL  # Enable focus
	add_child(close_button)

	# Connect the close button's pressed signal to the close function
	close_button.connect("pressed", Callable(self, "_on_CloseButton_pressed"))

	# Automatically set focus
	focus_first_element()

func focus_first_element():
	# Focus on the RichTextLabel initially
	rich_text_label.grab_focus()

func _on_link_clicked(meta):
	OS.shell_open(meta)

func _on_CloseButton_pressed() -> void:
	hide()  # Hide the popup instead of freeing it

func _input(event: InputEvent):
	# Switch focus between RichTextLabel and CloseButton with Tab/Shift+Tab
	if event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up"):
		close_button.grab_focus()
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("ui_text_backspace"):
		rich_text_label.grab_focus()
