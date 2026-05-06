extends CharacterBody2D

signal hp_changed(new_hp:int)
signal hp_max_changed(new_hp_max:int)
signal died

@export var hp_max : int = 50
@export var hp : int = hp_max:
	set(new_hp):
		if new_hp != hp:
			hp = clamp(new_hp,0,hp_max)
			emit_signal("hp_changed", hp)
			if hp == 0:
				emit_signal("died")

@export var defence : int = 0

@export var SPEED : int = 750

@onready var sprite = $Sprite
@onready var coll_shape = $CollisionShape2D
@onready var anim_player = $AnimationPlayer
@onready var hurtbox = $hurtbox
@onready var attack_timer = $attack_timer

@export var receives_knockback : bool = true
@export var knockback_modifier : float = 2
@export var bago_drop_cnt : int = 0

func die():
	queue_free()

func blink_red(duration: float = 0.1) -> void:
	var original_color = sprite.modulate
	sprite.modulate = Color(1, 0.2, 0.2)  # red tint
	await get_tree().create_timer(duration).timeout
	sprite.modulate = original_color

func receive_damage(base_damage : int) -> int:
	var actual_damage = base_damage - defence
	if actual_damage:
		blink_red()
	if (self.hp - actual_damage)<=0 and bago_drop_cnt:
		var drop_item_scene : PackedScene = load("res://scenes/items/pickable_item.tscn")
		var drop_item = drop_item_scene.instantiate()
		get_parent().add_child(drop_item)
		drop_item.item_name = "Bago"
		drop_item.item_quantity = bago_drop_cnt
		drop_item.sprite2d.texture = load("res://images/items/Bago.png")
		drop_item.global_position = self.global_position
		
	self.hp -= actual_damage #neccessary for setter call

	return actual_damage

func receive_knockback(damage_source_pos: Vector2, received_damage:int):
	if receives_knockback:
		var knockback_direction = damage_source_pos.direction_to(self.global_position)
		var knockback_strength = received_damage * knockback_modifier
		var knockback = knockback_direction * knockback_strength
		
		global_position += knockback

func freeze(seconds: float) -> void:
	var original_color = sprite.modulate
	sprite.modulate = Color(0.5, 0.8, 1.0)
	set_physics_process(false)# or disable movement logic
	attack_timer.paused = true
	var timer = get_tree().create_timer(seconds)
	await timer.timeout
	set_physics_process(true)
	attack_timer.paused = false
	sprite.modulate = original_color

func _on_hurtbox_area_entered(hitbox: Area2D) -> void:
	#actual damage = damage - defence
	var actual_damage = receive_damage(hitbox.damage)
	
	#hitbox freeze effect:
	var freeze = hitbox.freeze
	if freeze:
		freeze(freeze)
	
	if hitbox.is_in_group("projectiles"):
		hitbox.destroy()
	
	receive_knockback(hitbox.global_position, actual_damage)

func _on_died() -> void:
	die()
