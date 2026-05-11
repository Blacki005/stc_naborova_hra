extends "res://scripts/levels/level_base.gd"

@onready var pracovnik_rekrutacniho_pracoviste = $pracovnik_rekrutacniho_pracoviste

#returns count of enemies existing in the tree
func get_enemies_cnt() -> int:
	return get_tree().get_node_count_in_group("enemy")

func _ready() -> void:
	PlayerInventory.connect("inventory_updated", self._on_inventory_updated)

func _on_inventory_updated() -> void:
	if PlayerInventory.has_item("Pen"):
		pracovnik_rekrutacniho_pracoviste.start_id = "CONTINUE"


func _on_child_exiting_tree(exiting_child: Node) -> void:
	if exiting_child.is_in_group("enemy"):
		if get_enemies_cnt() <= 1:
			pracovnik_rekrutacniho_pracoviste.start_id = "FINISHED"
