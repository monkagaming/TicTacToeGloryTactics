extends Control

var focusable_elements = []
var current_focus_index = 0

func _ready():
	setup_focusable_elements()
	set_initial_focus()
	connect_signals()

func setup_focusable_elements():
	focusable_elements = [
		$TabContainer/Audio/MarginContainer/VBoxContainer/Music_Slider/HBoxContainer/Volume_Slider,
		$TabContainer/Audio/MarginContainer/VBoxContainer/SFX_Slider/HBoxContainer/SFX_Slider,
		$TabContainer/Video/MarginContainer/VBoxContainer/FullscreenCheck/HBoxContainer/FullscreenCheck,
		$TabContainer/Video/MarginContainer/VBoxContainer/FPSCounterCheck/HBoxContainer/FPSCheckButton,
		$TabContainer/Video/MarginContainer/VBoxContainer/FrameRateLimit/HBoxContainer/FPSInput,
		$CloseButton
	]
	for element in focusable_elements:
		element.focus_mode = Control.FOCUS_ALL

func set_initial_focus():
	if focusable_elements.size() > 0:
		focusable_elements[0].grab_focus()
		current_focus_index = 0

func connect_signals():
	if not $CloseButton.pressed.is_connected(_on_close_button_pressed):
		$CloseButton.pressed.connect(_on_close_button_pressed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_down"):
		change_focus(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up"):
		change_focus(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
		adjust_setting(-1 if event.is_action_pressed("ui_left") else 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right_tab"):
		switch_tab(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left_tab"):
		switch_tab(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_on_element_activated()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):  # Check for cancel action
		_on_close_button_pressed()

func switch_tab(direction: int):
	var tab_container = $TabContainer
	var new_tab = (tab_container.current_tab + direction) % tab_container.get_tab_count()
	if new_tab < 0:
		new_tab = tab_container.get_tab_count() - 1
	tab_container.current_tab = new_tab
	set_initial_focus()  # Reset focus when switching tabs

func adjust_setting(direction: int):
	var focused_element = focusable_elements[current_focus_index]
	if focused_element is HSlider:
		focused_element.value += direction * 5  # Adjust by 5% each time
		focused_element.emit_signal("value_changed", focused_element.value)
	elif focused_element is CheckBox or focused_element is CheckButton:
		focused_element.button_pressed = !focused_element.button_pressed
		focused_element.emit_signal("toggled", focused_element.button_pressed)
	elif focused_element is LineEdit:
		var current_value = int(focused_element.text)
		current_value += direction
		current_value = clamp(current_value, 1, 60)  # Assuming 1-60 is the valid range
		focused_element.text = str(current_value)
		focused_element.emit_signal("text_submitted", focused_element.text)

func change_focus(direction: int):
	current_focus_index = (current_focus_index + direction) % focusable_elements.size()
	if current_focus_index < 0:
		current_focus_index = focusable_elements.size() - 1
	focusable_elements[current_focus_index].grab_focus()

func _on_element_activated():
	var focused_element = focusable_elements[current_focus_index]
	if focused_element is Button:
		focused_element.emit_signal("pressed")
	elif focused_element is CheckBox or focused_element is CheckButton:
		focused_element.button_pressed = !focused_element.button_pressed
		focused_element.emit_signal("toggled", focused_element.button_pressed)
	elif focused_element is LineEdit:
		focused_element.grab_focus()
	elif focused_element is HSlider:
		# You might want to implement a specific action for sliders
		pass

	# Handle specific elements
	match focused_element.name:
		"FullscreenCheck":
			var fullscreen_check = focused_element as CheckBox
			fullscreen_check.button_pressed = !fullscreen_check.button_pressed
			get_node("TabContainer/Video/MarginContainer/VBoxContainer/FullscreenCheck")._on_FullscreenCheck_toggled(fullscreen_check.button_pressed)
		"FPSCheckButton":
			var fps_check = focused_element as CheckButton
			fps_check.button_pressed = !fps_check.button_pressed
			get_node("TabContainer/Video/MarginContainer/VBoxContainer/FPSCounterCheck")._on_FPSCounter_check_toggled(fps_check.button_pressed)
		"FPSInput":
			var fps_input = focused_element as LineEdit
			fps_input.grab_focus()
			# You might want to open an on-screen keyboard here for mobile devices
		"CloseButton":
			_on_close_button_pressed()

func _on_close_button_pressed():
	print("Close Button Clicked! In settings")
	Transition.load_scene("res://Scenes/UI.tscn")
