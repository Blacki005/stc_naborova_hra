extends Control


func _on_pepa_button_up() -> void:
	Globals.character = "pepa"
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_flasar_button_up() -> void:
	Globals.character = "flasar"
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_micinka_999_button_button_up() -> void:
	Globals.character = "micinka999"
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
