class_name CardDataResource extends Resource

@export var title : String = "Untitled"
@export_enum("Lead", "Tin", "Iron", "Copper", "Quicksilver", "Silver", "Gold",) var metal_type : String = "Lead"
@export_enum("Add/Subtract", "Multiply/Divide") var effect_type : String = "Add/Subtract"
