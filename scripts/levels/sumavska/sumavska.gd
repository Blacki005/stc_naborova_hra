extends Node2D

var default_position: Vector2 = Vector2(1696,2144)

@export var camera_limit_bottom : int
@export var camera_limit_left : int
@export var camera_limit_right : int
@export var camera_limit_top : int


func _ready() -> void:
	#set player's position:
	var player_position = Globals.last_sumavska_position
	if player_position == null:
		player_position = default_position
	$player.position = player_position


func _on_majorova_kacelar_transition_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		Globals.last_sumavska_position = Vector2(4616,672)
		get_tree().change_scene_to_file("res://scenes/levels/majorova_kancelar/majorova_kancelar.tscn")


func _on_katedra_matematiky_transition_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		Globals.last_sumavska_position = Vector2(3345,590)
		get_tree().change_scene_to_file("res://scenes/levels/katedra_matematiky/katedra_matematiky.tscn")


func _on_katedra_letectva_transition_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		Globals.last_sumavska_position = Vector2(904,1928)
		get_tree().change_scene_to_file("res://scenes/levels/katedra_letectva/katedra_letectva.tscn")


func _on_katedra_informatiky_transition_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		Globals.last_sumavska_position = Vector2(1696,2144)
		get_tree().change_scene_to_file("res://scenes/levels/katedra_informatiky/katedra_informatiky.tscn")


func _on_katedra_zbrani_transition_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		Globals.last_sumavska_position = Vector2(3528,3184)
		get_tree().change_scene_to_file("res://scenes/levels/katedra_zbrani/katedra_zbrani.tscn")


func _on_fvl_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		Globals.last_sumavska_position = Vector2(752,3408)
		get_tree().change_scene_to_file("res://scenes/levels/fvl/fvl.tscn")
