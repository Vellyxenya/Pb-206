extends Node2D

@export var goal_radius: float = 1200.0
@export var goal_arrow_padding: float = 142.0
@export var transition_duration: float = 0.8
@export var goal_margin: float = 220.0
@export var game_over_time_scale: float = 0.22
@export var points_per_second_in_goal: float = 2.0
@export var energy_per_photon: float = 15.0

const GOAL_VISUAL_SEGMENTS: int = 64

var is_transitioning: bool = false
var is_game_over: bool = false
var starting_isotope_key: String = ""
var current_phase_index: int = 1
var current_score: int = 0
var _goal_bonus_accumulator: float = 0.0
var lucky_popup_tween: Tween
var phase_sounds: Array[AudioStream] = []
var phase_audio_player: AudioStreamPlayer
var victory_music: AudioStream = null
var game_over_sound: AudioStream = null
var music_fade_tween: Tween = null  # Tween for music fade transitions
var sfx_player: AudioStreamPlayer = null  # Sound effects player
var blink_tween: Tween
var _next_phase_timer: float = -1.0  # Pre-sampled timer for next phase
var last_finish_state := true
var _last_countdown_second: int = -1  # Track last shown countdown second
var _countdown_tween: Tween = null  # Tween for countdown animation

@onready var atom: RigidBody2D = $Player/Atom
@onready var camera: Camera2D = $Player/Atom/Camera2D
@onready var background: Node2D = $Background
@onready var ui_layer: CanvasLayer = $UI
@onready var timer_label: Label = $UI/PhaseTimerLabel
@onready var score_label: Label = $UI/ScoreLabel
@onready var goal_status_label: Label = $UI/GoalStatusLabel
@onready var transition_flash: ColorRect = $UI/TransitionFlash
@onready var game_over_overlay: ColorRect = $UI/GameOverOverlay
@onready var game_over_title: Label = $UI/GameOverOverlay/GameOverPanel/GameOverContent/GameOverTitle
@onready var restart_button: Button = $UI/GameOverOverlay/GameOverPanel/GameOverContent/ButtonRow/RestartButton
@onready var main_menu_button: Button = $UI/GameOverOverlay/GameOverPanel/GameOverContent/ButtonRow/MainMenuButton
@onready var victory_overlay: ColorRect = $UI/VictoryOverlay
@onready var victory_score_display: Label = $UI/VictoryOverlay/VictoryPanel/VictoryContent/ScoreDisplay
@onready var victory_restart_button: Button = $UI/VictoryOverlay/VictoryPanel/VictoryContent/VictoryButtonRow/VictoryRestartButton
@onready var victory_main_menu_button: Button = $UI/VictoryOverlay/VictoryPanel/VictoryContent/VictoryButtonRow/VictoryMainMenuButton
@onready var lucky_popup_label: Label = $UI/LuckyPopupLabel
@onready var goal_area: Node2D = $GoalArea
@onready var goal_fill: Polygon2D = $GoalArea/GoalFill
@onready var goal_outline: Line2D = $GoalArea/GoalOutline
@onready var goal_arrow: Sprite2D = $Player/Atom/GoalArrow
@onready var goal_distance_label: Label = $Player/Atom/GoalDistanceLabel
@onready var hazards_root: Node2D = $Hazards
@onready var collectibles_root: Node2D = $Collectibles
@onready var spawn_manager: Node2D = $SpawnManager
@onready var hover_sound_stream_player: AudioStreamPlayer2D = $UI/ButtonHoverSound
@onready var alpha_decay_sound_player: AudioStreamPlayer = $AlphaDecaySound
@onready var beta_decay_sound_player: AudioStreamPlayer = $BetaDecaySound
@onready var neutrino_collision_player: AudioStreamPlayer = $NeutrinoCollisionPlayer
@onready var countdown_timer_label: Label = $UI/CountdownTimerLabel
@onready var beep_sound_player: AudioStreamPlayer = $BeepSoundPlayer

