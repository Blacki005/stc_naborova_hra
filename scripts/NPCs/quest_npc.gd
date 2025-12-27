extends StaticBody2D


@export var texture : Texture
@export var dialogue_data : DialogueData
@onready var interaction_area = $interaction_area


func _ready() -> void:
	interaction_area.interact = Callable(self, "_on_interact")
	if texture != null:
		$Sprite2D.texture = texture
	else:
		$Sprite2D.texture = load("res://icon.svg")
		print("Failed to load texture for " + self.name + "!")


func _on_interact() -> void:
	#handle interact action
	
	#get ui node
	var ui_node = get_tree().get_first_node_in_group("user_interface")
	
	#display shop with NPCs name
	#ui_node.display_shop(self.name)
	
	#display NPCs dialogue
	if dialogue_data != null:
		ui_node.dialogue_box.data = dialogue_data
		ui_node.dialogue_box.start("START")
	else:
		print("Failed to load dialogue for " + self.name + "!")
	pass
