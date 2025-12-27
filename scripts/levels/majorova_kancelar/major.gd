extends StaticBody2D


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
	if dialogue_data != null:
		dialogue_box.data = dialogue_data
		#writes global variables to dialoguebox variables dictionary
		dialogue_box.variables.merge(Globals.variables, true)
		dialogue_box.start(start_id)


func _on_dialogue_signal(value) -> void:
	#match value with signal names specific for this NPC
	match(value):
		'give_computer' : give_computer()


func give_computer() -> void:
	if not Globals.has_computer:
		PlayerInventory.add_item("Computer",1)
		Globals.has_computer = true
