extends StaticBody2D

@export var texture : Texture #NPC's texture
@export var dialogue_data : DialogueData #dialogue for NPC
@export var start_id : String = "START" #scene for NPCs mingame
@export var minigame : PackedScene
@export var item : String
@export var item_quantity : int = 1
@export var next_scene : PackedScene
@export var death_effect : PackedScene
@export var shop_name : String = self.name
@export var action_name : String

@onready var interaction_area = $interaction_area
@onready var dialogue_box = $CanvasLayer/DialogueBox

func _ready() -> void:
	if action_name:
		interaction_area.action_name = action_name
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
		InteractionManager.can_interact = false
		dialogue_box.data = dialogue_data
		#writes global variables to dialoguebox variables dictionary
		dialogue_box.variables.merge(Globals.variables, true)
		dialogue_box.start(start_id)


func _on_dialogue_signal(value : String) -> void:
	#match value with signal names specific for this NPC
	match(value):
		'play_game' : play_game()
		'level_finished' : level_finished()
		'give_item' : give_item()
		'die' : die()
		'display_shop' : display_shop()

func display_shop() -> void:
	#get ui node
	var ui_node = get_tree().get_first_node_in_group("user_interface")
	if !ui_node:
		printerr("Unable to get user interface node!")
		return
	
	#display shop with NPCs name
	ui_node.display_shop(shop_name)


func give_item() -> void:
	if item == "bago":
		Globals.bago += item_quantity
		return
	if item and item_quantity > 0:
		var result = PlayerInventory.add_item(item, item_quantity)

func play_game() -> void:
	#variables are stored in dictionary
	#values of variables are not stored when dialogue is freed, so maybe load them from file or globals script every time
	
	#run slavnostni pochod scene
	#slavnostni pochod scene sets global variable completed
	#store player global position"res://scenes/entity/npc_base.tscn" before transition
	Globals.player_position = get_tree().get_first_node_in_group("player").position
	get_tree().change_scene_to_packed(minigame)

func level_finished() -> void:
	#increment completed levels counter:
	Globals.levels_completed += 1
	Globals.new_level_unlocked = true
	get_tree().change_scene_to_packed(next_scene)


func _on_dialogue_box_mouse_entered() -> void:
	Globals.able_to_attack=false


func _on_dialogue_box_mouse_exited() -> void:
	Globals.able_to_attack=true

func die() -> void:
	if death_effect:
		var death_effect_node = death_effect.instantiate()
		get_parent().add_child(death_effect_node)
		death_effect_node.global_position = self.global_position
		queue_free()


func _on_dialogue_started(_id: String) -> void:
	pass
	#InteractionManager.can_interact = false


func _on_dialogue_ended() -> void:
	InteractionManager.can_interact = true
