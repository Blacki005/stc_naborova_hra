extends Control


func _on_new_game_button_button_up() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/katedra_informatiky/katedra_informatiky.tscn")


func _on_quit_button_button_up() -> void:
	get_tree().quit()


func _on_choose_character_button_button_up() -> void:
	get_tree().change_scene_to_file("res://scenes/character_chooser.tscn")


func _on_load_button_up() -> void:
	get_tree().change_scene_to_file("res://scenes/load_game_menu.tscn")
