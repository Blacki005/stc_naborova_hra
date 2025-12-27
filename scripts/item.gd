extends Node2D

var item_name
var item_quantity

func add_item_quantity(amount_to_add) -> void:
		item_quantity += amount_to_add
		$Label.text = str(item_quantity)


func set_item(nm : String, qt : int) -> void:
	item_name = nm
	item_quantity = qt
	$TextureRect.texture = load("res://images/items/" + item_name + ".png")
	
	var stack_size = int(JsonData.item_data[item_name]["StackSize"])
	if stack_size == 1:
		$Label.visible = false #non-stackable items do not have visible label
	else:
		$Label.visible = true
		$Label.text = str(item_quantity)


func decrease_item_quantity(amount_to_remove : int) -> void:
	item_quantity -= amount_to_remove
	$Label.text = str(item_quantity)
