extends StaticBody2D

@export var texture : Texture #NPC's texture
@export var dialogue_data : DialogueData #dialogue for NPC
@export var start_id : String
@export var minigame : PackedScene #scene for NPCs mingame

@onready var interaction_area = $interaction_area
@onready var dialogue_box = $CanvasLayer/DialogueBox

signal enable_door


func _ready() -> void:
	interaction_area.interact = Callable(self, "_on_interact")
	if texture != null:
		$Sprite2D.texture = texture
	else:
		$Sprite2D.texture = load("res://icon.svg")
		print("Failed to load texture for " + self.name + "!")
	
	if not Globals.K209_door_enabled:
		$CanvasLayer/DialogueBubble.start("START")


func _on_interact() -> void:
	#set right dialogue data
	if !Globals.K209_door_enabled:
		start_id = "GAMESTART"
	else:
		start_id = "GAMEEND"
	
	#display dialogue and merge globals
	if dialogue_data != null:
		dialogue_box.data = dialogue_data
		#writes global variables to dialoguebox variables dictionary
		dialogue_box.variables.merge(Globals.variables, true)
		dialogue_box.start(start_id)


func _on_dialogue_signal(value) -> void:
	match value:
		'enable_door':
			emit_signal("enable_door")
		'run_program':
			get_tree().change_scene_to_file("res://scenes/end_cutscene.tscn")