func _ready() -> void:
	add_to_group("game")  # Allow hazards to find the game node
	
	# Setup spawn manager
	if spawn_manager != null:
		spawn_manager.setup_references(atom, camera, hazards_root, collectibles_root, self)
		spawn_manager.goal_radius = goal_radius
	
	if atom != null:
		starting_isotope_key = atom.isotope_key
		atom.phase_timer_finished.connect(_on_atom_phase_timer_finished)
		atom.cheat_decay_triggered.connect(_on_atom_cheat_decay)
	if restart_button != null:
		restart_button.pressed.connect(_on_restart_pressed)
	if main_menu_button != null:
		main_menu_button.pressed.connect(_on_main_menu_pressed)
	if victory_restart_button != null:
		victory_restart_button.pressed.connect(_on_restart_pressed)
	if victory_main_menu_button != null:
		victory_main_menu_button.pressed.connect(_on_main_menu_pressed)
	if transition_flash != null:
		transition_flash.visible = false
	if game_over_overlay != null:
		game_over_overlay.visible = false
	if victory_overlay != null:
		victory_overlay.visible = false
	if lucky_popup_label != null:
		lucky_popup_label.visible = false
	Engine.time_scale = 1.0
	
	goal_distance_label.modulate = Color(0.0, 0.0, 0.0, 1.0)

	current_score = 0
	_update_score_display()

	_setup_phase_audio()
	_play_sound_for_phase(current_phase_index)

	_rebuild_goal_visual()
	
	# Spawn initial entities
	if spawn_manager != null:
		spawn_manager.spawn_initial_entities()
		spawn_manager.connect_photon_signals(self)
	_update_goal_area_visual()
	_update_goal_status(false)
	_update_goal_guidance(false)

func _process(_delta):
	if background != null:
		var background_anchor = atom.global_position if atom != null else Vector2.ZERO
		if camera != null:
			background_anchor = camera.global_position
		background.set_view_center(background_anchor)

	if atom != null and timer_label != null and atom.has_method("get_phase_time_left"):
		var time_left = atom.get_phase_time_left()
		var isotope_data = IsotopeData.get_isotope(atom.isotope_key)
		var isotope_name = isotope_data.get("name", atom.isotope_key)
		var decay_type = isotope_data.get("decay_type", "unknown")
		
		# Format decay type for display
		var decay_display = ""
		if decay_type == "alpha":
			decay_display = "α-decay"
		elif decay_type == "beta":
			decay_display = "β-decay"
		elif decay_type == "stable":
			decay_display = "STABLE"
		else:
			decay_display = decay_type
		
		timer_label.text = "Phase " + str(current_phase_index) + "/14: " + isotope_name + " (" + decay_display + ")\nTime: " + str(snapped(time_left, 0.1))
		
		# Update countdown timer in last 10 seconds
		_update_countdown_timer(time_left)

	var in_finish_area := is_atom_in_finish_area()
	_update_goal_area_visual()
	_update_goal_status(in_finish_area)
	_update_goal_guidance(in_finish_area)
	
	# Award points per second while in goal area
	if in_finish_area and not is_transitioning and not is_game_over:
		_goal_bonus_accumulator += points_per_second_in_goal * _delta
		if _goal_bonus_accumulator >= 1.0:
			var points_to_add = int(_goal_bonus_accumulator)
			_goal_bonus_accumulator -= float(points_to_add)
			add_score(points_to_add)

func is_atom_in_finish_area() -> bool:
	if atom == null or spawn_manager == null:
		return false

	return atom.global_position.distance_to(spawn_manager.goal_position) <= goal_radius

func _on_atom_phase_timer_finished() -> void:
	if atom == null or is_game_over:
		return

	if is_atom_in_finish_area():
		start_phase_transition(true)
	else:
		start_phase_transition(false, "Timer expired outside finish area")

func _on_atom_cheat_decay() -> void:
	"""Called when debug key 'D' is pressed - always succeeds"""
	if atom == null or is_game_over:
		return
	start_phase_transition(true)

