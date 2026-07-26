extends Node

# Autoload singleton for communicating with the leaderboard backend

var player_username: String = ""
var backend_url: String = "https://pb-206.onrender.com" # "http://127.0.0.1:3000"
const REQUEST_TIMEOUT_SECONDS: float = 5.0
const USERNAME_SAVE_PATH: String = "user://player_username.cfg"

func _ready() -> void:
	# Load username from local storage when the game starts
	load_username()

func save_username(username: String) -> bool:
	"""Save username to local storage"""
	if username.strip_edges().is_empty():
		push_warning("Cannot save empty username")
		return false
	
	var config = ConfigFile.new()
	config.set_value("player", "username", username.strip_edges())
	
	var error = config.save(USERNAME_SAVE_PATH)
	if error != OK:
		push_error("Failed to save username to " + USERNAME_SAVE_PATH)
		return false
	
	player_username = username.strip_edges()
	print("Username saved locally: ", player_username)
	return true

func load_username() -> String:
	"""Load username from local storage"""
	var config = ConfigFile.new()
	
	# Check if file exists and load it
	var error = config.load(USERNAME_SAVE_PATH)
	if error != OK:
		# File doesn't exist or couldn't be loaded
		player_username = ""
		return ""
	
	# Try to get the username value
	if config.has_section_key("player", "username"):
		var loaded_username = config.get_value("player", "username", "")
		if loaded_username is String and not loaded_username.strip_edges().is_empty():
			player_username = loaded_username.strip_edges()
			print("Username loaded from local storage: ", player_username)
			return player_username
	
	player_username = ""
	return ""

func clear_username() -> void:
	"""Clear the saved username (for logout/reset)"""
	player_username = ""
	var dir = DirAccess.open("user://")
	if dir and dir.file_exists(USERNAME_SAVE_PATH.replace("user://", "")):
		dir.remove(USERNAME_SAVE_PATH.replace("user://", ""))
		print("Username cleared from local storage")

func _create_http_node() -> HTTPRequest:
	var http = HTTPRequest.new()
	http.timeout = REQUEST_TIMEOUT_SECONDS
	add_child(http)
	return http

func check_username_exists(username: String) -> bool:
	if username.strip_edges().is_empty():
		return false
	
	var http = _create_http_node()
	var url = backend_url + "/check-username/" + username.uri_encode()
	var error = http.request(url)
	
	if error != OK:
		push_warning("Failed to initiate username check (offline or bad URL)")
		http.queue_free()
		return false
		
	var response = await http.request_completed
	var result = response[0]
	var response_code = response[1]
	var body = response[3]
	http.queue_free()
	
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		return false

	var body_string = body.get_string_from_utf8()
	if body_string.is_empty():
		return false

	var json = JSON.parse_string(body_string)
	if json is Dictionary and json.has("exists"):
		return json["exists"]

	return false

func upload_score(score: int) -> bool:
	if player_username.strip_edges().is_empty():
		push_warning("Cannot upload score: player_username is empty")
		return false
		
	var http = _create_http_node()
	var url = backend_url + "/score"
	var headers = ["Content-Type: application/json"]
	
	var payload = {
		"username": player_username,
		"score": score
	}
	var query = JSON.stringify(payload)
	var error = http.request(url, headers, HTTPClient.METHOD_POST, query)
	
	if error != OK:
		push_warning("Failed to initiate score upload request (offline)")
		http.queue_free()
		return false
		
	var response = await http.request_completed
	var result = response[0]
	var response_code = response[1]
	var body = response[3]
	http.queue_free()
	
	if result != HTTPRequest.RESULT_SUCCESS:
		push_warning("Score upload request failed (Network error/Timeout)")
		return false
	
	var body_string = body.get_string_from_utf8()
	var json = JSON.parse_string(body_string) if not body_string.is_empty() else null

	if response_code == 200:
		if json is Dictionary and json.get("success", false):
			print("Score uploaded successfully for name: ", player_username, " Score: ", score)
			return true
	
	var err_msg = "Unknown error"
	if json is Dictionary and json.has("error"):
		err_msg = json["error"]
		
	push_warning("Failed to upload score (HTTP " + str(response_code) + "): " + err_msg)
	return false

func fetch_leaderboard(limit: int = 100) -> Array:
	var http = _create_http_node()
	var url = backend_url + "/leaderboard?limit=" + str(limit)
	var error = http.request(url)
	
	if error != OK:
		push_warning("Failed to initiate leaderboard fetch request (offline)")
		http.queue_free()
		return []
		
	var response = await http.request_completed
	var result = response[0]
	var response_code = response[1]
	var body = response[3]
	http.queue_free()
	
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		push_warning("Leaderboard fetch failed or server unreachable")
		return []
		
	var body_string = body.get_string_from_utf8()
	if body_string.is_empty():
		return []

	var json = JSON.parse_string(body_string)
	if json is Array:
		return json

	return []
