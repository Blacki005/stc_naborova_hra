extends "res://scripts/entity_base.gd"

#projectile = mouse:

@onready var attack_timer = $attack_timer

func _physics_process(delta) -> void:
	move_player(delta)


func move_player(_delta) -> void: 
	var input_direction = Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
	velocity = input_direction * SPEED
	var angle_to_x_axis = input_direction.angle() - PI/3

		
	move_and_slide()
