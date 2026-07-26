extends Control

@onready var list_container: VBoxContainer = $Center/VBox/Scroll/ListContainer
@onready var status_label: Label = $Center/VBox/Status
@onready var back_button: Button = $Center/VBox/Buttons/BackButton

func _ready() -> void:
	if back_button != null:
		back_button.pressed.connect(_on_back_pressed)
		
	status_label.text = "Querying core registry..."
	_load_leaderboard()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func _load_leaderboard() -> void:
	# Clear existing children just in case
	for child in list_container.get_children():
		child.queue_free()
		
	var scores = await LeaderboardManager.fetch_leaderboard(100)
	
	if scores.is_empty():
		status_label.text = "Core registry database is empty or server is offline."
		status_label.add_theme_color_override("font_color", Color(0.9, 0.45, 0.45))
		return
		
	status_label.text = ""
	status_label.visible = false
	
	var rank = 1
	var regular_font = load("res://Assets/Fonts/Quantico/Quantico-Regular.ttf")
	var bold_font = load("res://Assets/Fonts/Quantico/Quantico-Bold.ttf")
	
	for entry in scores:
		var username = str(entry.get("username", "Unknown Isotope"))
		var score = int(entry.get("score", 0))
		var timestamp = str(entry.get("timestamp", ""))
		
		# Clean date string from 2026-07-26T08:26:26.000Z or 2026-07-26 08:26:26
		var display_date = timestamp
		if "T" in timestamp:
			var parts = timestamp.split("T")
			var date_part = parts[0]
			var time_part = parts[1].split(".")[0]
			display_date = date_part + " " + time_part
			
		# Create a visual row panel
		var row_panel = Panel.new()
		row_panel.custom_minimum_size = Vector2(0, 48)
		row_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# Set a subtle alternating background color for rows
		var style = StyleBoxFlat.new()
		if rank % 2 == 0:
			style.bg_color = Color(0.14, 0.14, 0.20, 0.6)
		else:
			style.bg_color = Color(0.10, 0.10, 0.15, 0.6)
		
		# Hover outline or border
		style.border_width_left = 4
		if username.to_lower() == LeaderboardManager.player_username.to_lower():
			style.bg_color = Color(0.18, 0.25, 0.18, 0.8) # Highlight active player row in green
			style.border_color = Color(0.3, 0.8, 0.4, 1.0)
		else:
			style.border_color = Color(0.2, 0.2, 0.3, 1.0)
			
		row_panel.add_theme_stylebox_override("panel", style)
		
		# Row layout
		var hbox = HBoxContainer.new()
		hbox.layout_mode = 1
		hbox.anchors_preset = Control.PRESET_FULL_RECT
		hbox.offset_left = 20
		hbox.offset_right = -20
		row_panel.add_child(hbox)
		
		# 1. Rank Label
		var rank_lbl = Label.new()
		rank_lbl.custom_minimum_size = Vector2(80, 0)
		rank_lbl.add_theme_font_override("font", bold_font)
		rank_lbl.add_theme_font_size_override("font_size", 16)
		
		# Format top ranks with symbol
		if rank == 1:
			rank_lbl.text = "🥇 #1"
			rank_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2)) # Gold
		elif rank == 2:
			rank_lbl.text = "🥈 #2"
			rank_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85)) # Silver
		elif rank == 3:
			rank_lbl.text = "🥉 #3"
			rank_lbl.add_theme_color_override("font_color", Color(0.8, 0.55, 0.35)) # Bronze
		else:
			rank_lbl.text = "   #" + str(rank)
			rank_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
			
		rank_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox.add_child(rank_lbl)
		
		# 2. Username Label
		var user_lbl = Label.new()
		user_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		user_lbl.add_theme_font_override("font", bold_font)
		user_lbl.add_theme_font_size_override("font_size", 18)
		user_lbl.text = username
		user_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		if username.to_lower() == LeaderboardManager.player_username.to_lower():
			user_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
		hbox.add_child(user_lbl)
		
		# 3. Score Label
		var score_lbl = Label.new()
		score_lbl.custom_minimum_size = Vector2(160, 0)
		score_lbl.add_theme_font_override("font", bold_font)
		score_lbl.add_theme_font_size_override("font_size", 18)
		score_lbl.text = str(score) + " eV"
		score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		score_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		score_lbl.add_theme_color_override("font_color", Color(0.9, 0.6, 0.1)) # Orange/energy color
		hbox.add_child(score_lbl)
		
		# 4. Timestamp Label
		var date_lbl = Label.new()
		date_lbl.custom_minimum_size = Vector2(200, 0)
		date_lbl.add_theme_font_override("font", regular_font)
		date_lbl.add_theme_font_size_override("font_size", 14)
		date_lbl.text = display_date
		date_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		date_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		date_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		hbox.add_child(date_lbl)
		
		list_container.add_child(row_panel)
		rank += 1
