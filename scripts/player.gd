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

# ─── Screen shake ───────────────────────────────────────────────
var _shake_tween: Tween = null

# ─── Dash ───────────────────────────────────────────────────────
const DASH_SPEED: int = 2800
const DASH_DURATION: float = 0.10
const DASH_COOLDOWN: float = 0.7
const GHOST_SPAWN_INTERVAL: float = 0.018
var _dash_shader: Shader = preload("res://shaders/dash_ghost.gdshader")
var is_dashing: bool = false
var dash_direction: Vector2 = Vector2.ZERO
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var ghost_spawn_timer: float = 0.0
var last_move_direction: Vector2 = Vector2.DOWN

# ─── Combo system ───────────────────────────────────────────────
const COMBO_TIMEOUT: float = 2.0
const COMBO_BAGO_MILESTONE: int = 5
var combo_count: int = 0
var combo_timer: float = 0.0
var _combo_font: FontFile = preload("res://fonts/CozetteVector.otf")
var _bago_texture: Texture2D = preload("res://images/items/Bago.png")
var _bago_scene: PackedScene = preload("res://scenes/items/pickable_item.tscn")

func _ready() -> void:
	#set interaction manager player variable
	InteractionManager.player = self

	#set camera limits according to parent scene
	player_camera.limit_bottom = get_parent().camera_limit_bottom
	player_camera.limit_left = get_parent().camera_limit_left
	player_camera.limit_right = get_parent().camera_limit_right
	player_camera.limit_top = get_parent().camera_limit_top

	# Register dash input action if not already present
	if not InputMap.has_action("dash"):
		InputMap.add_action("dash")
		var ev := InputEventKey.new()
		ev.keycode = KEY_SHIFT
		InputMap.action_add_event("dash", ev)

	# Connect global signals
	Globals.screen_shake_requested.connect(shake_camera)
	Globals.enemy_hit.connect(_on_enemy_hit)

func _physics_process(delta: float) -> void:
	# Tick cooldown timers
	dash_cooldown_timer = maxf(0.0, dash_cooldown_timer - delta)
	combo_timer = maxf(0.0, combo_timer - delta)
	if combo_timer <= 0.0 and combo_count > 0:
		combo_count = 0

	if is_saluting:
		return

	if is_dashing:
		_handle_dash(delta)
		return

	player_movement(delta)

	# Attack
	if Globals.able_to_attack and Input.is_action_pressed("attack") and attack_timer.is_stopped():
		var projectile_direction = self.global_position.direction_to(get_global_mouse_position())
		attack(projectile_direction)

	# Dash input
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0:
		_start_dash()


func player_movement(_delta) -> void:
	var input_direction = Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
	velocity = input_direction * SPEED
	if velocity == Vector2.ZERO:
		body_anim.play("default")
		return

	# Track last movement direction for dash
	last_move_direction = velocity.normalized()

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
	if true:#hitbox.is_in_group("projectiles"):
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

		Globals.stats["damage_taken"] += dmg

		# Screen shake + reset combo on player damage
		shake_camera(8.0, 0.2)
		_reset_combo()

# ─── Screen shake ───────────────────────────────────────────────

func shake_camera(strength: float = 6.0, duration: float = 0.15) -> void:
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
	var shake_steps := 5
	var step_time := duration / shake_steps
	_shake_tween = create_tween()
	for i in shake_steps:
		var rand_offset := Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
		_shake_tween.tween_property(player_camera, "offset", rand_offset, step_time)
	_shake_tween.tween_property(player_camera, "offset", Vector2.ZERO, step_time)

# ─── Dash ───────────────────────────────────────────────────────

func _start_dash() -> void:
	is_dashing = true
	dash_timer = DASH_DURATION
	ghost_spawn_timer = 0.0

	# Determine direction: prefer current input, fallback to last movement
	var input_dir := Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
	if input_dir.length_squared() > 0.01:
		dash_direction = input_dir.normalized()
	else:
		dash_direction = last_move_direction

	# Disable hurtbox so player is invulnerable during dash
	$hurtbox.set_deferred("monitoring", false)
	$hurtbox/CollisionShape2D.set_deferred("disabled", true)

	# Spawn first ghost immediately
	_spawn_dash_ghost()

func _handle_dash(delta: float) -> void:
	dash_timer -= delta
	ghost_spawn_timer -= delta

	# Spawn afterimage ghosts at interval
	if ghost_spawn_timer <= 0.0:
		ghost_spawn_timer = GHOST_SPAWN_INTERVAL
		_spawn_dash_ghost()

	velocity = dash_direction * DASH_SPEED
	move_and_slide()

	if dash_timer <= 0.0:
		is_dashing = false
		dash_cooldown_timer = DASH_COOLDOWN
		# Re-enable hurtbox
		$hurtbox.set_deferred("monitoring", true)
		$hurtbox/CollisionShape2D.set_deferred("disabled", false)

