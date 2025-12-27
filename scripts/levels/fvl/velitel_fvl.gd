extends StaticBody2D

@export var texture : Texture #NPC's texture
@export var dialogue_data : DialogueData #dialogue for NPC
@export var start_id : String
@export var minigame : PackedScene #scene for NPCs mingame

@onready var interaction_area = $interaction_area
@onready var dialogue_box = $CanvasLayer/DialogueBox


func _ready() -> void:
	interaction_area.interact = Callable(self, "_on_interact")
	if texture != null:
		$Sprite2D.texture = texture
	else:
		$Sprite2D.texture = load("res://icon.svg")
		print("Failed to load texture for " + self.name + "!")


#gets called when player interacts with NPC
func _on_interact() -> void:
	if dialogue_data != null:
		dialogue_box.data = dialogue_data
		#writes global variables to dialoguebox variables dictionary
		dialogue_box.variables.merge(Globals.variables, true)
		dialogue_box.start(start_id)


#gets called when dialogue emits signal
func _on_dialogue_signal(value) -> void:
	#match value with signal names specific for this NPC
	match(value):
		'play_game' : play_game()
		'give_mouse' : give_mouse()
		'get_bago' : get_bago()


func give_mouse() -> void:
	PlayerInventory.add_item("Mouse",1)
	Globals.has_mouse = true


#exchange bago for Mouse
func get_bago() -> void:
	Globals.bago -= 10
	PlayerInventory.add_item("Mouse",1)
	Globals.has_mouse = true


#run NPC's minigame
func play_game() -> void:
	Globals.player_position = get_tree().get_first_node_in_group("player").position
	get_tree().change_scene_to_packed(minigame)
