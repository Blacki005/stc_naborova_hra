extends CharacterBody2D

#TODO: add idle animations to all sides and handle it

@export var SPEED : int = 800
@onready var player_camera = $Camera2D
@onready var body_anim = $player_body
@onready var head_anim = $player_head
@onready var attack_timer = $attack_timer

#case needs to be this way because the projectile is searched by name match
var projectiles : Dictionary = {
	"Pen" : preload("res://scenes/projectiles/Pen_projectile.tscn"),
	"IDCard" : preload("res://scenes/projectiles/IDCard_projectile.tscn")
}
var is_saluting #acts a bit as a semaphore, so the salute animation is played whole

func _ready() -> void:
	#set interaction manager player variable
	InteractionManager.player = self
	
	#set camera limits according to parent scene
	player_camera.limit_bottom = get_parent().camera_limit_bottom
	player_camera.limit_left = get_parent().camera_limit_left
	player_camera.limit_right = get_parent().camera_limit_right
	player_camera.limit_top = get_parent().camera_limit_top
	
	#load sprite frames according to selected character
	$player_head.sprite_frames = load("res://resources/sprite_frames/" + Globals.character + ".tres")


func _physics_process(delta) -> void:
	if not is_saluting:
		player_movement(delta)
		#attack only if mouse is not above the inventory node or inventory is invisible:
		if Globals.able_to_attack and Input.is_action_just_pressed("attack") and attack_timer.is_stopped():
			var projectile_direction = self.global_position.direction_to(get_global_mouse_position())
			attack(projectile_direction)

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("salute"):
		#set semaphore
		is_saluting = true
		
		head_anim.play("front")
		body_anim.play("salute")
		#wait until animation finishes
		await get_tree().create_timer(0.5).timeout
		#release semaphore
		is_saluting = false


func player_movement(_delta) -> void: 
	var input_direction = Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
	velocity = input_direction * SPEED
	var angle =  input_direction.angle() - PI/3
	#TODO: animations
	#if angle < PI/2:
		#body_anim.play("walk_right")
	#elif angle < PI:
		#body_anim.play("walk_down")
	#elif angle < (3*PI)/2:
		#body_anim.play("walk_left")
	#elif angle <= 2*PI:
		#body_anim.play("walk_up")
	move_and_slide()

func attack(projectile_direction: Vector2):
	#decide if active item is throwable:
	if PlayerInventory.hotbar.has(PlayerInventory.active_item_slot):
		var active_item_name = PlayerInventory.hotbar[PlayerInventory.active_item_slot][0]
		if JsonData.item_data[active_item_name]["ItemCategory"] == "Throwable":
			var projectile = projectiles[active_item_name]
			
			var projectile_instance = projectile.instantiate()
			get_tree().current_scene.add_child(projectile_instance)
			projectile_instance.global_position = self.global_position
			
			var mouse_rotation = projectile_direction.angle()
			projectile_instance.rotation = mouse_rotation
			
			attack_timer.start()

func _on_hurtbox_area_entered(hitbox: Area2D) -> void:
	if hitbox.is_in_group("projectiles"):
		hitbox.destroy()
		#TODO: implement meelee damage - this gets damage only if area is projectile
		#TODO: cool take damage effects
		Globals.health -= hitbox.damage
