extends Control


func _on_main_menu_button_button_up() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_exit_button_button_up() -> void:
	get_tree().quit()
