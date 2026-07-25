extends Control

var music_fade_tween: Tween = null

@onready var start_button: Button = $Center/VBox/StartButton
@onready var credits_button: Button = $Center/VBox/CreditsButton
@onready var quit_button: Button = $Center/VBox/QuitButton
@onready var music_player: AudioStreamPlayer = $MusicPlayer

func _ready() -> void:
	if start_button != null:
		start_button.pressed.connect(_on_start_pressed)
	if credits_button != null:
		credits_button.pressed.connect(_on_credits_pressed)
	if quit_button != null:
		quit_button.pressed.connect(_on_quit_pressed)
	
	# Fade in menu music
	if music_player != null:
		music_player.volume_db = -80.0
		music_fade_tween = create_tween()
		music_fade_tween.tween_property(music_player, "volume_db", 0.0, 0.2)

func _on_start_pressed() -> void:
	Engine.time_scale = 1.0
	# Fade out menu music before transitioning
	if music_player != null and music_player.playing:
		await _fade_out_music()
	get_tree().change_scene_to_file("res://Scenes/game.tscn")

func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/credits.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _fade_out_music() -> void:
	"""Fade out the menu music smoothly"""
	if music_player == null:
		return
	
	if music_fade_tween != null:
		music_fade_tween.kill()
	
	music_fade_tween = create_tween()
	music_fade_tween.tween_property(music_player, "volume_db", -80.0, 1.0)
	await music_fade_tween.finished
	music_player.stop()
