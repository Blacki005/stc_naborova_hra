extends Area2D

@onready var collision_shape = $CollisionShape2D

@export var travel_time: float = 2.0  # Time to reach target
@export var arc_height: float = 200.0  # Simulated trajectory arc

var start_position: Vector2
var target_position: Vector2
var elapsed_time: float = 0.0
var is_active: bool = false

func shoot_towards_position(target_pos: Vector2):
	start_position = global_position
	target_position = target_pos
	is_active = true
	self.monitorable = false

func _process(delta):
	if not is_active:
		return
		
	elapsed_time += delta
	var progress = elapsed_time / travel_time
	
	if progress >= 1.0:
		# Reached destination or missed
		self.monitorable = true
		if has_overlapping_areas():
			var target = get_overlapping_areas()[0]
			target.get_hit()
			destroy()
		else:
			destroy()
	
	# Linear interpolation for horizontal movement
	var pos = start_position.lerp(target_position, progress)
	
	# Add parabolic arc for vertical movement (simulate depth)
	var arc_offset = -arc_height * sin(progress * PI)
	pos.y += arc_offset
	
	global_position = pos

func destroy():
	queue_free()
