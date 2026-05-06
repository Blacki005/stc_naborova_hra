extends Area2D
class_name InteractionArea

@export var action_name: String = "interakce"

var interact: Callable = func():
	pass


func _on_body_entered(_body) -> void:
	InteractionManager.register_area(self)


func _on_body_exited(body) -> void:
	if body.is_in_group("player"):
		var dialogue_box = get_node("../CanvasLayer/DialogueBox")
		if dialogue_box:
			dialogue_box.stop()
	InteractionManager.unregister_area(self)
