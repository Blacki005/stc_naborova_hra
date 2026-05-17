extends Control

const BPM : int = 55 #bpm pochodu na zacatku
const NEEDED_STEPS : int = 132 #CORRECT BEATS OF SONG

@onready var audio_stream_player = $AudioStreamPlayer
@export var tolerance : int #how many steps can player miss

@onready var game_over_message = $game_over_menu/VBoxContainer/game_over_message
@onready var bpm_label = $VBoxContainer/bpm_label
@onready var progress_bar = $VBoxContainer/ProgressBar

#to count steps done by player
var steps : int = 0
var game_won : bool = false

enum {
	VICTORY=0,
	WRONG_STEP_CNT=1,
	IDLE_TIMEOUT=2
}

func _ready() -> void:
	start_game()


func start_game() -> void:
	bpm_label.text = "KROKY: 0"
	$game_over_menu.hide()
	progress_bar.value = 0
	$idle_timer.start(3)
	$soldiers.position.x = 1320
	steps = 0
	audio_stream_player.play()


#make step, reset idle timer, move soldiers and play animation
func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("salute"): #spacebar
		#reset timer
		$idle_timer.stop()
		$idle_timer.start(3)
		steps += 1
		bpm_label.text = "KROKY: " + str(steps)
		progress_bar.value = steps
		$soldiers.play("default")
		$soldiers.position.x -= 5


func _on_audio_stream_player_finished() -> void:
	if (NEEDED_STEPS - tolerance <= steps && steps <= NEEDED_STEPS + tolerance):
		game_won = true
		game_over(VICTORY)
	else:
		game_won = false
		game_over(WRONG_STEP_CNT)

func game_over(status:int) -> void:
	$idle_timer.stop()
	
	if status==VICTORY:
		game_over_message.text = "Gratuluji, jsi hvězdou úterního nástupu!"
	elif status==IDLE_TIMEOUT:
		game_over_message.text = "Kdybys místo stání na místě pochodoval, plakaly by rodiny dojetím a ne hanbou. Zkus to znovu!"
	else:
		game_over_message.text = "No, tak to to půjdeš ještě jednou!\nSprávný počet kroků: " + str(NEEDED_STEPS) + "\nTvůj počet kroků: " + str(steps)
	$game_over_menu.show()

func _on_restart_button_button_up() -> void:
	start_game()


func _on_exit_button_button_up() -> void:
	if game_won:
		Globals.variables["march_completed"] = true
	get_tree().change_scene_to_file("res://scenes/levels/prisaha/prisaha.tscn")


func _on_idle_timer_timeout() -> void:
	#player didnt step for too long and thus lost
	audio_stream_player.stop()
	game_over(IDLE_TIMEOUT)
