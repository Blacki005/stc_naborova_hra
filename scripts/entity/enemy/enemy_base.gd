extends "res://scripts/entity/entity_base.gd"

var chasing_player : bool = false
var player = null
var LOS_to_player = false

var push_velocity : Vector2 = Vector2.ZERO
var default_position : Vector2 = Vector2.ZERO
var wander_destination : Vector2 = Vector2.ZERO
var wandering : bool = false
var wander_timer : Timer = null

@onready var health_bar : ProgressBar = $health_bar
@onready var detection_area : Area2D = $detection_area

@export var ENY_PROJECTILE : PackedScene = null
@export var ATTACK_DISTANCE : int = 700
@export var DAMAGE_REACTIONS : Array[String] = []
@export var WANDER_RADIUS : int = 256

func _ready() -> void:
	self.hp_changed.connect(_on_hp_changed)
	health_bar.max_value = hp_max
	health_bar.value = hp_max
	SPEED = 300

	default_position = global_position

	wander_timer = Timer.new()
	wander_timer.one_shot = true
	wander_timer.timeout.connect(_on_wander_timer_timeout)
	add_child(wander_timer)

	_start_wander_timer()

func _physics_process(delta: float) -> void:
	if chasing_player:
		#raycasting must be in physics process according to docs
		#only raycast when player is in detection area
		var space_state = get_world_2d().direct_space_state
		# use global coordinates, not local to node
		var query = PhysicsRayQueryParameters2D.create(self.global_position, player.global_position)
		var result = space_state.intersect_ray(query)
		if result.collider == player:
			LOS_to_player = true
			var direction = self.global_position.direction_to(player.global_position).normalized()
			move_enemy(delta, direction)
		else:
			LOS_to_player = false
	elif wandering:
		var direction = self.global_position.direction_to(wander_destination).normalized()
		move_enemy(delta, direction, SPEED / 2.0)
		if global_position.distance_to(wander_destination) < 5.0:
			wandering = false
			velocity = Vector2.ZERO
			_start_wander_timer()

#TODO: moving AI of enemy
func move_enemy(_delta, direction : Vector2, speed : float = SPEED):
	if push_velocity.length() > 10.0:
		velocity = push_velocity
	else:
		velocity = direction * speed
	move_and_slide()
	push_velocity = push_velocity.lerp(Vector2.ZERO, 0.15)

func attack(projectile_direction: Vector2):
	if ENY_PROJECTILE != null:
		var projectile = ENY_PROJECTILE.instantiate()
		get_tree().current_scene.add_child(projectile)
		projectile.global_position = global_position + Vector2(0,-100)
		#make sure that projectile hits player and is on correct layers
		projectile.set_collision_layer_value(4, false)
		projectile.set_collision_layer_value(3, true)
		projectile.damage = 2
		projectile.SPEED = 500
		
		projectile.rotation = projectile_direction.angle()

func _on_detection_area_body_entered(body: Node2D) -> void:
	#check if the body is player - not neccessary because detection area masks only player layer
	player = body
	chasing_player = true
	wandering = false
	wander_timer.stop()
	attack(self.global_position.direction_to(player.global_position))
	attack_timer.start()

func _on_detection_area_body_exited(_body: Node2D) -> void:
	chasing_player = false
	player = null
	#stop attack timer when player exits detection area
	attack_timer.stop()
	#reset default position and resume wandering
	default_position = global_position
	_start_wander_timer()

func _on_attack_timer_timeout() -> void:
	if LOS_to_player:
		#if chasing player, every timeout check if there is LOS and then attack
		attack(self.global_position.direction_to(player.global_position))
	if chasing_player:
		attack_timer.start()


func _on_hp_changed(new_hp : int) -> void:
	health_bar.value = new_hp
	
	var dmg_react = get_node_or_null("damage_reaction")
	if dmg_react != null:
		dmg_react.show()
		(dmg_react as Label).text = DAMAGE_REACTIONS.pick_random()
		var tween1 = create_tween()
		tween1.tween_property(dmg_react as Label, "position", Vector2(-104, -400), 2.0).from(Vector2(-104, -208))
		var tween2 = create_tween()
		tween2.tween_property(dmg_react as Label, "modulate", Color(1, 1, 1, 0), 2.0).from(Color(1,1,1,1))

func _start_wander_timer() -> void:
	wander_timer.start(randf_range(2.0, 5.0))

func _on_wander_timer_timeout() -> void:
	if chasing_player:
		return

	var space_state = get_world_2d().direct_space_state

	# Grab the enemy's own collision shape so cast_motion accounts for its full size
	var owners := get_shape_owners()
	if owners.is_empty():
		_start_wander_timer()
		return
	var shape := shape_owner_get_shape(owners[0], 0)

	var attempts : int = 0
	while attempts < 10:
		var angle = randf() * TAU
		var dist = randf() * WANDER_RADIUS
		var candidate = default_position + Vector2(cos(angle), sin(angle)) * dist
		var motion = candidate - global_position

		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = shape
		query.transform = global_transform
		query.motion = motion
		query.exclude = [get_rid()]

		# cast_motion sweeps the full collision shape along the motion vector.
		# Returns [safe_frac, unsafe_frac]; both are 1.0 when fully unobstructed.
		var result := space_state.cast_motion(query)

		if result[0] >= 1.0:
			wander_destination = candidate
			wandering = true
			return
		attempts += 1

	# if all attempts hit something, just stay still and try again later
	_start_wander_timer()
