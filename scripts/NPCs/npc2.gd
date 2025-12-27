extends StaticBody2D
#all NPCs were created from this file, but it isnt directly assigned to any

@export var texture : Texture
@export var dialogue_data : DialogueData
@export var start_id : String
@export var minigame : PackedScene

@onready var interaction_area = $interaction_area
@onready var dialogue_box = $CanvasLayer/DialogueBox


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
	#var ui_node = get_tree().get_first_node_in_group("user_interface")
	
	#display shop with NPCs name
	#ui_node.display_shop(self.name)
	
	#display NPCs dialogue
	
	if dialogue_data != null:
		dialogue_box.data = dialogue_data
		#writes global variables to dialoguebox variables dictionary
		dialogue_box.variables.merge(Globals.variables, true)
		dialogue_box.start(start_id)


func _on_dialogue_signal(value) -> void:
	#match value with signal names specific for this NPC
	match(value):
		'give_item' : give_item()


func give_item() -> void:
	PlayerInventory.add_item("Monitor",1)