func start_phase_transition(success: bool, death_cause: String = "") -> void:
	if is_transitioning or is_game_over:
		return
	is_transitioning = true
	
	# Hide and reset countdown timer
	if countdown_timer_label != null:
		countdown_timer_label.visible = false
	_last_countdown_second = -1
	if _countdown_tween:
		_countdown_tween.kill()

	if success:
		print("Phase success: atom in finish area at timer end.")
		# Play decay effect before transition
		if atom != null and atom.has_method("play_decay_effect"):
			var current_data = IsotopeData.get_isotope(atom.isotope_key)
			var decay_type = current_data.get("decay_type", "unknown")
			if decay_type != "stable":
				await atom.play_decay_effect(decay_type)
				# Show decay transition text
				await show_decay_transition_text(current_data, decay_type)
	else:
		print("Phase fail: atom outside finish area at timer end.")
		if atom != null and atom.has_method("play_destroy_animation"):
			await atom.play_destroy_animation()

	await play_transition_flash(success)
	
	if success:
		var dt = IsotopeData.get_isotope(atom.isotope_key).get("decay_type", "unknown")
		if "alpha" in dt:
			alpha_decay_sound_player.play()
		elif "beta" in dt:
			beta_decay_sound_player.play()

	if success:
		advance_to_next_phase()
	else:
		enter_game_over_state(death_cause)

	is_transitioning = false

func play_transition_flash(success: bool) -> void:
	if transition_flash == null:
		await get_tree().create_timer(transition_duration).timeout
		return

	var flash_color = Color(0.55, 0.95, 0.60, 0.0) if success else Color(0.95, 0.45, 0.45, 0.0)
	transition_flash.visible = true
	transition_flash.color = flash_color

	var tween = create_tween()
	tween.tween_property(transition_flash, "color:a", 0.45, transition_duration * 0.35)
	tween.tween_property(transition_flash, "color:a", 0.0, transition_duration * 0.65)
	await tween.finished
	transition_flash.visible = false

