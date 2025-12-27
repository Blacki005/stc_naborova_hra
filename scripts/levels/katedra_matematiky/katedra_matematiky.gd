extends Node2D

@export var default_position : Vector2
@export var camera_limit_bottom : int
@export var camera_limit_left : int
@export var camera_limit_right : int
@export var camera_limit_top : int


func _ready() -> void:
	var player_position = Globals.player_position
	if player_position == null:
		player_position = default_position
	$player.position = player_position
	#o vynulovani player_position se uz stara getter globals


func _on_sumavska_transition_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		get_tree().change_scene_to_file("res://scenes/levels/sumavska/sumavska.tscn")
