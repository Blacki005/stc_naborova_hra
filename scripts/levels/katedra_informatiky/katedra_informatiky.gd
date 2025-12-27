extends Node2D

@export var default_position : Vector2
@export var next_scene : PackedScene
@export var camera_limit_bottom : int
@export var camera_limit_left : int
@export var camera_limit_right : int
@export var camera_limit_top : int


func _ready() -> void:
	var camera : Camera2D = get_tree().get_first_node_in_group("player").get_node("./Camera2D")
	if camera == null:
		print("Error: Unable to get camera node!")
		return
	
	#set players position:
	var player_position = Globals.player_position
	if player_position == null:
		player_position = default_position
	$player.position = player_position
	#vynulovat player_position - o to se uz stara getter globals
	
	#set camera limits for current level
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_bottom = -1080
	camera.limit_right = 1920
	
	#enable door according to variable in globals
	if Globals.K209_door_enabled:
		_on_plk_bigo_enable_door()


func _on_sumavska_transition_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		#player entered door
		get_tree().change_scene_to_packed(next_scene)


func _on_plk_bigo_enable_door() -> void:
	$sumavska_transition.show()
	$sumavska_transition/CollisionShape2D.disabled = false
	Globals.K209_door_enabled = true
