extends Node
#this scripts serves as a place to store global variables for all NPCs, quests etc.

const MAX_HEALTH : int = 10
const INITIAL_BAGO : int = 0
const LEVELS_CNT : int = 5
const MAX_SHIELD : int = 10
const INITIAL_SHIELD : int = 0

# Signals used for cross-node communication
signal screen_shake_requested(strength: float, duration: float)
signal enemy_hit(position: Vector2)

const SERVER_URL : String = "localhost"
const HTTP_PORT : String = "8080"
const HTTPS_PORT : String = "8443"

#signal to UI that health or bago changed
signal bago_changed
signal health_changed
signal shield_changed

#player stats variables:
var bago : int = INITIAL_BAGO:
	set(value):
		bago = value
		variables["bago"] = value
		emit_signal("bago_changed")
var health : int = MAX_HEALTH:
	set(value):
		health = value
		variables["health"] = value
		if(health > MAX_HEALTH):
			health = MAX_HEALTH
		if(health <= 0):
			die()
		emit_signal("health_changed")
var shield : int = INITIAL_SHIELD:
	set(value):
		shield = value
		variables["shield"] = value
		if(shield > MAX_SHIELD):
			shield = MAX_SHIELD
		emit_signal("shield_changed")

#variable for playing unlocking animation in level menu:
var new_level_unlocked : bool = false
var levels_completed : int = 0:
	set(value):
		if value > LEVELS_CNT:
			return
		else:
			levels_completed = value

#TODO: new level completing mechanism for data collecting
var cnt_levels_played : Dictionary = {
	"level_1" : 0,
	"level_2" : 0,
	"level_3" : 0,
	"level_4" : 0,
	"level_5" : 0
}

var cnt_levels_completed : Dictionary = {
	
}

#all important variables in dictionary, so they can be stored in/loaded from file and/or parsed to dialogue
var variables : Dictionary = {
#bago is like currency and is needed in some dialogues
	"bago" : INITIAL_BAGO,
	"health" : 10,
	"shield" : 0,

#define quest items variables:
	"has_hospital_key" : false,
	"has_injection" : false,
	"march_completed" : false
}

#==============================
#===== position variables =====
#==============================

var player_position:
	get():
		#null value every time it's used
		var pos = player_position
		player_position = null
		return pos

#variable that makes sure player doesn't unintentionally fire when clicking on inventory node
var able_to_attack : bool = true

# ─── Stats tracking ────────────────────────────────────────────
var stats : Dictionary = {
	"playtime" : 0.0,
	"max_combo" : 0,
	"enemies_killed" : 0,
	"items_collected" : 0,
	"damage_taken" : 0,
}

var is_in_gameplay: bool = false

func _process(delta: float) -> void:
	# Only count playtime when in a gameplay scene (not menus) and not paused
	if is_in_gameplay and not get_tree().paused:
		stats["playtime"] += delta

func reset_stats() -> void:
	stats = {
		"playtime" : 0.0,
		"max_combo" : 0,
		"enemies_killed" : 0,
		"items_collected" : 0,
		"damage_taken" : 0,
	}

## Returns a grade dictionary: { "grade": "S", "score": 85, "breakdown": {...} }
func get_grade() -> String:
	# Individual stat scores (0-100 each)
	var combo_score : float = minf(stats["max_combo"] * 10.0, 100.0)
	var kills_score : float = minf(stats["enemies_killed"] * (100.0 / 9.0), 100.0)
	var items_score : float = minf(stats["items_collected"] * 10.0, 100.0)
	# Damage penalty: 0 damage = 100, losing all 10 HP = 0
	var damage_score : float = maxf(100.0 - stats["damage_taken"] * 10.0, 0.0)
	# Time score: full marks under 120s, drops to 0 by 600s
	var time_score : float = clampf(100.0 - (stats["playtime"] - 120.0) * (100.0 / 480.0), 0.0, 100.0)

	var total : float = (combo_score + kills_score + items_score + damage_score + time_score) / 5.0

	var grade : String
	if total >= 90.0:
		grade = "S"
	elif total >= 75.0:
		grade = "A"
	elif total >= 55.0:
		grade = "B"
	elif total >= 35.0:
		grade = "C"
	else:
		grade = "D"

	return grade

# Fade overlay for scene transitions (death screen)
var _is_dying := false
var _fade_canvas_layer: CanvasLayer = null
var _fade_color_rect: ColorRect = null


var http_request: HTTPRequest

var volume : int = 100: #% of max volume
	set(value):
		volume = clampi(value, 0, 100)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(volume / 100.0))

