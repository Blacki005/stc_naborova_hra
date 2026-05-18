extends Node2D

@onready var path = $racing_path
@onready var path_follow = $racing_path/PathFollow2D
@onready var score_label = $user_interface/score_label
@onready var start_timer = $start_timer
@onready var start_label = $user_interface/start_label
@onready var bot1 = $bot_racer_1
@onready var bot2 = $bot_racer_2
@onready var dialogue_box = $user_interface/DialogueBox
@onready var initial_player_position = $player.global_position
@onready var initial_player_rotation = $player.rotation
@onready var anim_player = $anim_player
@onready var end_buttons = $user_interface/HBoxContainer
@onready var bot1_init_pos = $bot_racer_1.global_position
@onready var bot2_init_pos = $bot_racer_2.global_position
@onready var player = $player
@onready var bot_init_rot = $bot_racer_1.rotation

@export var lap_count : int = 3

var lap:int = 1
var bot1_score = 1
var bot2_score = 1
var start_countdown: int

func _ready():
	Globals.is_in_gameplay = true
	player.set_physics_process(false)
	get_tree().paused = true
	dialogue_box.start("START")
	start_countdown = 3
	start_label.text = str(start_countdown)

func get_path_direction(pos):
	#get closest point on path2D to the agent
	var offset = path.curve.get_closest_offset(pos)
	path_follow.progress = offset
	#vraci bod o trochu posonuty dopredu oproti tomu, ktery je na path2D nejbliz
	#problem = tohle vraci smer cesty, ne cestu samotnou - nesnazi se na ni vratit
	return path_follow.transform.x


func _on_finish_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		#check if player crossed finish line forward:
		var velocity = body.velocity
		if velocity.y > 0:
			start_label.text = "Podvádět se nemá, fuj!"
			start_label.show()
			body.global_position = initial_player_position
			body.rotation = initial_player_rotation
			body.velocity = Vector2.ZERO
			await get_tree().create_timer(2.0).timeout
			start_label.hide()
		else:
			lap += 1
			if lap == lap_count:
				score_label.text = "Poslední kolo!"
			else:
				score_label.text = "Kolo: "+ str(lap)
		if lap > lap_count:
			race_finished()
	elif body == bot1:
		bot1_score += 1
	elif body == bot2:
		bot2_score += 1
	
	if bot1_score > lap_count || bot2_score > lap_count:
		game_over()

func game_over() -> void:
	stop_audio()
	get_tree().paused = true
	player.set_physics_process(false)
	anim_player.play("fade_out")
	start_label.text = "Prohrál jsi, zkus to rychleji."
	end_buttons.show()
	

func race_finished() -> void:
	score_label.hide()
	
	get_tree().paused = true
	player.set_physics_process(false)
	Globals.new_level_unlocked = true
	Globals.levels_completed += 1
	anim_player.play("fade_out")
	stop_audio()
	start_label.text = "Dobrá práce, přemýšlel jsi o F1?"
	end_buttons.show()

func stop_audio() -> void:
	$AudioStreamPlayer.stop()
	$car_noise_player.stop()
	player.audio_player.stop()


func start_race() -> void:
	var start_beep_player : AudioStreamPlayer = AudioStreamPlayer.new()
	start_beep_player.stream = load("res://sound/levels/prijmacky/car_starting.mp3")
	start_beep_player.bus = "Master"
	start_beep_player.volume_linear = 0.4
	add_child(start_beep_player)
	start_beep_player.play()
	start_beep_player.finished.connect(start_beep_player.queue_free)
	
	score_label.text = "Kolo: 1"
	start_label.show()
	score_label.show()
	start_timer.start()

func _on_start_timer_timeout() -> void:
	start_countdown -= 1
	start_label.text = str(start_countdown)
	if !start_countdown:
		start_timer.stop()
		get_tree().paused = false
		player.set_physics_process(true)
		start_label.hide()
		$car_noise_player.play()


func _on_dialogue_signal(value: String) -> void:
	if value == "start_race":
		start_race()


func _on_exit_button_button_up() -> void:
	#reset the pause invoked at crossing the finish line
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/user_interface/level_menu.tscn")


func _on_restart_button_button_up() -> void:
	$CanvasModulate.hide()
	end_buttons.hide()
	lap = 0
	start_countdown = 3
	bot1_score = 0
	bot2_score = 0
	start_label.text = str(start_countdown)
	player.global_position = initial_player_position
	player.rotation = initial_player_rotation
	bot1.global_position = bot1_init_pos
	bot1.rotation = bot_init_rot
	bot2.rotation = bot_init_rot
	bot2.global_position = bot2_init_pos
	start_race()