func show_decay_transition_text(current_data: Dictionary, decay_type: String) -> void:
	"""Show animated text explaining the decay transition"""
	if atom == null or ui_layer == null:
		return
	
	# Get next isotope info
	var next_isotope_key = current_data.get("next_isotope", "")
	if next_isotope_key == "":
		return
	
	var next_data = IsotopeData.get_isotope(next_isotope_key)
	if next_data.is_empty():
		return
	
	var current_name = current_data.get("name", "")
	var next_name = next_data.get("name", "")
	
	# Pre-sample the timer for the next phase
	var timer_range = next_data.get("timer_range", [60, 120])
	var timer_min = float(timer_range[0])
	var timer_max = float(timer_range[1])
	_next_phase_timer = randf_range(timer_min, timer_max)
	
	# Create overlay container in screen space
	var overlay = ColorRect.new()
	overlay.name = "DecayTransitionOverlay"
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.z_index = 100  # Ensure it's on top of other UI elements
	ui_layer.add_child(overlay)
	
	# Create container for text
	var vbox = VBoxContainer.new()
	vbox.anchor_left = 0.5
	vbox.anchor_top = 0.5
	vbox.anchor_right = 0.5
	vbox.anchor_bottom = 0.5
	vbox.offset_left = -300
	vbox.offset_top = -100
	vbox.offset_right = 300
	vbox.offset_bottom = 100
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	overlay.add_child(vbox)
	
	# Decay type label
	var decay_label = Label.new()
	var decay_text = "α-DECAY" if decay_type == "alpha" else "β-DECAY"
	decay_label.text = decay_text
	decay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	decay_label.add_theme_font_size_override("font_size", 36)
	decay_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	decay_label.modulate = Color(1, 1, 1, 0)
	vbox.add_child(decay_label)
	
	# Current isotope label (will be struck through)
	var current_label = Label.new()
	current_label.text = current_name
	current_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	current_label.add_theme_font_size_override("font_size", 48)
	current_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
	current_label.modulate = Color(1, 1, 1, 0)
	vbox.add_child(current_label)
	
	# Arrow label
	var arrow_label = Label.new()
	arrow_label.text = "↓"
	arrow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow_label.add_theme_font_size_override("font_size", 60)
	arrow_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.5, 1.0))
	arrow_label.modulate = Color(1, 1, 1, 0)
	vbox.add_child(arrow_label)
	
	# Next isotope label
	var next_label = Label.new()
	next_label.text = next_name
	next_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	next_label.add_theme_font_size_override("font_size", 52)
	next_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5, 1.0))
	next_label.modulate = Color(1, 1, 1, 0)
	vbox.add_child(next_label)
	
	# Timer label for decay cycle duration
	var decay_timer_label = Label.new()
	decay_timer_label.text = "Time before next decay: ???"
	decay_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	decay_timer_label.add_theme_font_size_override("font_size", 28)
	decay_timer_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0, 1.0))
	decay_timer_label.modulate = Color(1, 1, 1, 0)
	vbox.add_child(decay_timer_label)
	
	# Strikethrough line for current isotope
	var strikethrough = ColorRect.new()
	strikethrough.color = Color(1.0, 0.3, 0.3, 0.9)
	strikethrough.size = Vector2(0, 4)
	strikethrough.position = Vector2(0, 0)
	strikethrough.z_index = 1
	current_label.add_child(strikethrough)
	
	# Animation sequence
	var seq_tween = create_tween()
	
	# 1. Fade in decay type (0.3s)
	seq_tween.tween_property(decay_label, "modulate:a", 1.0, 0.3)
	seq_tween.tween_interval(0.2)
	
	# 2. Fade in current isotope (0.3s)
	seq_tween.tween_property(current_label, "modulate:a", 1.0, 0.3)
	seq_tween.tween_interval(0.3)
	
	# 3. Strikethrough animation (0.4s)
	seq_tween.tween_method(func(width: float):
		var label_width = current_label.size.x
		strikethrough.size = Vector2(width, 4)
		strikethrough.position = Vector2((label_width - width) * 0.5, current_label.size.y * 0.5 - 2)
	, 0.0, current_label.size.x, 0.4)
	seq_tween.tween_interval(0.2)
	
	# 4. Fade in arrow (0.2s)
	seq_tween.tween_property(arrow_label, "modulate:a", 1.0, 0.2)
	seq_tween.tween_interval(0.1)
	
	# 5. Fade in next isotope with scale (0.4s)
	next_label.scale = Vector2(0.8, 0.8)
	seq_tween.set_parallel(true)
	seq_tween.tween_property(next_label, "modulate:a", 1.0, 0.4)
	seq_tween.tween_property(next_label, "scale", Vector2(1.0, 1.0), 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	seq_tween.set_parallel(false)
	seq_tween.tween_interval(0.3)
	
	# 6. Fade in timer label and animate random numbers (1.2s)
	seq_tween.tween_property(decay_timer_label, "modulate:a", 1.0, 0.2)
	seq_tween.tween_callback(func():
		# Rapidly show random numbers for 1 second
		var timer_anim_tween = create_tween()
		var random_duration = 1.0
		var update_interval = 0.05  # Update every 50ms for fast changing effect
		var updates = int(random_duration / update_interval)
		
		for i in range(updates):
			timer_anim_tween.tween_callback(func():
				var random_time = randf_range(timer_min, timer_max)
				decay_timer_label.text = "Time before next decay: " + str(snapped(random_time, 0.1)) + "s"
			)
			timer_anim_tween.tween_interval(update_interval)
		
		# Show the final sampled value
		timer_anim_tween.tween_callback(func():
			decay_timer_label.text = "Time before next decay: " + str(snapped(_next_phase_timer, 0.1)) + "s"
			decay_timer_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3, 1.0))  # Highlight final value
		)
	)
	seq_tween.tween_interval(1.4)  # Wait for random animation to complete
	
	# 7. Fade out everything (0.3s)
	seq_tween.tween_property(overlay, "modulate:a", 0.0, 0.3)
	
	await seq_tween.finished
	overlay.queue_free()

func get_next_phase_timer() -> float:
	"""Get the pre-sampled timer value for the next phase"""
	return _next_phase_timer

func clear_next_phase_timer() -> void:
	"""Clear the pre-sampled timer value after use"""
	_next_phase_timer = -1.0

func advance_to_next_phase() -> void:
	is_game_over = false
	Engine.time_scale = 1.0
	if game_over_overlay != null:
		game_over_overlay.visible = false

	var advanced = false
	if atom != null:
		atom.on_phase_completed()
		var current_data = IsotopeData.get_isotope(atom.isotope_key)
		
		if not current_data.is_empty() and current_data.get("next_isotope") != null:
			var decay_type = current_data.get("decay_type", "alpha")
			atom.isotope_key = str(current_data.next_isotope)
			
			# Check if we've reached stable Pb-206 (after setting new isotope_key)
			var next_data = IsotopeData.get_isotope(atom.isotope_key)
			if not next_data.is_empty() and next_data.get("decay_type") == "stable":
				# Reached stable isotope - handle victory sequence
				handle_stable_isotope_victory()
				return
			
			# Set charge based on decay type
			# Beta decay emits an electron, leaving the atom with +1 charge
			# Alpha decay removes 2p+2n, atom remains neutral (0 charge)
			if decay_type == "beta":
				atom.set_charge(1)
				print("β-decay occurred: atom is now positively charged (+1)")
			else:
				atom.set_charge(0)
				print("α-decay occurred: atom remains neutral (0)")
			
			advanced = true

	if advanced:
		current_phase_index += 1
	_play_sound_for_phase(current_phase_index)

	if spawn_manager != null:
		spawn_manager.clear_all_entities()
		spawn_manager.spawn_initial_entities()
		spawn_manager.connect_photon_signals(self)
	if atom != null:
		atom.load_isotope_data()
		atom.reset_phase_visuals()

