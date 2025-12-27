extends Node2D

@onready var path = $racing_path
@onready var path_follow = $racing_path/PathFollow2D

func get_path_direction(pos):
	#get closest point on path2D to the agent
	var offset = path.curve.get_closest_offset(pos)
	path_follow.progress = offset
	#vraci bod o trochu posonuty dopredu oproti tomu, ktery je na path2D nejbliz
	#problem = tohle vraci smer cesty, ne cestu samotnou - nesnazi se na ni vratit
	return path_follow.transform.x
