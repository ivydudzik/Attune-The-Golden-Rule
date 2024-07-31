@tool
class_name Metal extends Node2D

@export_enum("Lead", "Tin", "Iron", "Copper", "Quicksilver", "Silver", "Gold",) var metal_type : String = "Lead"

@onready var sprite : Sprite2D = $Sprite

func _ready() -> void:
	sprite.texture = load("res://Art/Metals/" + str(metal_type) + ".png")
