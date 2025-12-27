extends Node2D

# Configuration
@export var MOVEMENT_RADIUS: float = 100.0
@export var BASE_SPEED: float = 150  # Base time to reach destination
@export var SPEED_INCREASE_PER_SCORE: float = 10  # Faster with higher score
@export var WAIT_TIME_AT_DESTINATION: float = 0.5
@export var RANGE = 500

@export var target : Area2D

var score = 10

var center_position: Vector2
var tween: Tween

func _ready():
	center_position = position
	choose_new_target()

func choose_new_target():
	# Random angle within full circle
	var random_angle = randf_range(0, TAU)
	var target_position = center_position + Vector2(
		cos(random_angle) * MOVEMENT_RADIUS,
		sin(random_angle) * MOVEMENT_RADIUS
	)
	
	# Calculate duration based on distance and speed
	var distance = position.distance_to(target_position)
	var current_speed = BASE_SPEED + (score * SPEED_INCREASE_PER_SCORE)
	var duration = distance / current_speed
	
	# Kill existing tween if any
	if tween:
		tween.kill()
	
	# Create new tween
	tween = create_tween()
	tween.tween_property(self, "position", target_position, duration)
	tween.tween_interval(WAIT_TIME_AT_DESTINATION)
	tween.tween_callback(choose_new_target)

func shoot():
	var projectile = preload("res://scenes/projectiles/bvp_projectile.tscn").instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = global_position
	projectile.shoot_towards_position(Vector2(global_position.x, global_position.y - RANGE))
