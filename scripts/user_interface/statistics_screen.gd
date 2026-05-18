extends Control

@export var ENEMIES_MAX_CNT : int = 10

@onready var playtime_val = $ColorRect/VBoxContainer/GridContainer/playtime_val
@onready var enemies_killed_val = $ColorRect/VBoxContainer/GridContainer/enemies_killed_val
@onready var damage_taken_val = $ColorRect/VBoxContainer/GridContainer/damage_taken_val
@onready var items_collected_val = $ColorRect/VBoxContainer/GridContainer/items_collected_val
@onready var max_combo_val = $ColorRect/VBoxContainer/GridContainer/max_combo_val
@onready var grade_val = $ColorRect/VBoxContainer/GridContainer/grade_val
@onready var exit_btn = $ColorRect/VBoxContainer/HBoxContainer/exit

func _ready() -> void:
	Globals.stats["items_collected"] = PlayerInventory.get_uniq_inventory_items_cnt()
	var ITEMS_MAX_CNT = JsonData.get_item_cnt()
	if OS.get_name() == "Web":
		exit_btn.hide()
	
	var stats : Dictionary = {
		"playtime" : 0.0,
		"max_combo" : 0,
		"enemies_killed" : 0,
		"items_collected" : 0,
		"damage_taken" : 0,
	}
	
	
	playtime_val.text = str(Globals.stats["playtime"])
	enemies_killed_val.text = str(Globals.stats["enemies_killed"]) + "/" + str(ENEMIES_MAX_CNT)
	damage_taken_val.text = str(Globals.stats["damage_taken"])
	items_collected_val.text = str(Globals.stats["items_collected"]) + "/" + str(ITEMS_MAX_CNT)
	max_combo_val.text = str(Globals.stats["max_combo"])
	grade_val.text = Globals.get_grade()


func _on_main_menu_button_up() -> void:
	get_tree().change_scene_to_file("res://scenes/user_interface/level_menu.tscn")


func _on_exit_button_up() -> void:
	get_tree().quit(0)
