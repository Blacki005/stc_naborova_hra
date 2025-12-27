extends StaticBody2D

@export var texture : Texture #NPC's texture
@export var dialogue_data : DialogueData #dialogue for NPC
@export var start_id : String #scene for NPCs mingame
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
		'play_game' : play_game()


func play_game() -> void:
	#variables are stored in dictionary
	#values of variables are not stored when dialogue is freed, so maybe load them from file or globals script every time
	
	#run slavnostni pochod scene
	#slavnostni pochod scene sets global variable completed
	#store player global position before transition
	Globals.player_position = get_tree().get_first_node_in_group("player").position
	get_tree().change_scene_to_packed(minigame)


func _on_dialogue_box_mouse_entered() -> void:
	Globals.able_to_attack=false


func _on_dialogue_box_mouse_exited() -> void:
	Globals.able_to_attack=true