func show_victory_screen() -> void:
	is_game_over = true
	Engine.time_scale = 0.6
	
	# Stop spawning hazards
	if spawn_manager != null:
		spawn_manager.set_process(false)
		spawn_manager.clear_all_entities()
	
	# Show victory overlay with final score
	if victory_overlay != null:
		victory_overlay.visible = true
	if victory_score_display != null:
		victory_score_display.text = "Final Score: " + str(current_score)
	
	print("Victory! Reached stable Pb-206 with score: ", current_score)

func handle_stable_isotope_victory() -> void:
	"""Handle transition to stable Pb-206 isotope"""
	print("Reached stable Pb-206! Starting victory sequence...")
	
	# Fade to victory music
	if phase_audio_player != null and victory_music != null:
		await _fade_to_music(victory_music)
	else:
		print("Warning: Victory music not available")
	
	# Load the stable isotope visuals but don't start timer
	if atom != null:
		atom.set_charge(0)  # Lead-206 is neutral
		atom.load_isotope_data()
		atom.reset_phase_visuals()
		atom.phase_active = false  # Disable phase timer for stable isotope
	
	# Hide UI elements
	if timer_label != null:
		timer_label.visible = false
	if countdown_timer_label != null:
		countdown_timer_label.visible = false
		_last_countdown_second = -1
	if _countdown_tween:
		_countdown_tween.kill()
	if goal_status_label != null:
		goal_status_label.visible = false
	if goal_arrow != null:
		goal_arrow.visible = false
	if goal_distance_label != null:
		goal_distance_label.visible = false
	
	# Clear all hazards
	if spawn_manager != null:
		spawn_manager.clear_all_entities()
	
	# Wait 4 seconds then show victory screen
	await get_tree().create_timer(4.0).timeout
	show_victory_screen()

func restart_current_phase() -> void:
	is_game_over = false
	is_transitioning = false
	Engine.time_scale = 1.0
	if game_over_overlay != null:
		game_over_overlay.visible = false
	if victory_overlay != null:
		victory_overlay.visible = false
	
	# Re-show UI elements
	if timer_label != null:
		timer_label.visible = true
	if goal_status_label != null:
		goal_status_label.visible = true

	current_score = 0
	_goal_bonus_accumulator = 0.0
	_update_score_display()

	if atom != null and not starting_isotope_key.is_empty():
		atom.isotope_key = starting_isotope_key
	current_phase_index = 1
	_play_sound_for_phase(current_phase_index)

	if spawn_manager != null:
		spawn_manager.set_process(true)  # Re-enable spawning
		spawn_manager.clear_all_entities()
		spawn_manager.spawn_initial_entities()
		spawn_manager.connect_photon_signals(self)
	if atom != null:
		atom.set_charge(0)  # Reset to neutral on restart
		atom.load_isotope_data()
		atom.reset_phase_visuals()

func enter_game_over_state(death_cause: String = "Timer expired outside finish area") -> void:
	is_game_over = true
	Engine.time_scale = game_over_time_scale
	
	# Hide and reset countdown timer
	if countdown_timer_label != null:
		countdown_timer_label.visible = false
	_last_countdown_second = -1
	if _countdown_tween:
		_countdown_tween.kill()
	
	# Fade out level music
	if phase_audio_player != null and phase_audio_player.playing:
		_fade_out_music()
	
	# Wait before showing game over screen
	await get_tree().create_timer(0.5).timeout
	
	# Play game over sound effect
	if sfx_player != null and game_over_sound != null:
		sfx_player.stream = game_over_sound
		sfx_player.play()
		
	if game_over_overlay != null:
		game_over_overlay.visible = true
	if game_over_title != null:
		game_over_title.text = "GAME OVER\n" + death_cause

