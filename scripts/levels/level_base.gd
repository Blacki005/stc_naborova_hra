extends Node2D

@export var default_position : Vector2
@export var next_scene : PackedScene
@export var camera_limit_bottom : int = 1080
@export var camera_limit_left : int = 0
@export var camera_limit_right : int = 1920
@export var camera_limit_top : int = 0


func _ready() -> void:
	var camera : Camera2D = get_tree().get_first_node_in_group("player").get_node("./Camera2D")
	if camera == null:
		print("Error: Unable to get camera node!")
		return
	
	#set players position:
	var player_position : Vector2 = Globals.player_position
	if player_position == null:
		player_position = default_position
	$player.position = player_position
