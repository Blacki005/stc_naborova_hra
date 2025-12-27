extends Node
#this scripts serves as a place to store global variables for all NPCs, quests etc.

const MAX_HEALTH : int = 10

#signal to UI that health or bago changed
signal bago_changed
signal health_changed

#chosen character - player loads corresponding head sprite and it sets initial values of other variables
var character : String = "flasar":
	set(value):
		match value:
			"flasar":
				character = value
				variables["character"] = "flasar"
				bago = 5
			"pepa":
				character = value
				variables["character"] = "pepa"
				health = 5
			"micinka999":
				variables["character"] = "micinka999"
				character = value
			_:
				#default, invalid character chosen
				character = "flasar"


#player stats variables:
var bago : int = 0:
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


#all important variables in dictionary, so they can be stored in/loaded from file and/or parsed to dialogue
var variables : Dictionary = {
#levels variables:
	"rekrutacni_pracoviste_completed" : false,

#bago is like currency and is needed in some dialogues
	"bago" : 0,
	"health" : 10,

#define quest items variables:
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

#set window to fullscreen at the beginning
func _ready() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


#resets global variables to initial state
func reset() -> void:
	
	bago = 0
	health = MAX_HEALTH
	player_position = null
	
	#apply character effects again after death
	character = character


func die() -> void:
	reset()
	PlayerInventory.reset_inventory()
	get_tree().change_scene_to_file("res://scenes/death_screen.tscn")


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
