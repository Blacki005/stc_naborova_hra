extends Area2D
class_name InteractionArea

@export var action_name: String = "interakce"

var interact: Callable = func():
	pass


func _on_body_entered(_body) -> void:
	InteractionManager.register_area(self)


func _on_body_exited(body) -> void:
	if body.is_in_group("player"):
		# Stop dialogue if playing
		var dialogue_box = get_node_or_null("../CanvasLayer/MarginContainer/DialogueBox")
		if dialogue_box:
			dialogue_box.stop()
		# Close shop if open
		var ui = get_tree().get_first_node_in_group("user_interface")
		if ui and ui.shop.visible:
			ui.shop.close()
	InteractionManager.unregister_area(self)
