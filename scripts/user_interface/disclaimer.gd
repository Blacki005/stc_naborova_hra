extends Control

@onready var anim_player = $AnimationPlayer

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	get_tree().change_scene_to_file("res://scenes/user_interface/start_screen.tscn")


func _on_timer_timeout() -> void:
	anim_player.play("fade_out")
