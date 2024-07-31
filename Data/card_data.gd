class_name CardDataResource extends Resource

@export var image : Texture
@export var image_scaling : Vector2 = Vector2.ONE
@export var title : String = "Untitled"
@export_enum("Lead", "Tin", "Iron", "Copper", "Quicksilver", "Silver", "Gold",) var metal_type : String = "Lead"
@export_enum("Add/Subtract", "Multiply/Divide") var effect_type : String = "Add/Subtract"
