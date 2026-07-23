extends Control

@onready var start_button: Button = $Center/VBox/StartButton
@onready var quit_button: Button = $Center/VBox/QuitButton

func _ready() -> void:
	if start_button != null:
		start_button.pressed.connect(_on_start_pressed)
	if quit_button != null:
		quit_button.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://Scenes/game.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
