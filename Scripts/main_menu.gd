extends Control

var music_fade_tween: Tween = null

@onready var start_button: Button = $Center/VBox/StartButton
@onready var credits_button: Button = $Center/VBox/CreditsButton
@onready var leaderboard_button: Button = $Center/VBox/LeaderboardButton
@onready var quit_button: Button = $Center/VBox/QuitButton
@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var hover_sound_stream_player: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var username_container: HBoxContainer = $UsernameContainer
@onready var username_label: Label = $UsernameContainer/UsernameDisplay
@onready var change_username_button: Button = $UsernameContainer/ChangeUsernameButton

var target_volume = -100.0

func _ready() -> void:
	# Check for username first - redirect to prompt if not set
	if LeaderboardManager.player_username.is_empty():
		LeaderboardManager.load_username()
	
	if LeaderboardManager.player_username.is_empty():
		# No username saved, redirect to username prompt immediately
		get_tree().change_scene_to_file("res://Scenes/username_prompt.tscn")
		return
	
	if start_button != null:
		start_button.pressed.connect(_on_start_pressed)
	if credits_button != null:
		credits_button.pressed.connect(_on_credits_pressed)
	if leaderboard_button != null:
		leaderboard_button.pressed.connect(_on_leaderboard_pressed)
	if quit_button != null:
		quit_button.pressed.connect(_on_quit_pressed)
	if change_username_button != null:
		change_username_button.pressed.connect(_on_change_username_pressed)
	
	# Display username
	_update_username_display()
	
	# Fade in menu music
	if music_player != null:
		music_player.volume_db = target_volume
		music_fade_tween = create_tween()
		music_fade_tween.tween_property(music_player, "volume_db", 0.0, 0.2)

func _update_username_display() -> void:
	"""Update the username label with the current player username"""
	if username_label == null or username_container == null:
		return
	
	# Username should always exist when we reach this point (checked in _ready)
	if not LeaderboardManager.player_username.is_empty():
		username_label.text = "Player: " + LeaderboardManager.player_username
		username_container.visible = true
	else:
		username_container.visible = false

func _on_start_pressed() -> void:
	Engine.time_scale = 1.0
	
	# Username is guaranteed to exist at this point (checked in _ready)
	if music_player != null and music_player.playing:
		await _fade_out_music()
	get_tree().change_scene_to_file("res://Scenes/game.tscn")

func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/credits.tscn")

func _on_leaderboard_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/leaderboard.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _fade_out_music() -> void:
	"""Fade out the menu music smoothly"""
	if music_player == null:
		return
	
	if music_fade_tween != null:
		music_fade_tween.kill()
	
	music_fade_tween = create_tween()
	music_fade_tween.tween_property(music_player, "volume_db", target_volume, 1.0)
	await music_fade_tween.finished
	music_player.stop()


func _on_start_button_mouse_entered() -> void:
	hover_sound_stream_player.play()


func _on_credits_button_mouse_entered() -> void:
	hover_sound_stream_player.play()


func _on_leaderboard_button_mouse_entered() -> void:
	hover_sound_stream_player.play()

func _on_change_username_pressed() -> void:
	"""Allow player to change their username"""
	get_tree().change_scene_to_file("res://Scenes/username_prompt.tscn")

func _on_change_username_button_mouse_entered() -> void:
	hover_sound_stream_player.play()


func _on_quit_button_mouse_entered() -> void:
	hover_sound_stream_player.play()
