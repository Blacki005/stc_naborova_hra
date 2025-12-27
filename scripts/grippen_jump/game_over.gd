extends CanvasLayer

signal restart
signal exit


func _on_restart_button_pressed() -> void:
	emit_signal("restart")


func _on_exit_button_button_up() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/katedra_letectva/katedra_letectva.tscn")
