class_name Level extends Resource

@export var level : int
@export_enum("Lead", "Tin", "Iron", "Copper", "Quicksilver", "Silver", "Gold",) var goal_metal : String = "Lead"
@export var starting_cards : Array[CardDataResource]
@export var plays_per_infusion : int
@export var swaps_per_infusion : int
@export var total_infusions : int
