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
	#handle interact action
	if dialogue_data != null:
		dialogue_box.data = dialogue_data
		#writes global variables to dialoguebox variables dictionary
		dialogue_box.variables.merge(Globals.variables, true)
		dialogue_box.start(start_id)


func _on_dialogue_signal(value) -> void:
	#match value with signal names specific for this NPC
	match(value):
		'play_game' : play_game()
		'give_monitor' : give_monitor()


func give_monitor() -> void:
	PlayerInventory.add_item("Monitor",1)
	Globals.has_monitor = true


func play_game() -> void:
	Globals.player_position = get_parent().get_node("./player").position
	get_tree().change_scene_to_packed(minigame)
