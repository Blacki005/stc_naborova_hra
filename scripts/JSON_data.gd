extends Node

var item_data: Dictionary

func _ready() -> void:
	item_data = LoadData("res://data/item_data.json")


#loads data from JSON and returns them as dictionary
func LoadData(file_path : String) -> Dictionary:
	var json_string: String = FileAccess.get_file_as_string(file_path)
	if json_string == "":
		return {}
	var json = JSON.new()
	if json.parse(json_string) != OK:
		return {}
	return json.get_data()