#set window to fullscreen at the beginning
func _ready() -> void:
	PlayerInventory.connect("inventory_updated", _on_inventory_updated)
	
	#add http request node
	http_request = HTTPRequest.new()
	add_child(http_request)
	
	#send data about user to server
	get_user_fingerprint()
	
	#prevent clipping viewport:
	#DisplayServer.window_set_min_size()
	DisplayServer.window_set_min_size(Vector2i(1920, 1080))
	#DisplayServer.window_set_max_size()

func _on_inventory_updated() -> void:
	if PlayerInventory.has_item("Key"):
		variables["has_hospital_key"] = true
	if PlayerInventory.has_item("Injection"):
		variables["has_injection"] = true


func send_data(address: String, data: Dictionary) -> void:
	var json_string : String = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]
	http_request.request(address, headers, HTTPClient.METHOD_POST, json_string)


#resets global variables to initial state
func reset() -> void:
	bago = 0
	health = MAX_HEALTH
	player_position = null
	_is_dying = false
	is_in_gameplay = false
	reset_stats()

func die() -> void:
	if _is_dying:
		return
	_is_dying = true
	
	# Play death sound
	var death_audio = AudioStreamPlayer.new()
	death_audio.stream = load("res://sound/player/death.mp3")
	death_audio.bus = "Master"
	add_child(death_audio)
	death_audio.play()

	# Create a full-screen black overlay on a high CanvasLayer
	_fade_canvas_layer = CanvasLayer.new()
	_fade_canvas_layer.layer = 100
	add_child(_fade_canvas_layer)
	
	_fade_color_rect = ColorRect.new()
	_fade_color_rect.color = Color(0, 0, 0, 0)
	_fade_color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	_fade_color_rect.anchor_left = 0.0
	_fade_color_rect.anchor_top = 0.0
	_fade_color_rect.anchor_right = 1.0
	_fade_color_rect.anchor_bottom = 1.0
	_fade_canvas_layer.add_child(_fade_color_rect)
	
	# Fade out to black, then switch to death screen
	var tween = create_tween()
	tween.tween_property(_fade_color_rect, "color:a", 1.0, 0.5)
	tween.tween_callback(func():
		_is_dying = false
		get_tree().change_scene_to_file("res://scenes/user_interface/death_screen.tscn")
	)

func fade_in(duration: float = 0.5) -> void:
	if _fade_color_rect == null:
		return
	_fade_color_rect.color.a = 1.0
	var tween = create_tween()
	tween.tween_property(_fade_color_rect, "color:a", 0.0, duration)
	tween.tween_callback(func():
		if _fade_canvas_layer:
			_fade_canvas_layer.queue_free()
			_fade_canvas_layer = null
			_fade_color_rect = null
	)

func get_public_ip() -> String:
	var err : Error = http_request.request("https://api.ipify.org")
	if err != OK:
		printerr("Request error: " + str(err))
		return ""

	var result = await http_request.request_completed

	var response_code = result[1]
	var body = result[3]

	if response_code != 200:
		printerr("Failed to get IP: " + str(response_code))
		return ""

	return body.get_string_from_utf8().strip_edges()


func get_server_url() -> String:
	if OS.has_feature("web"):
		return "https://"+SERVER_URL+":"+HTTPS_PORT+"/data"
	else:
		return "http://"+SERVER_URL+":"+HTTP_PORT+"/data"

