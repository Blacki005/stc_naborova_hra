extends Node2D

@export var time_limit : int = 5
@export var needed_hits : int = 5
@onready var crosshair = $crosshair
var hits : int = 0
var playing : bool = false #checks that gunshot sound is played only when actually playing the game


func _input(event: InputEvent) -> void:
	#move crosshair with mouse
	if event is InputEventMouseMotion:
		crosshair.position = event.position
	
	if playing && event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
			$gunshot_sound.play()


#check if target has been hit
func _on_target_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		
		if event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
			hits += 1
			
			#change position and make target smaller
			$target.position = Vector2(300 + (randi() % 1320), 300 + (randi() % 480))
			$target.scale *= 0.8


func _on_timer_timeout() -> void:
	#game over
	#show mouse and other ui elements
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	$target/CollisionShape2D.disabled = true
	$target.hide()
	crosshair.hide()
	$exit_button.show()
	$Label.show()
	
	playing = false
	
	if hits >= needed_hits:
		$Label.text = "Vyhráli jste"
		Globals.bago += 5
	else:
		$Label.text ="Bylo by fajn se občas i trefit"
		$new_game_button.show()
	
	#decide if player was hurt during shooting (50% chance):
	if randi() % 2 == 1:
		Globals.health -= 5
		$health_lost_message.text = "Během střílení z prototypu ses zranil a přišel jsi o zdraví. Zbývá ti: " + str(Globals.health) + " životů!" 
		$health_lost_message.show()


func _on_new_game_button_button_up() -> void:
	#set game played variable to true:
	Globals.target_range_played = true
	playing = true
	
	#hide mouse and ui elements
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	$new_game_button.hide()
	$exit_button.hide()
	$Label.hide()
	$health_lost_message.hide()
	
	crosshair.show()
	$target/CollisionShape2D.disabled = false
	$target.show()
	$timer.wait_time = time_limit
	$timer.start()
	$target.scale = Vector2(1,1)
	hits = 0


func _on_exit_button_button_up() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/katedra_zbrani/katedra_zbrani.tscn")
