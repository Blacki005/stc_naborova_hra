extends Control

var saves : Array = [] #array storing filenames of all saves in saves directory
var i = 0
var warning_displayed : bool = false


#decide OS and accroding to OS load files from ./saves directory
func _ready() -> void:
	var dir
	var os_name = OS.get_name()
	if os_name == "Windows":
		dir = DirAccess.open(".\\")
		if dir == null:
			display_saves("Nepodařilo se otevřít adresář .\\saves!")
		
		if dir.dir_exists(".\\saves"):
			dir = DirAccess.open(".\\saves")
			if dir == null:
				display_saves("Nepodařilo se otevřít adresář .\\saves!")
			else:
				saves = dir.get_files()
		else:
			display_saves("Nebyl nalezen adresář .\\saves!")
	elif os_name == "Linux":
		dir = DirAccess.open("./")
		if dir == null:
			display_saves("Nepodařilo se otevřít adresář ./saves!")
		
		if dir.dir_exists("./saves"):
			dir = DirAccess.open("./saves")
			if dir == null:
				display_saves("Nepodařilo se otevřít adresář ./saves!")
			else:
				saves = dir.get_files()
		else:
			display_saves("Nebyl nalezen adresář .\\saves!")
	else:
		display_saves("Na tomto OS není podporované ukládání souborů!")
	
	display_saves("V adresáři ./saves/ nebyly nalezeny žádné uložené hry!")


#display saves according to their count or display given error message
func display_saves(err_message : String) -> void:
	if len(saves) == 0:
		#hide buttons where there are no saves and display error message
		$next.hide()
		$previous.hide()
		$load.hide()
		$delete.hide()
		$save_name.text = err_message
		return
	elif len(saves) == 1:
		#hide next and previous when there is only one save
		$next.hide()
		$previous.hide()
	#display first save's name
	$save_name.text = saves[0].substr(0,len(saves[0]) - 5)


#load variables from given save
func _on_load_button_up() -> void:
	var os_name = OS.get_name()
	var saved_variables
	if os_name == "Windows":
		var file = FileAccess.open(".\\saves\\" + $save_name.text + ".json", FileAccess.READ)
		if file == null:
			printerr("Error opening file .\\saves\\" + $save_name.text + ".json")
			return
		saved_variables = JSON.parse_string(file.get_as_text())
		if saved_variables == null:
			printerr("Invalid save file!")
			return
	elif os_name == "Linux":
		var file = FileAccess.open("./saves/" + $save_name.text + ".json", FileAccess.READ)
		if file == null:
			printerr("Error opening file ./saves/" + $save_name.text + ".json")
			return
		saved_variables = JSON.parse_string(file.get_as_text())
		if saved_variables == null:
			printerr("Invalid save file!")
			return
	else:
		$save_name.text = "Na tomto OS není podporované ukládání souborů!"
		return
	
	#decide if the file contains all important keys
	var keys : Array = ["bigo_snake_completed", "grippen_jump_completed", "slavnostni_pochod_completed", "target_range_played", "bago", "health",
	"has_computer", "has_monitor", "has_mouse", "has_keyboard", "character", "K209_door_enabled", "math_bago_given"]
	for key in keys:
		if saved_variables.has(key) == null:
			printerr("Corrupted file")
			return
	
	Globals.bigo_snake_completed = saved_variables["bigo_snake_completed"]
	Globals.grippen_jump_completed=saved_variables["grippen_jump_completed"]
	Globals.slavnostni_pochod_completed=saved_variables["slavnostni_pochod_completed"]
	Globals.target_range_played=saved_variables["target_range_played"]
	Globals.bago=saved_variables["bago"]
	Globals.health=saved_variables["health"]
	Globals.has_computer=saved_variables["has_computer"]
	Globals.has_monitor=saved_variables["has_monitor"]
	Globals.has_mouse=saved_variables["has_mouse"]
	Globals.has_keyboard=saved_variables["has_keyboard"]
	Globals.character=saved_variables["character"]
	Globals.K209_door_enabled=saved_variables["K209_door_enabled"]
	Globals.math_bago_given=saved_variables["math_bago_given"]
	
	#load sumavska with given arguments
	get_tree().change_scene_to_file("res://scenes/levels/katedra_informatiky/katedra_informatiky.tscn")


#cyclic buffer
func _on_previous_button_up() -> void:
	i -= 1
	i = i % len(saves)
	#display save name without the .json ending
	$save_name.text = saves[i].substr(0,len(saves[i])-5)


func _on_next_button_up() -> void:
	i += 1
	i = i % len(saves)
	$save_name.text = saves[i].substr(0,len(saves[i])-5)


func _on_main_menu_button_up() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_delete_button_up() -> void:
	#display warning on first click, delete on confirmation
	if not warning_displayed:
		warning_displayed = true
		$delete.text = "Vopravdu?"
		return
	
	var os_name = OS.get_name()
	var dir
	if os_name == "Linux":
		dir = DirAccess.open("./saves")
	elif os_name == "Windows":
		dir = DirAccess.open(".\\saves")
	if dir != null:
		dir.remove($save_name.text + ".json")
	else:
		$save_name.text = "Chyba při otevírání adresáře saves!"
	
	#reset warning variable
	warning_displayed = false
	$delete.text = "Já tenhle save už nechci!"
	#init again, files changed:
	_ready()