func _on_collectible_collected(_collector: Node2D, points: int) -> void:
	add_score(points)
	print("Collected! +", points, " points. Total: ", current_score)
	
	# Add energy when collecting photons
	if atom != null:
		atom.add_energy(energy_per_photon)

func add_score(points: int) -> void:
	current_score += points
	_update_score_display()
	
	# Show floating score text
	if atom != null:
		_show_floating_score(points, atom.global_position)

func _update_score_display() -> void:
	if score_label != null:
		score_label.text = "Score: " + str(current_score)

func _show_floating_score(points: int, spawn_pos: Vector2) -> void:
	"""Create a floating text label showing score increase"""
	var label = Label.new()
	label.text = "+" + str(points)
	label.global_position = spawn_pos + Vector2(-20, -30)  # Offset above the atom
	label.z_index = 100  # Ensure it's on top
	
	# Style the label
	label.add_theme_color_override("font_color", Color.ORANGE)
	label.add_theme_font_size_override("font_size", 46)

	# Outline
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	
	add_child(label)
	
	# Animate: float up and fade out
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position:y", spawn_pos.y - 80, 1.0).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN)
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)  # Delete when done

func on_player_neutrino_death() -> void:
	"""Called when a neutrino hits the player"""
	if is_game_over or is_transitioning:
		return
	print("Player hit by neutrino!")
	neutrino_collision_player.play()
	if atom != null and atom.has_method("play_destroy_animation"):
		await atom.play_destroy_animation()
	enter_game_over_state("Destroyed by neutrino collision!")

func on_player_neutron_death_from_field() -> void:
	"""Called by spawn_manager when neutron field kills player"""
	if is_game_over or is_transitioning:
		return
	start_phase_transition(false, "Neutron field spike")

func show_lucky_popup() -> void:
	"""Called by spawn_manager when player survives neutron field"""
	if atom == null or lucky_popup_label == null or is_game_over:
		return
	
	var world_pos = atom.global_position + Vector2(0.0, -80.0)
	
	if lucky_popup_tween != null:
		lucky_popup_tween.kill()

	var viewport_pos = get_viewport().get_canvas_transform() * world_pos
	lucky_popup_label.text = "I got lucky"
	lucky_popup_label.visible = true
	lucky_popup_label.position = viewport_pos
	lucky_popup_label.modulate = Color(1.0, 1.0, 1.0, 1.0)

	lucky_popup_tween = create_tween()
	lucky_popup_tween.tween_property(lucky_popup_label, "position", viewport_pos + Vector2(0.0, -48.0), 0.95)
	lucky_popup_tween.parallel().tween_property(lucky_popup_label, "modulate:a", 0.0, 0.95)
	await lucky_popup_tween.finished
	lucky_popup_label.visible = false

func _on_restart_pressed() -> void:
	restart_current_phase()

func _on_main_menu_pressed() -> void:
	Engine.time_scale = 1.0
	# Fade out game music before returning to main menu
	if phase_audio_player != null and phase_audio_player.playing:
		await _fade_out_music()
	if ResourceLoader.exists("res://Scenes/main_menu.tscn"):
		get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
	else:
		print("Main menu scene missing; closing game.")
		get_tree().quit()

func _fade_out_music() -> void:
	"""Fade out the current music smoothly"""
	if phase_audio_player == null:
		return
	
	if music_fade_tween != null:
		music_fade_tween.kill()
	
	music_fade_tween = create_tween()
	music_fade_tween.tween_property(phase_audio_player, "volume_db", -80.0, 1.0)
	await music_fade_tween.finished
	phase_audio_player.stop()

func _update_goal_area_visual() -> void:
	if goal_area != null and spawn_manager != null:
		goal_area.global_position = spawn_manager.goal_position

func _rebuild_goal_visual() -> void:
	if goal_fill == null or goal_outline == null:
		return

	var fill_points := PackedVector2Array()
	var outline_points := PackedVector2Array()
	for index in range(GOAL_VISUAL_SEGMENTS):
		var angle = (float(index) / float(GOAL_VISUAL_SEGMENTS)) * TAU - PI * 0.5
		var point = Vector2.from_angle(angle) * goal_radius
		fill_points.append(point)
		outline_points.append(point)

	if not outline_points.is_empty():
		outline_points.append(outline_points[0])

	goal_fill.polygon = fill_points
	goal_outline.points = outline_points
	goal_outline.width = clamp(goal_radius * 0.05, 4.0, 18.0)