#get user's fingerprint to send to db
func get_user_fingerprint() -> void:
	var fingerprint : Dictionary = {}
	
	# Network
	# Get local IPs
	var ips: Array = IP.get_local_addresses()
	# Get public IP
	var public_ip = await get_public_ip()
	if public_ip != "":
	# Avoid duplicates just in case
		if not ips.has(public_ip):
			ips.push_front(public_ip)
	fingerprint["ip_addresses"] = ips

	# OS info
	fingerprint["os_name"] = OS.get_name()
	fingerprint["os_version"] = OS.get_version()
	fingerprint["os_locale"] = OS.get_locale()
	fingerprint["model_name"] = OS.get_model_name()
	fingerprint["processor_name"] = OS.get_processor_name()
	fingerprint["processor_count"] = OS.get_processor_count()
	
	# Platform features
	fingerprint["is_web"] = OS.has_feature("web")
	fingerprint["is_windows"] = OS.has_feature("windows")
	fingerprint["is_linux"] = OS.has_feature("linux")
	fingerprint["is_macos"] = OS.has_feature("macos")
	fingerprint["is_mobile"] = OS.has_feature("mobile")
	
	# Screen
	fingerprint["screen_size"] = {
		"width": DisplayServer.screen_get_size().x,
		"height": DisplayServer.screen_get_size().y
	}
	fingerprint["screen_dpi"] = DisplayServer.screen_get_dpi()
	
	# Web-specific via JavaScript
	if OS.has_feature("web"):
		fingerprint["user_agent"] = JavaScriptBridge.eval("navigator.userAgent")
		fingerprint["browser_language"] = JavaScriptBridge.eval("navigator.language")
		fingerprint["browser_platform"] = JavaScriptBridge.eval("navigator.platform")
		fingerprint["screen_color_depth"] = JavaScriptBridge.eval("screen.colorDepth")
		fingerprint["timezone"] = JavaScriptBridge.eval("Intl.DateTimeFormat().resolvedOptions().timeZone")
	
	# Environment variables (desktop only, empty on web)
	var env_keys = ["HOME", "USER", "USERNAME", "COMPUTERNAME", "OS"]
	for key in env_keys:
		var val = OS.get_environment(key)
		if val != "":
			fingerprint["env_" + key.to_lower()] = val
	
	# Unique hash of all collected data
	fingerprint["fingerprint_hash"] = str(fingerprint).hash()
	
	
	var json_string = JSON.stringify(fingerprint)
	var headers = ["Content-Type: application/json"]
	http_request.request(get_server_url(), headers, HTTPClient.METHOD_POST, json_string)

#	send_data("https://192.168.0.111:8443/data", fingerprint)

#creates save file and stores global variables in it
#file is changed as read only and cannot be edited by user via file explorer
#files can be browsed via load menu
func save_game(filename : String) -> String:
	var file
	var os_name = OS.get_name()
	
	##path formats differ in Windows and Linux
	#if os_name == "Windows":
		##open current directory and check if the opening was successful
		#var dir = DirAccess.open(".\\")
		#if dir == null:
			#printerr("Failed to open directory .\\!")
			#return ""
		#
		##create directory for saves if it doesn't exist and open it
		#if not dir.dir_exists(".\\saves"):
			#if dir.make_dir(".\\saves") != OK:
				#printerr("Failed to make directory .\\saves!")
				#return ""
		#dir = DirAccess.open(".\\saves")
		#if dir == null:
			#printerr("Failed to open directory .\\saves even though it exists!")
			#return ""
		#
		##generate save name if the user didn't pass any according to number of saves in saves directory
		#if filename == "":
			#var save_index = len(dir.get_files()) + 1
			#filename = "save" + str(save_index)
		#
		#var file_path = ".\\saves\\" + filename + ".json"
		#file = FileAccess.open(file_path, FileAccess.WRITE)
		#if file == null:
			#printerr("Failed to open file " + file_path + " for writing!")
			#return ""
		#if FileAccess.set_read_only_attribute(file_path,true) != OK:
			#printerr("Failed to set read-only attribute of file " + file_path + "!")
	#elif os_name == "Linux":
		##open current directory and check if the opening was successful
		#var dir = DirAccess.open("./")
		#if dir == null:
			#printerr("Failed to open directory ./!")
			#return ""
		#
		##create directory for saves if it doesn't exist and open it
		#if not dir.dir_exists("./saves"):
			#if dir.make_dir("./saves") != OK:
				#printerr("Failed to make directory ./saves!")
				#return ""
		#dir = DirAccess.open("./saves")
		#if dir == null:
			#printerr("Failed to open directory ./saves even though it exists!")
			#return ""
		#
		##generate save name if the user didn't pass any according to number of saves in saves directory
		#if filename == "":
			#var save_index = len(dir.get_files()) + 1
			#filename = "save" + str(save_index)
		#
		#var file_path = "./saves/" + filename + ".json"
		#file = FileAccess.open(file_path, FileAccess.WRITE)
		#if file == null:
			#printerr("Failed to open file " + file_path + " for writing!")
			#return ""
		#if FileAccess.set_read_only_attribute(file_path,true) != OK:
			#printerr("Failed to set read-only attribute of file " + file_path + "!")
		#if FileAccess.set_unix_permissions(file_path, 256+32+4) != OK:
			#printerr("Failed to set read-only access for file " + file_path)
	#else:
		##unsupported OS
		#printerr("Saving files on this OS is not supported!")
		#return ""
	
#open current directory and check if the opening was successful
	#var dir = DirAccess.open("user://saves/")
	

	var file_path = "user://saves/" + filename + ".json"
	file = FileAccess.open(file_path, FileAccess.WRITE)
	
	#store current state of variables to the save file
	file.store_string(str(variables))
	return filename
