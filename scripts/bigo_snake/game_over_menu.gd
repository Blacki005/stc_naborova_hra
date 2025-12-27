extends CanvasLayer

signal restart

func _on_restart_button_pressed() -> void:
	emit_signal("restart")


func _on_exit_button_button_up() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/levels/fvl/fvl.tscn")
