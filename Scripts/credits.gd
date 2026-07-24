extends Control

## Credits scene

@onready var back_button: Button = $BackButton

func _ready() -> void:
	if back_button != null:
		back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