func _start_blink() -> void:
	if blink_tween:
		blink_tween.kill()

	blink_tween = create_tween()
	blink_tween.set_loops()

	blink_tween.tween_property(goal_status_label, "modulate:a", 0.2, 0.5)
	blink_tween.tween_property(goal_status_label, "modulate:a", 1.0, 0.5)

func _stop_blink() -> void:
	if blink_tween:
		blink_tween.kill()
		blink_tween = null

	goal_status_label.modulate.a = 1.0

func _update_goal_status(in_finish_area: bool) -> void:
	if goal_status_label == null:
		return

	# Only change color/text every frame, but don't restart blink
	goal_status_label.text = "Finish Area: IN" if in_finish_area else "Finish Area: OUT. Hurry to the area before the timer runs out!"

	var alpha = goal_status_label.modulate.a
	if in_finish_area:
		goal_status_label.modulate = Color(0.18, 0.62, 0.22, alpha)
	else:
		goal_status_label.modulate = Color(0.82, 0.2, 0.2, alpha)

	# Only start/stop blinking when state changes
	if in_finish_area != last_finish_state:
		if in_finish_area:
			_stop_blink()
		else:
			_start_blink()

	last_finish_state = in_finish_area
func _update_countdown_timer(time_left: float) -> void:
	"""Show and animate countdown timer in last 10 seconds"""
	if countdown_timer_label == null:
		return
	
	if time_left <= 10.0 and time_left > 0.0:
		# Show countdown
		var current_second = int(ceil(time_left))
		
		if current_second != _last_countdown_second:
			# New second - update and animate
			_last_countdown_second = current_second
			countdown_timer_label.text = str(current_second)
			countdown_timer_label.visible = true
			
			# Play beep sound
			if beep_sound_player != null:
				beep_sound_player.play()
			
			# Animate scale and color
			_animate_countdown_number()
	else:
		# Hide countdown when not in last 10 seconds
		if countdown_timer_label.visible:
			countdown_timer_label.visible = false
			_last_countdown_second = -1

func _animate_countdown_number() -> void:
	"""Animate countdown number with scale up and color transition"""
	if countdown_timer_label == null:
		return
	
	# Kill existing tween
	if _countdown_tween:
		_countdown_tween.kill()
	
	# Reset initial state
	countdown_timer_label.scale = Vector2(0.5, 0.5)
	countdown_timer_label.modulate = Color.WHITE
	
	# Create animation tween
	_countdown_tween = create_tween()
	_countdown_tween.set_parallel(true)
	
	# Scale up over 1 second
	_countdown_tween.tween_property(countdown_timer_label, "scale", Vector2(1.0, 1.0), 1.0).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	# Color transition from white to orange
	_countdown_tween.tween_property(countdown_timer_label, "modulate", Color(1.0, 0.5, 0.0, 1.0), 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func _update_goal_guidance(in_finish_area: bool) -> void:
	if atom == null or goal_arrow == null or goal_distance_label == null or spawn_manager == null:
		return

	var timer_active = atom.has_method("is_phase_active") and atom.is_phase_active()
	var to_goal = spawn_manager.goal_position - atom.global_position
	var distance = to_goal.length()
	var edge_distance = max(distance - goal_radius, 0.0)
	var show_guidance = timer_active and not is_transitioning and not is_game_over and not in_finish_area and distance > 1.0

	goal_arrow.visible = show_guidance
	goal_distance_label.visible = show_guidance
	if not show_guidance:
		return

	var direction = to_goal / distance
	var arrow_offset = direction * _get_goal_arrow_distance()
	goal_arrow.position = arrow_offset
	goal_arrow.rotation = direction.angle() + PI / 2.0
	
	# Position label at arrow tip + extra distance, centered on that point
	# Label dimensions: 100x26 pixels, so offset by (-50, -13) to center
	var label_center = arrow_offset + direction * 60.0
	goal_distance_label.position = label_center + Vector2(-50.0, -13.0)
	goal_distance_label.text = str(int(round(edge_distance / 10.0)))

func _get_goal_arrow_distance() -> float:
	if atom == null:
		return goal_arrow_padding

	var collision_shape = atom.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null:
		return goal_arrow_padding

	var circle = collision_shape.shape as CircleShape2D
	if circle == null:
		return goal_arrow_padding

	return circle.radius + goal_arrow_padding

func _setup_phase_audio() -> void:
	phase_audio_player = AudioStreamPlayer.new()
	phase_audio_player.name = "PhaseAudioPlayer"
	phase_audio_player.bus = "Master"
	phase_audio_player.autoplay = false
	add_child(phase_audio_player)
	
	# Create sound effects player
	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SFXPlayer"
	sfx_player.bus = "Master"
	sfx_player.autoplay = false
	add_child(sfx_player)

	phase_sounds = _load_phase_sounds()
	
	# Load victory music
	victory_music = load("res://Assets/Sounds/BlackTrendMusic - Sport Victory Energetic Rock.mp3") as AudioStream
	if victory_music == null:
		push_warning("Victory music not found!")
	
	# Load game over sound
	game_over_sound = load("res://Assets/Sounds/gameover.mp3") as AudioStream
	if game_over_sound == null:
		push_warning("Game over sound not found!")

func _load_phase_sounds() -> Array[AudioStream]:
	var sounds: Array[AudioStream] = []
	var entries: Array[Dictionary] = []

	var dir = DirAccess.open("res://Assets/Sounds")
	if dir == null:
		push_warning("Assets/Sounds folder not found. Phase sounds disabled.")
		return sounds

	for file_name in dir.get_files():
		if file_name.ends_with(".import"):
			continue
		var phase_number = _extract_phase_number(file_name)
		if phase_number <= 0:
			continue
		entries.append({
			"phase": phase_number,
			"path": "res://Assets/Sounds/" + file_name
		})

	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["phase"]) < int(b["phase"]) )

	for entry in entries:
		var stream = load(String(entry["path"])) as AudioStream
		if stream != null:
			sounds.append(stream)

	return sounds

