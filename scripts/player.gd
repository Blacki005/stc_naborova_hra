extends CharacterBody2D

@export var SPEED : int = 800
@export var PROJECTILE_OFFSET : Vector2 = Vector2(0, -100)
@onready var player_camera = $Camera2D
@onready var body_anim = $player_body
@onready var attack_timer = $attack_timer
@onready var sprite = $player_body

#case needs to be this way because the projectile is searched by name match
var projectiles : Dictionary = {
	"Pen" : preload("res://scenes/projectiles/Pen_projectile.tscn"),
	"IDCard" : preload("res://scenes/projectiles/IDCard_projectile.tscn"),
	"Injection" : preload("res://scenes/projectiles/injection_projectile.tscn"),
	"Grenade" : preload("res://scenes/projectiles/Grenade_projectile.tscn"),
	"BluePotion" : preload("res://scenes/projectiles/BluePotion_projectile.tscn")
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

func _physics_process(delta) -> void:
	if not is_saluting:
		player_movement(delta)
		#attack only if mouse is not above the inventory node or inventory is invisible:
		if Globals.able_to_attack and Input.is_action_pressed("attack") and attack_timer.is_stopped():
			var projectile_direction = self.global_position.direction_to(get_global_mouse_position())
			attack(projectile_direction)
		

#func _input(event: InputEvent) -> void:
	#if Input.is_action_just_pressed("salute"):
		##set semaphore
		#is_saluting = true
		#
		#head_anim.play("front")
		#body_anim.play("salute")
		##wait until animation finishes
		#await get_tree().create_timer(0.5).timeout
		##release semaphore
		#is_saluting = false


func player_movement(_delta) -> void:
	var input_direction = Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
	velocity = input_direction * SPEED
	if velocity == Vector2.ZERO:
		body_anim.play("default")
		return
	var angle = input_direction.angle()
	angle = fposmod(angle + TAU, TAU)  # normalize to 0..2PI
	var sector = int((angle + PI/4) / (PI/2)) % 4
	match sector:
		0:
			body_anim.play("walk_right")
		1:
			body_anim.play("walk_down")
		2:
			body_anim.play("walk_left")
		3:
			body_anim.play("walk_up")

	move_and_slide()

	# Push enemies on collision so player can always move through them
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.is_in_group("enemy"):
			var push_direction = -collision.get_normal()
			collider.push_velocity = push_direction * SPEED * 1.5

func attack(projectile_direction: Vector2) -> void:
	#decide if active item is throwable:
	if PlayerInventory.hotbar.has(PlayerInventory.active_item_slot):
		var active_item_name = PlayerInventory.hotbar[PlayerInventory.active_item_slot][0]
		if JsonData.item_data[active_item_name]["ItemCategory"] == "Throwable":
			var projectile = projectiles[active_item_name]
			
			var projectile_instance = projectile.instantiate()
			get_tree().current_scene.add_child(projectile_instance)
			projectile_instance.global_position = self.global_position + PROJECTILE_OFFSET
			projectile_instance.connect("projectile_destroyed", _on_projectile_destroyed)
			
			projectile_instance.sound = load("res://sound/projectiles/"+ active_item_name +".mp3")
			var mouse_rotation = projectile_direction.angle()
			
			
			projectile_instance.rotation = mouse_rotation
			attack_timer.start()

func blink_red(duration: float = 0.1) -> void:
	var original_color = sprite.modulate
	sprite.modulate = Color(1, 0.2, 0.2)  # red tint
	await get_tree().create_timer(duration).timeout
	sprite.modulate = original_color

func _on_projectile_destroyed(sound : AudioStream) -> void:
	$AudioStreamPlayer.stream = sound
	if not $AudioStreamPlayer.playing:
		$AudioStreamPlayer.play()
	

func _on_hurtbox_area_entered(hitbox: Area2D) -> void:
	if hitbox.is_in_group("projectiles"):
		hitbox.destroy()
		var dmg : int = hitbox.damage
		blink_red()
		#TODO: implement meelee damage - this gets damage only if area is projectile
		#TODO: cool take damage effects
		
		var hit_sounds = [
			load("res://sound/player/hit1.mp3"),
			load("res://sound/player/hit2.mp3"),
			load("res://sound/player/hit3.mp3"),
			load("res://sound/player/hit4.mp3"),
		]
		var hit_player = AudioStreamPlayer.new()
		hit_player.stream = hit_sounds[randi() % hit_sounds.size()]
		hit_player.bus = "Master"
		add_child(hit_player)
		hit_player.play()
		hit_player.finished.connect(hit_player.queue_free)
		
		if Globals.shield > dmg:
			Globals.shield -= dmg
		elif Globals.shield > 0:
			Globals.shield = 0
		else:
			Globals.health -= dmg
