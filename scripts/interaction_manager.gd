extends Node2D

var player
@onready var label = $Label

const base_text : String = "[E] to "
const OFFSET : Vector2 = Vector2(-50,-250) #offset so the label is above the character

var active_areas = [] #all interactive areas are registered to this array in the moment player walks in them
var can_interact : bool = true


func register_area(area: InteractionArea) -> void:
	active_areas.push_back(area)


func unregister_area(area: InteractionArea) -> void:
	var idx = active_areas.find(area)
	if idx != -1:
		active_areas.remove_at(idx)


func _process(_delta) -> void:
	#decide which area is closest to player - it's label will be displayed
	if active_areas.size() > 0 && can_interact:
		active_areas.sort_custom(_sort_by_distance_to_player)
		label.text = base_text + active_areas[0].action_name
		label.global_position = active_areas[0].global_position + OFFSET
		label.show()
	else:
		label.hide()


func _sort_by_distance_to_player(area1, area2) -> bool:
	var area1_to_player = player.global_position.distance_to(area1.global_position)
	var area2_to_player = player.global_position.distance_to(area2.global_position)
	return area1_to_player < area2_to_player


func _input(event) -> void:
	if event.is_action_pressed("interact") && can_interact:
		if active_areas.size() > 0:
			#zavora
			can_interact = false
			label.hide()
			
			await active_areas[0].interact.call()
			
			can_interact = true