func _spawn_dash_ghost() -> void:
	var ghost := Sprite2D.new()
	ghost.z_index = body_anim.z_index - 1
	ghost.texture = body_anim.sprite_frames.get_frame_texture(body_anim.animation, body_anim.frame)
	ghost.global_position = global_position
	ghost.offset = body_anim.offset
	ghost.flip_h = body_anim.flip_h
	ghost.scale = body_anim.scale

	# Apply dash ghost shader
	var mat := ShaderMaterial.new()
	mat.shader = _dash_shader
	mat.set_shader_parameter("alpha_mult", 0.8)
	mat.set_shader_parameter("distortion", 0.1)
	ghost.material = mat

	get_tree().current_scene.add_child(ghost)

	# Animate fade-out and slight drift
	var tween := ghost.create_tween().set_parallel(true)
	tween.tween_property(mat, "shader_parameter/alpha_mult", 0.0, 0.4)
	tween.tween_property(ghost, "global_position", ghost.global_position + dash_direction * -25.0, 0.4)
	tween.chain().tween_callback(ghost.queue_free)

# ─── Combo system ───────────────────────────────────────────────

func _on_enemy_hit(hit_pos: Vector2) -> void:
	combo_count += 1
	combo_timer = COMBO_TIMEOUT
	Globals.stats["max_combo"] = maxi(Globals.stats["max_combo"], combo_count)

	if combo_count >= 2:
		_show_combo_text(hit_pos)

	# Spawn bago pickable item at milestones
	if combo_count > 0 and combo_count % COMBO_BAGO_MILESTONE == 0:
		_spawn_bago_drop(hit_pos)

func _reset_combo() -> void:
	combo_count = 0
	combo_timer = 0.0

func _show_combo_text(pos: Vector2) -> void:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Use the pixel-art font with nearest-neighbour filtering
	label.add_theme_font_override("font", _combo_font)

	# Scale text and color with combo intensity
	var font_size := 28 + mini(combo_count, 10) * 2
	label.add_theme_font_size_override("font_size", font_size)

	var text_color: Color
	if combo_count >= 8:
		text_color = Color(1.0, 0.15, 0.15)      # red
	elif combo_count >= 5:
		text_color = Color(1.0, 0.55, 0.0)        # orange
	else:
		text_color = Color(1.0, 0.85, 0.0)        # gold

	label.add_theme_color_override("font_color", text_color)
	label.text = str(combo_count) + "x COMBO!"
	label.z_index = 100
	label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var world_pos := pos + Vector2(randf_range(-20, 20), -90)
	label.global_position = world_pos
	label.scale = Vector2(0.1, 0.1)

	get_tree().current_scene.add_child(label)

	# Pop in → float up → fade out
	var tween := get_tree().create_tween().set_parallel(true)
	tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(label, "global_position:y", world_pos.y - 70, 0.8).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.3)
	tween.chain().tween_callback(label.queue_free)

func _spawn_bago_drop(pos: Vector2) -> void:
	var bago_item := _bago_scene.instantiate()
	get_tree().current_scene.add_child(bago_item)
	bago_item.item_name = "Bago"
	bago_item.item_quantity = 1
	bago_item.texture = _bago_texture
	bago_item.sprite2d.texture = _bago_texture
	bago_item.sprite2d.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	# Bouncy arc: shoot upward, arc out to a landing spot
	var land_offset := Vector2(randf_range(-1, 1), randf_range(-0.5, 1.0)).normalized() * randf_range(120, 200)
	var land_pos := pos + land_offset
	var apex := (pos + land_pos) * 0.5 + Vector2(0, -160)
	bago_item.global_position = pos
	bago_item.scale = Vector2(0.1, 0.1)

	var tween := bago_item.create_tween().set_parallel(false)

	# Launch up to apex with a big stretch
	tween.tween_property(bago_item, "global_position", apex, 0.15)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(bago_item, "scale", Vector2(1.5, 1.5), 0.15)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Fall to landing spot and squash
	tween.tween_property(bago_item, "global_position", land_pos, 0.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(bago_item, "scale", Vector2(0.8, 0.8), 0.2)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Bounce back to normal
	tween.tween_property(bago_item, "scale", Vector2.ONE, 0.15)\
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