func _extract_phase_number(file_name: String) -> int:
	var base = file_name.get_basename().to_lower()
	if not base.begins_with("kf"):
		return -1

	var digits = ""
	for i in range(2, base.length()):
		var ch = base.substr(i, 1)
		if ch >= "0" and ch <= "9":
			digits += ch
		else:
			break

	if digits.is_empty():
		return -1
	return int(digits)

func _play_sound_for_phase(phase_index: int) -> void:
	if phase_audio_player == null or phase_sounds.is_empty():
		return
	if phase_index <= 0:
		return
	
	# Loop music after phase 10: phase 11 uses kf01, phase 12 uses kf02, etc.
	var music_index = phase_index
	if phase_index > phase_sounds.size():
		music_index = ((phase_index - 1) % phase_sounds.size()) + 1
		print("Phase ", phase_index, " using music from phase ", music_index)
	
	if music_index > phase_sounds.size():
		push_warning("No phase sound found for phase " + str(phase_index))
		return

	await _fade_to_music(phase_sounds[music_index - 1])

func _fade_to_music(new_stream: AudioStream) -> void:
	"""Smoothly fade out current music and fade in new music"""
	if phase_audio_player == null:
		return
	
	# Kill any existing fade tween
	if music_fade_tween != null:
		music_fade_tween.kill()
	
	music_fade_tween = create_tween()
	
	# Fade out current music if playing
	if phase_audio_player.playing:
		music_fade_tween.tween_property(phase_audio_player, "volume_db", -80.0, 1.0)
		await music_fade_tween.finished
		phase_audio_player.stop()
	
	# Switch to new stream
	phase_audio_player.stream = new_stream
	phase_audio_player.volume_db = -80.0
	phase_audio_player.play()
	
	# Fade in new music
	music_fade_tween = create_tween()
	music_fade_tween.tween_property(phase_audio_player, "volume_db", 0.0, 1.0)
	await music_fade_tween.finished


func _on_restart_button_mouse_entered() -> void:
	hover_sound_stream_player.play()


func _on_main_menu_button_mouse_entered() -> void:
	hover_sound_stream_player.play()


func _on_victory_restart_button_mouse_entered() -> void:
	hover_sound_stream_player.play()


func _on_victory_main_menu_button_mouse_entered() -> void:
	hover_sound_stream_player.play()
