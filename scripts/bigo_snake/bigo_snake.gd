extends Node

@export var snake_scene : PackedScene

var score: int
var game_started : bool = false

#grid variables
#cell is 40 pixels, game is 1920x1080 so one row is 46 columns and there are 25 rows
var cells : int = 760
var cell_size : int = 40

#snake variables
var old_data : Array
var snake_data : Array
var snake : Array

#movement variables
var start_pos = Vector2(9,9)
var up = Vector2(0,-1)
var down = Vector2(0,1)
var left = Vector2(-1,0)
var right = Vector2(1,0)
var move_direction : Vector2
var can_move: bool

#food variables
var food_pos : Vector2
var regen_food : bool = true


func _ready() -> void:
	new_game()

func new_game() -> void:
	get_tree().paused = false
	#clear old segments, hide menu, reset score and generate snake
	get_tree().call_group("segments", "queue_free")
	$game_over_menu.hide()
	score = 0
	$hud.get_node("score_label").text = "SCORE: " + str(score)
	move_direction = up
	can_move = true
	generate_snake()
	move_food()

func generate_snake() -> void:
	old_data.clear()
	snake_data.clear()
	snake.clear()
	
	#start with start_pos, segments down
	for i in range(3):
		add_segment(start_pos + Vector2(0,i))

#adds segment to existing snake
func add_segment(pos) -> void:
	snake_data.append(pos)
	var snake_segment = snake_scene.instantiate()
	snake_segment.position = (pos * cell_size) + Vector2(0,cell_size)
	add_child(snake_segment)
	snake.append(snake_segment)

#called every frame
func _process(_delta) -> void:
	move_snake()

func move_snake() -> void:
	if can_move:
		if Input.is_action_just_pressed("walk_down") and move_direction != up:
			move_direction = down
			can_move = false
			if not game_started:
				start_game()
		if Input.is_action_just_pressed("walk_up") and move_direction != down:
			move_direction = up
			can_move = false
			if not game_started:
				start_game()
		if Input.is_action_just_pressed("walk_left") and move_direction != right:
			move_direction = left
			can_move = false
			if not game_started:
				start_game()
		if Input.is_action_just_pressed("walk_right") and move_direction != left:
			move_direction = right
			can_move = false
			if not game_started:
				start_game()

func start_game():
	game_started = true
	$move_timer.start()

#snake moves in smaller framerate, its bacisally turn based game lol
func _on_move_timer_timeout() -> void:
	can_move = true
	#use snakes previsous position to move the segments:
	old_data = [] + snake_data
	snake_data[0] += move_direction
	for i in range(len(snake_data)):
		#move all segments
		if i > 0:
			snake_data[i] = old_data[i-1]
		snake[i].position = (snake_data[i] * cell_size) + Vector2(0, cell_size)
	check_out_of_bounds()
	check_self_eaten()
	check_food_eaten()

#check if snake collided with a wall, ends game if true
func check_out_of_bounds() -> void:
	if snake_data[0].x < 4 or snake_data[0].y < 3 or snake_data[0].x > 43 or snake_data[0].y > 21:
		end_game()

func check_self_eaten() -> void:
	for i in range(1, len(snake_data)):
		if snake_data[0] == snake_data[i]:
			end_game()

func check_food_eaten() -> void:
	#move food and add segment
	if snake_data[0] == food_pos:
		score += 1
		$hud.get_node("score_label").text = "SKÓRE: " + str(score)
		add_segment(old_data[-1])
		move_food()

func move_food() -> void:
	while regen_food:
		regen_food = false
		food_pos = Vector2(randi_range(4,43), randi_range(3,21))
		for i in snake_data:
			if food_pos == i:
				regen_food = true
	$food.position = (food_pos * cell_size) + Vector2(0, cell_size)
	regen_food = true

func end_game() -> void:
	get_tree().paused = true
	$game_over_menu.show()
	if score >= 10:
		Globals.bigo_snake_completed = true
		$game_over_menu/ColorRect/restart_button.hide()
		$game_over_menu/ColorRect/Label.text = "Úkol splněn, to bude mňamka!"
	else:
		$game_over_menu/ColorRect/Label.text = "Tak z tohohle se asi moc lidí nenají!\nPro úspěšné splnění úkolu musíš nasbírat alespoň 10 konzerv."
	$move_timer.stop()
	game_started = false

func _on_game_over_menu_restart() -> void:
	new_game()
