extends Node2D

@onready var gun = $bvp
@onready var target = $target
@onready var label_timer = $soldier/label_timer
@onready var soldier_dialogue = $soldier/soldier_dialogue

@export var gear_nodes: Array[NodePath] = []
@export var add_duration : float = 0.8
@export var add_spawn_offset : Vector2 = Vector2(80, -20)  # where the gear flies in from (relative to its final spot)
@export var add_rotation_deg : float = 360.0               # spin while flying
@export var remove_duration : float = 0.6
@export var remove_offset : Vector2 = Vector2(0, -20)        # slight pop-out when removed

const MAX_SCORE : int = 4

var score : int = 0
var winning_score : int
var shot_hit_target : bool = false

func _ready() -> void:
	winning_score = len(gear_nodes)
	hide_all_gear()
	if target:
		target.connect("hit", _on_target_hit)
	
	#pause tree and display dialogue:
	get_tree().paused = true
	soldier_dialogue.start("START")

func _on_target_hit() -> void:
	shot_hit_target = true

func hide_all_gear() -> void:
	for path in gear_nodes:
		var g : Sprite2D = get_node(path) as Sprite2D
		if g:
			g.visible = false

func update_gear_visibility(prev_score: int) -> void:
	for i : int in range(gear_nodes.size()):
		var g : Sprite2D = get_node(gear_nodes[i]) as Sprite2D
		if g == null:
			continue
		var should_show : bool = i < score
		var was_showing : bool = i < prev_score

		if should_show and not was_showing:
			play_add_anim(g)
		elif not should_show and was_showing:
			play_remove_anim(g)
		else:
			g.visible = should_show
			g.modulate.a = 1.0 if should_show else 0.0

func play_add_anim(g: Sprite2D) -> void:
	g.visible = true
	g.modulate.a = 0.0
	var final_pos : Vector2 = g.position
	var start_pos : Vector2 = final_pos + add_spawn_offset
	g.position = start_pos
	g.rotation = 0.0

	var tw : Tween = create_tween().set_parallel(true)
	tw.tween_property(g, "position", final_pos, add_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(g, "rotation_degrees", add_rotation_deg, add_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(g, "modulate:a", 1.0, add_duration * 0.7)  # fade in slightly faster

func play_remove_anim(g: Sprite2D) -> void:
	var tw : Tween = create_tween().set_parallel(true)
	tw.tween_property(g, "position", g.position + remove_offset, remove_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(g, "modulate:a", 0.0, remove_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.finished.connect(func() -> void:
		g.visible = false
		g.position -= remove_offset  # restore base position for next add
		g.rotation = 0.0)


func _on_child_exiting_tree(node: Node) -> void:
	#projectile is being destroyed:
	if node.is_in_group("projectiles") and score < winning_score:
		var prev_score : int = score
		if shot_hit_target:
			shot_hit_target = false
			#soldier_label.text = "Nice shot."
			soldier_dialogue.start("NICE_SHOT")
			label_timer.start()
			score += 1
		else:
			soldier_dialogue.start("MISS")
			if score > 0:
				score -= 1
		update_gear_visibility(prev_score)
		label_timer.start()



func _on_label_timer_timeout() -> void:
	if score >= winning_score:
		soldier_dialogue.start("GAME_OVER")
		game_over()
	else:
		soldier_dialogue.stop()

func game_over() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	#remove existing projectiles
	for node in get_tree().get_nodes_in_group("projectiles"):
		node.queue_free()
	get_tree().paused = true
	Globals.levels_completed += 1
	Globals.new_level_unlocked = true


func _on_soldier_dialogue_ended() -> void:
	if score < 5:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		get_tree().paused = false
		


func _on_soldier_dialogue_signal(value: String) -> void:
	if value == "game_over":
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/user_interface/level_menu.tscn")
