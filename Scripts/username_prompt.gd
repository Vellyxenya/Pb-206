extends Control

@onready var input_field: LineEdit = $Center/Panel/Margin/VBox/Input
@onready var status_label: Label = $Center/Panel/Margin/VBox/Status
@onready var cancel_button: Button = $Center/Panel/Margin/VBox/Buttons/CancelButton
@onready var submit_button: Button = $Center/Panel/Margin/VBox/Buttons/SubmitButton

var is_checking: bool = false

func _ready() -> void:
	if cancel_button != null:
		cancel_button.pressed.connect(_on_cancel_pressed)
	if submit_button != null:
		submit_button.pressed.connect(_on_submit_pressed)
	if input_field != null:
		input_field.text_submitted.connect(_on_text_submitted)
		input_field.grab_focus()
	
	status_label.text = ""

func _on_cancel_pressed() -> void:
	if is_checking:
		return
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func _on_text_submitted(_new_text: String) -> void:
	_on_submit_pressed()

func _on_submit_pressed() -> void:
	if is_checking:
		return
		
	var username = input_field.text.strip_edges()
	
	# Local Validation
	if username.is_empty():
		status_label.add_theme_color_override("font_color", Color(0.9, 0.35, 0.35))
		status_label.text = "Error: Signifier cannot be empty."
		return
		
	if username.length() > 18:
		status_label.add_theme_color_override("font_color", Color(0.9, 0.35, 0.35))
		status_label.text = "Error: Max length is 18 characters."
		return
		
	# Check basic alphanumeric/safe characters
	var regex = RegEx.new()
	regex.compile("^[a-zA-Z0-9_\\-\\s]+$")
	var result = regex.search(username)
	if result == null:
		status_label.add_theme_color_override("font_color", Color(0.9, 0.35, 0.35))
		status_label.text = "Error: Invalid characters. Use letters, numbers, spaces, underscores, or hyphens."
		return
		
	_set_loading_state(true)
	status_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	status_label.text = "Verifying signifier uniqueness in sequence core..."
	
	# Contact REST backend
	var exists = await LeaderboardManager.check_username_exists(username)
	
	if exists:
		_set_loading_state(false)
		status_label.add_theme_color_override("font_color", Color(0.95, 0.45, 0.2))
		status_label.text = "Taken: Signifier already registered in core. Choose another."
	else:
		status_label.add_theme_color_override("font_color", Color(0.3, 0.85, 0.45))
		status_label.text = "Success: Signifier confirmed. Starting sequence..."
		LeaderboardManager.player_username = username
		
		# Save username locally for future sessions
		LeaderboardManager.save_username(username)
		
		# Short delay for visual feedback before loading game
		await get_tree().create_timer(1.2).timeout
		get_tree().change_scene_to_file("res://Scenes/game.tscn")
	
func _set_loading_state(active: bool) -> void:
	is_checking = active
	if input_field != null:
		input_field.editable = !active
	if cancel_button != null:
		cancel_button.disabled = active
	if submit_button != null:
		submit_button.disabled = active
