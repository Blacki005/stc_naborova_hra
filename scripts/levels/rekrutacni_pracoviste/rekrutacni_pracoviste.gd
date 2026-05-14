extends "res://scripts/levels/level_base.gd"

@onready var pracovnik_rekrutacniho_pracoviste = $pracovnik_rekrutacniho_pracoviste


var enemies_cnt : int = 0

#returns count of enemies existing in the tree
func get_enemies_cnt() -> int:
	var cnt : int = 0
	for child in get_children(false):
		if child.is_in_group("enemy"):
			cnt += 1
	return cnt

func _ready() -> void:
	PlayerInventory.connect("inventory_updated", self._on_inventory_updated)
	enemies_cnt = get_enemies_cnt()

func _on_inventory_updated() -> void:
	if PlayerInventory.has_item("Pen") and enemies_cnt:
		pracovnik_rekrutacniho_pracoviste.start_id = "CONTINUE"


func _on_child_exiting_tree(exiting_child: Node) -> void:
	if exiting_child.is_in_group("enemy"):
		enemies_cnt -= 1
		if enemies_cnt <= 0:
			pracovnik_rekrutacniho_pracoviste.start_id = "FINISHED"
