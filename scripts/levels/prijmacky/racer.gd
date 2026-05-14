extends CharacterBody2D

var wheel_base = 32
var steering_angle = 13
var engine_power = 1500
var friction = -70
var drag = -0.06
var braking = -450
var max_speed_reverse = 250
var slip_speed = 750
var traction_fast = 2.5
var traction_slow = 15

# --- Boost settings ---
const BOOST_MAX = 50.0            # max boost tank
const BOOST_REFILL_RATE = 15.0    # per second when not boosting
const BOOST_BURN_RATE = 25       # per second while boosting
const BOOST_SPEED_MULT = 1.4      # extra engine power
const BOOST_STEER_MULT = 0.6       # steering_angle is scaled by this (worse steer)

var boost_amount = BOOST_MAX
var is_boosting = false

var acceleration = Vector2.ZERO
var steer_direction

@onready var boost_particles: CPUParticles2D = $BoostParticles
@onready var boost_bar = $CanvasLayer/boost_bar
@onready var camera = $Camera2D
@onready var audio_player = $AudioStreamPlayer


func _ready() -> void:
	boost_bar.min_value = 0
	boost_bar.max_value = BOOST_MAX

func _physics_process(delta):
	boost_bar.value = boost_amount
	is_boosting = false
	acceleration = Vector2.ZERO
	get_input(delta)
	apply_friction(delta)
	calculate_steering(delta)
	velocity += acceleration * delta
	move_and_slide()
	if boost_particles:
		boost_particles.emitting = is_boosting

func apply_friction(delta):
	if acceleration == Vector2.ZERO and velocity.length() < 50:
		velocity = Vector2.ZERO
	var friction_force = velocity * friction * delta
	var drag_force = velocity * velocity.length() * drag * delta
	acceleration += drag_force + friction_force
	
func get_input(delta):
	var turn = Input.get_axis("walk_left", "walk_right")

	# Boost handling
	var engine_multiplier := 1.0
	var current_steering_angle = steering_angle
	if Input.is_action_pressed("salute") and boost_amount > 0.0:

		if not audio_player.playing:
			audio_player.play()
		
		is_boosting = true
		engine_multiplier = BOOST_SPEED_MULT
		current_steering_angle *= BOOST_STEER_MULT
		boost_amount = max(0.0, boost_amount - BOOST_BURN_RATE * delta)
	else:
		audio_player.stop()
		boost_amount = min(BOOST_MAX, boost_amount + BOOST_REFILL_RATE * delta)

	steer_direction = turn * deg_to_rad(current_steering_angle)

	if Input.is_action_pressed("walk_up"):
		acceleration = transform.x * engine_power * engine_multiplier
	if Input.is_action_pressed("walk_down"):
		acceleration = transform.x * braking
	
func calculate_steering(delta):
	var rear_wheel = position - transform.x * wheel_base / 2.0
	var front_wheel = position + transform.x * wheel_base / 2.0
	rear_wheel += velocity * delta
	front_wheel += velocity.rotated(steer_direction) * delta
	var new_heading = rear_wheel.direction_to(front_wheel)
	var traction = traction_slow
	if velocity.length() > slip_speed:
		traction = traction_fast
	var d = new_heading.dot(velocity.normalized())
	if d > 0:
		velocity = lerp(velocity, new_heading * velocity.length(), traction * delta)
	if d < 0:
		velocity = -new_heading * min(velocity.length(), max_speed_reverse)
	rotation = new_heading.angle()
