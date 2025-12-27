extends Node

@export var pipe_scene : PackedScene

var game_running : bool
var game_over : bool
var scroll : int
var score : int
const SCROLL_SPEED : int = 10 #make game slower or faster
var screen_size : Vector2i
var ground_height : int
var pipes : Array
const PIPE_DELAY : int = 100 #delay so pipe just doesnt randomly appear
const PIPE_RANGE : int = 200 #limit for pipes vertical offset
const REQUIRED_SCORE = 10


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_window().size
	ground_height = $ground.get_node("Sprite2D").texture.get_height()
	new_game()


func new_game() -> void:
	#reset variables, clear existing pipes (from older game)
	get_tree().call_group("pipes", "queue_free")
	game_running = false
	game_over = false
	score = 0
	scroll = 0
	$score_label.text = "SCORE: " + str(score)
	$game_over.hide()
	pipes.clear()
	
	#generate starting pipes
	generate_pipes()
	$grippen.reset()


func _input(event: InputEvent) -> void:
	if not game_over:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				#start new game by clicking
				if game_running == false:
					start_game()
				else:
					#flap
					if $grippen.flying:
						$grippen.flap()
						check_top()


func start_game() -> void:
	game_running = true
	$grippen.flying = true
	$grippen.flap()
	$pipe_timer.start()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if game_running:
		scroll += SCROLL_SPEED
		#reset scroll
		if scroll >= screen_size.x:
			scroll = 0
		#move ground node
		$ground.position.x = -scroll
		#move pipes:
		for pipe in pipes:
			pipe.position.x -= SCROLL_SPEED


func _on_pipe_timer_timeout() -> void:
	generate_pipes()


func generate_pipes() -> void:
	var pipe = pipe_scene.instantiate()
	#pipe delay decides pipes horizontal offset
	pipe.position.x = screen_size.x + PIPE_DELAY
	#pipe range decides pipes vertical offset
	pipe.position.y = (screen_size.y - ground_height) / 2 + randi_range(-PIPE_RANGE, PIPE_RANGE)
	#connect pipes hit signal to register grippen collision and passthrough
	pipe.hit.connect(grippen_hit)
	pipe.scored.connect(scored)
	add_child(pipe)
	pipes.append(pipe)

func scored() -> void:
	score += 1
	$score_label.text = "SKÓRE: " + str(score)


#checks if grippen collided with the ceiling
func check_top() -> void:
	if $grippen.position.y < 0:
		$grippen.falling = true
		stop_game()


func stop_game() -> void:
	$game_over.show()
	$pipe_timer.stop()
	$grippen.flying = false
	game_running = false
	game_over = true
	
	#display endgame message
	if score >= REQUIRED_SCORE:
		Globals.grippen_jump_completed = true
		$game_over/restart_button.disabled = true
		$game_over/restart_button.hide()
		
		$game_over/Label.text = "Vyhráváte modrý baret!\nskóre: " + str(score)
	else:
		$game_over/Label.text = "Snad jsi lepší kybernetik než pilot!\nskóre: " + str(score)


func grippen_hit() -> void:
	$grippen.falling = true
	stop_game()


func _on_ground_hit() -> void:
	$grippen.falling = false
	stop_game()
