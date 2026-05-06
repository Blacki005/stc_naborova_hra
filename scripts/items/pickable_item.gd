extends Node2D

@onready var interaction_area = $interaction_area
@onready var sprite2d = $Sprite2D

@export var pop_distance : int = 32
@export var pop_time : float = 0.18
@export var fade_time: float = 0.12
@export var hop_height: float = 12.0        # how high it hops upward (negative Y)
@export var hop_time: float = 0.08          # time for the hop

@export var item_name : String
@export var item_quantity : int
@export var texture : Texture2D

func _ready():
	sprite2d.texture = texture
	interaction_area.interact = Callable(self, "_on_interact")

func _on_interact():
	if item_name == "Bago":
		Globals.bago += item_quantity
	else:
		PlayerInventory.add_item(item_name, item_quantity)
	animate_and_free()

func animate_and_free() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		queue_free()
		return

	var start = global_position
	var end = player.global_position
	var dist = (end - start).length()
	if dist < 1.0:
		queue_free()
		return

	# Arc height scales with distance; ensure at least hop_height
	var arc_height = max(hop_height, dist)
	var apex = (start + end) * 0.5 + Vector2(0, -arc_height)

	var tween = create_tween().set_parallel(false)
	tween.tween_property(self, "global_position", apex, hop_time * 0.5) \
		 .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", end, hop_time * 0.5) \
		 .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Fade after landing
	tween.tween_property(self, "modulate:a", 0.0, fade_time).set_trans(Tween.TRANS_SINE)

	tween.finished.connect(queue_free)
