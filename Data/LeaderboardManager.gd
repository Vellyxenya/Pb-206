extends Node

# Autoload singleton for communicating with the leaderboard backend

var player_username: String = ""
var backend_url: String = "http://127.0.0.1:3000"

func check_username_exists(username: String) -> bool:
	if username.strip_edges().is_empty():
		return false
	
	var http = HTTPRequest.new()
	add_child(http)
	
	var url = backend_url + "/check-username/" + username.uri_encode()
	var error = http.request(url)
	if error != OK:
		push_error("Failed to initiate username check request")
		http.queue_free()
		return false
		
	var response = await http.request_completed
	var response_code = response[1]
	var body = response[3]
	http.queue_free()
	
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json is Dictionary and json.has("exists"):
			return json["exists"]
	return false

func upload_score(score: int) -> bool:
	if player_username.strip_edges().is_empty():
		push_warning("Cannot upload score: player_username is empty")
		return false
		
	var http = HTTPRequest.new()
	add_child(http)
	
	var url = backend_url + "/score"
	var headers = ["Content-Type: application/json"]
	var payload = {
		"username": player_username,
		"score": score
	}
	var query = JSON.stringify(payload)
	var error = http.request(url, headers, HTTPClient.METHOD_POST, query)
	if error != OK:
		push_error("Failed to initiate score upload request")
		http.queue_free()
		return false
		
	var response = await http.request_completed
	var response_code = response[1]
	var body = response[3]
	http.queue_free()
	
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json is Dictionary and json.get("success", false):
			print("Score uploaded successfully for name: ", player_username, " Score: ", score)
			return true
	
	var err_msg = "Unknown error"
	if response_code != 0:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json is Dictionary and json.has("error"):
			err_msg = json["error"]
	push_error("Failed to upload score (HTTP " + str(response_code) + "): " + err_msg)
	return false

func fetch_leaderboard(limit: int = 100) -> Array:
	var http = HTTPRequest.new()
	add_child(http)
	
	var url = backend_url + "/leaderboard?limit=" + str(limit)
	var error = http.request(url)
	if error != OK:
		push_error("Failed to initiate leaderboard fetch request")
		http.queue_free()
		return []
		
	var response = await http.request_completed
	var response_code = response[1]
	var body = response[3]
	http.queue_free()
	
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json is Array:
			return json
	return []
