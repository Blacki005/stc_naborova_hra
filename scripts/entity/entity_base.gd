extends CharacterBody2D

signal hp_changed(new_hp:int)
signal hp_max_changed(new_hp_max:int)
signal died

@export var hp_max : int = 100
@export var hp : int = hp_max:
	set(new_hp):
		if new_hp != hp:
			hp = clamp(new_hp,0,hp_max)
			emit_signal("hp_changed",hp)
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

func die():
	queue_free()

func receive_damage(base_damage : int) -> int:
	var actual_damage = base_damage - defence
	self.hp -= actual_damage #neccessary for setter call
	return actual_damage

func receive_knockback(damage_source_pos: Vector2, received_damage:int):
	if receives_knockback:
		var knockback_direction = damage_source_pos.direction_to(self.global_position)
		var knockback_strength = received_damage * knockback_modifier
		var knockback = knockback_direction * knockback_strength
		
		global_position += knockback

func _on_hurtbox_area_entered(hitbox: Area2D) -> void:
	#actual damage = damage - defence
	var actual_damage = receive_damage(hitbox.damage)
	
	if hitbox.is_in_group("projectiles"):
		hitbox.destroy()
	
	receive_knockback(hitbox.global_position, actual_damage)


func _on_died() -> void:
	#TODO: zmensit enemy cnt v hlavni scene
	
	die()
