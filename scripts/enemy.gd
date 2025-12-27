extends StaticBody2D
@onready var timer = $Timer


func _process(_delta) -> void:
#TODO: moving ai
	#check for salute, stop countdown if player saluted
	if Input.is_action_pressed("salute"):
		timer.stop()


func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		#player is near and needs to salute, run timer
		timer.start(2.5)


func _on_timer_timeout() -> void:
	#player is in the area for 1.5 seconds and didnt salute
	timer.stop()
	$DialogueBubble.show()
	$DialogueBubble.start()
	Globals.health -= 3


func _on_dialogue_bubble_dialogue_ended() -> void:
	$DialogueBubble.hide()
