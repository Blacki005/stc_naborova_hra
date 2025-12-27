extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AnimationPlayer.play("blend_in")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "blend_in":
		$AnimatedSprite2D.play()
	else:
		$Label.show()


func _on_animated_sprite_2d_animation_finished() -> void:
	$AnimationPlayer.play("blend_out")


func _on_button_button_up() -> void:
	PlayerInventory.reset_inventory()
	Globals.reset()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
