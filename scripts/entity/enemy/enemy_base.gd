extends "res://scripts/entity/entity_base.gd"

var chasing_player : bool = false
var player = null
var LOS_to_player = false

@onready var health_bar : ProgressBar = $health_bar
@onready var move_timer : Timer = $move_timer
@onready var detection_area : Area2D = $detection_area

@export var ENY_PROJECTILE : PackedScene = null
@export var ATTACK_DISTANCE : int = 700

func _ready() -> void:
	self.hp_changed.connect(_on_hp_changed)
	health_bar.max_value = hp_max
	health_bar.value = hp_max
	SPEED = 300

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

#TODO: moving AI of enemy
func move_enemy(_delta, direction : Vector2):
	velocity = direction * SPEED
	move_and_slide()

func attack(projectile_direction: Vector2):
	if ENY_PROJECTILE != null:
		var projectile = ENY_PROJECTILE.instantiate()
		get_tree().current_scene.add_child(projectile)
		projectile.global_position = self.global_position + Vector2(0,-100)
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
	attack(self.global_position.direction_to(player.global_position))
	attack_timer.start()

func _on_detection_area_body_exited(_body: Node2D) -> void:
	chasing_player = false
	player = null
	#stop attack timer when player exits detection area
	attack_timer.stop()

func _on_attack_timer_timeout() -> void:
	if LOS_to_player:
		#if chasing player, every timeout check if there is LOS and then attack
		attack(self.global_position.direction_to(player.global_position))
	if chasing_player:
		attack_timer.start()

func _on_hp_changed(new_hp : int) -> void:
	health_bar.value = new_hp
