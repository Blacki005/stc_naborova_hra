extends Node2D

@onready var gun = $bvp
@onready var target = $target

var score = 0

func _ready():
	if target:
		target.connect("hit", _on_target_hit)

func _unhandled_input(event):
	# Alternative: using Input Map action
	if event.is_action_pressed("attack"):
		#check if there is no projectile:
		if get_tree().get_nodes_in_group("projectiles").size() == 0:
			gun.shoot()

func _on_target_hit():
	# Optional: visual/audio feedback
	pass
