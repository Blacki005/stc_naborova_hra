extends "res://scripts/entity/entity_base.gd"

enum EnemyType { DEFAULT, CHARGER, DODGER, TANK }

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
@onready var audio_stream_player = $AudioStreamPlayer2D
@onready var banzai_sound : AudioStream = load("res://sound/projectiles/banzai.mp3")
@onready var must_have_been_the_wind : AudioStream = load("res://sound/enemy/must_have_been_the_wind.mp3")
@onready var never_should_have_come_here : AudioStream = load("res://sound/enemy/never_should_have_come_here.mp3")

@export var enemy_type: EnemyType = EnemyType.DEFAULT
@export var ENY_PROJECTILE : PackedScene = null
@export var ATTACK_DISTANCE : int = 700
@export var DAMAGE_REACTIONS : Array[String] = []
@export var WANDER_RADIUS : int = 256

# ─── Charger ────────────────────────────────────────────────────
const CHARGE_SPEED: int = 1500
const CHARGE_WINDUP: float = 1.5
const CHARGE_DURATION: float = 0.3
const CHARGE_COOLDOWN: float = 2.0
const CHARGE_GHOST_INTERVAL: float = 0.05
var _dash_shader: Shader = preload("res://shaders/dash_ghost.gdshader")
var is_charging: bool = false
var is_winding_up: bool = false
var charge_direction: Vector2 = Vector2.ZERO
var charge_timer: float = 0.0
var charge_cooldown_timer: float = 0.0
var windup_timer: float = 0.0
var ghost_spawn_timer: float = 0.0
var _windup_tween: Tween = null

# ─── Dodger ─────────────────────────────────────────────────────
const STRAFE_SWITCH_TIME: float = 1.5
const ORBIT_DISTANCE: float = 350.0
var strafe_direction: float = 1.0
var strafe_timer: float = 0.0

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

	# Type-specific defaults (scene exports override these when set)
	match enemy_type:
		EnemyType.CHARGER:
			receives_knockback = false
		EnemyType.DODGER:
			SPEED = 350
			strafe_timer = STRAFE_SWITCH_TIME
		EnemyType.TANK:
			SPEED = 150
			knockback_modifier = 0.5

func _physics_process(delta: float) -> void:
	charge_cooldown_timer = maxf(0.0, charge_cooldown_timer - delta)

	if chasing_player:
		#raycasting must be in physics process according to docs
		#only raycast when player is in detection area
		var space_state = get_world_2d().direct_space_state
		# use global coordinates, not local to node
		var query = PhysicsRayQueryParameters2D.create(self.global_position, player.global_position)
		var result = space_state.intersect_ray(query)
		if result.size() > 0 and result.collider == player:
			LOS_to_player = true
			match enemy_type:
				EnemyType.CHARGER:
					_process_charger(delta)
				EnemyType.DODGER:
					_process_dodger(delta)
				EnemyType.TANK:
					_process_tank(delta)
				_:
					_process_default(delta)
		else:
			LOS_to_player = false
			if is_charging or is_winding_up:
				_cancel_charge()
	elif wandering:
		var direction = self.global_position.direction_to(wander_destination).normalized()
		move_enemy(delta, direction, SPEED / 2.0)
		if global_position.distance_to(wander_destination) < 5.0:
			wandering = false
			velocity = Vector2.ZERO
			_start_wander_timer()

# ─── Movement ───────────────────────────────────────────────────

func move_enemy(_delta, direction : Vector2, speed : float = SPEED):
	if push_velocity.length() > 10.0:
		velocity = push_velocity
	else:
		velocity = direction * speed
	move_and_slide()
	push_velocity = push_velocity.lerp(Vector2.ZERO, 0.15)

# ─── Type behaviours ────────────────────────────────────────────

func _process_default(_delta: float) -> void:
	var direction = global_position.direction_to(player.global_position).normalized()
	move_enemy(_delta, direction)

func _process_tank(_delta: float) -> void:
	var direction = global_position.direction_to(player.global_position).normalized()
	move_enemy(_delta, direction, SPEED)

func _process_dodger(delta: float) -> void:
	strafe_timer -= delta
	if strafe_timer <= 0.0:
		strafe_direction *= -1
		strafe_timer = STRAFE_SWITCH_TIME + randf_range(-0.3, 0.3)

	var to_player = global_position.direction_to(player.global_position).normalized()
	var dist = global_position.distance_to(player.global_position)

	# Approach when far, retreat when close, orbit at ORBIT_DISTANCE
	var approach_weight = clampf((dist - ORBIT_DISTANCE) / ORBIT_DISTANCE, -1.0, 1.0)
	var strafe = Vector2(-to_player.y, to_player.x) * strafe_direction
	var direction = (to_player * approach_weight + strafe).normalized()

	move_enemy(delta, direction, SPEED)

func _process_charger(delta: float) -> void:
	if is_charging:
		_handle_charge(delta)
		return

	if is_winding_up:
		return  # windup animation drives the transition to charge

	# Move toward player at half speed while waiting for cooldown
	var direction = global_position.direction_to(player.global_position).normalized()
	move_enemy(delta, direction, SPEED * 0.5)

	# Begin windup when cooldown is ready
	if charge_cooldown_timer <= 0.0:
		_start_windup()

# ─── Charger helpers ────────────────────────────────────────────

