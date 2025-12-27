extends StaticBody2D


@export var dialogue_data : DialogueData
@export var texture : Texture
@onready var interaction_area = $interaction_area


func _ready() -> void:
	interaction_area.interact = Callable(self, "_on_interact")
	if texture != null:
		$Sprite2D.texture = texture
	else:
		$Sprite2D.texture = load("res://icon.svg")
		print("Failed to load texture for " + self.name + "!")


func _on_interact() -> void:
	var ui_node = get_tree().get_first_node_in_group("user_interface")
	if dialogue_data != null:
		ui_node.dialogue_box.data = dialogue_data
		ui_node.dialogue_box.start("START")
	else:
		print("Failed to load dialogue for " + self.name + "!")