func _start_windup() -> void:
	audio_stream_player.stream = banzai_sound
	audio_stream_player.volume_linear = 0.7
	audio_stream_player.play()
	is_winding_up = true
	velocity = Vector2.ZERO

	# Phase 1 (60%): progressively turn red
	var red_time := CHARGE_WINDUP * 0.6
	# Phase 2 (40%): two white blinks then charge
	var blink_time := CHARGE_WINDUP * 0.4
	var half_blink := blink_time / 4.0  # 4 steps: white→red→white→red

	if _windup_tween and _windup_tween.is_valid():
		_windup_tween.kill()
	_windup_tween = create_tween()

	# Gradually shift to deep red
	_windup_tween.tween_property(sprite, "modulate", Color(1.0, 0.2, 0.2), red_time)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	# Blink white twice
	_windup_tween.tween_property(sprite, "modulate", Color(2.0, 2.0, 2.0), half_blink)\
		.set_trans(Tween.TRANS_LINEAR)
	_windup_tween.tween_property(sprite, "modulate", Color(1.0, 0.2, 0.2), half_blink)\
		.set_trans(Tween.TRANS_LINEAR)
	_windup_tween.tween_property(sprite, "modulate", Color(2.5, 2.5, 2.5), half_blink)\
		.set_trans(Tween.TRANS_LINEAR)
	_windup_tween.tween_property(sprite, "modulate", Color(1.0, 0.2, 0.2), half_blink)\
		.set_trans(Tween.TRANS_LINEAR)

	# Launch the charge after the full animation
	_windup_tween.tween_callback(_start_charge)

func _start_charge() -> void:
	_show_reaction("Banzai!")
	is_winding_up = false
	is_charging = true
	charge_timer = CHARGE_DURATION
	charge_direction = global_position.direction_to(player.global_position).normalized()
	ghost_spawn_timer = 0.0
	# Brighten sprite during the rush
	sprite.modulate = Color(1.0, 0.8, 0.5)
	_spawn_charge_ghost()

func _handle_charge(delta: float) -> void:
	charge_timer -= delta
	ghost_spawn_timer -= delta

	if ghost_spawn_timer <= 0.0:
		ghost_spawn_timer = CHARGE_GHOST_INTERVAL
		_spawn_charge_ghost()

	velocity = charge_direction * CHARGE_SPEED
	move_and_slide()

	if charge_timer <= 0.0:
		_end_charge()

func _end_charge() -> void:
	is_charging = false
	charge_cooldown_timer = CHARGE_COOLDOWN
	sprite.modulate = Color(1, 1, 1)

func _cancel_charge() -> void:
	audio_stream_player.stop()
	is_charging = false
	is_winding_up = false
	if _windup_tween and _windup_tween.is_valid():
		_windup_tween.kill()
		_windup_tween = null
	sprite.modulate = Color(1, 1, 1)
	velocity = Vector2.ZERO

func _spawn_charge_ghost() -> void:
	var ghost := Sprite2D.new()
	ghost.z_index = sprite.z_index - 1
	ghost.texture = sprite.texture
	ghost.global_position = global_position
	ghost.offset = sprite.offset
	ghost.flip_h = sprite.flip_h
	ghost.scale = sprite.scale

	# Red-tinted afterimage using the dash ghost shader
	var mat := ShaderMaterial.new()
	mat.shader = _dash_shader
	mat.set_shader_parameter("ghost_color", Color(1.0, 0.3, 0.15, 1.0))
	mat.set_shader_parameter("alpha_mult", 0.7)
	mat.set_shader_parameter("distortion", 0.15)
	ghost.material = mat

	get_tree().current_scene.add_child(ghost)

	var tween := ghost.create_tween().set_parallel(true)
	tween.tween_property(mat, "shader_parameter/alpha_mult", 0.0, 0.35)
	tween.tween_property(ghost, "global_position", ghost.global_position + charge_direction * -30.0, 0.35)
	tween.chain().tween_callback(ghost.queue_free)

# ─── Attack ─────────────────────────────────────────────────────

func attack(projectile_direction: Vector2) -> void:
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
	if enemy_type != EnemyType.CHARGER:
		_show_reaction("Never should have come here!")
		audio_stream_player.volume_linear = 10
		audio_stream_player.stream = never_should_have_come_here
		audio_stream_player.play()
	if enemy_type != EnemyType.CHARGER:
		attack(self.global_position.direction_to(player.global_position))
	attack_timer.start()

func _on_detection_area_body_exited(_body: Node2D) -> void:
	chasing_player = false
	player = null
	#stop attack timer when player exits detection area
	attack_timer.stop()
	#reset default position and resume wandering
	default_position = global_position
	_cancel_charge()
	_show_reaction("Must have been the wind")
	audio_stream_player.volume_linear = 1.5
	audio_stream_player.stream = must_have_been_the_wind
	audio_stream_player.play()
	_start_wander_timer()

func _on_attack_timer_timeout() -> void:
	# Chargers don't shoot — their charge is the attack
	if enemy_type == EnemyType.CHARGER:
		if chasing_player:
			attack_timer.start()
		return
	if LOS_to_player:
		#if chasing player, every timeout check if there is LOS and then attack
		attack(self.global_position.direction_to(player.global_position))
	if chasing_player:
		attack_timer.start()


func _on_hp_changed(new_hp : int) -> void:
	health_bar.value = new_hp
	if DAMAGE_REACTIONS.size() > 0:
		_show_reaction(DAMAGE_REACTIONS.pick_random())

# ─── Reaction bubble ───────────────────────────────────────────

func _show_reaction(text: String) -> void:
	var label_node = get_node_or_null("damage_reaction")
	if label_node == null:
		return
	label_node.show()
	(label_node as Label).text = text
	var tween1 = create_tween()
	tween1.tween_property(label_node as Label, "position", Vector2(-104, -400), 2.0).from(Vector2(-104, -208))
	var tween2 = create_tween()
	tween2.tween_property(label_node as Label, "modulate", Color(1, 1, 1, 0), 2.0).from(Color(1,1,1,1))

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
