@tool
extends Node2D

@export_enum("Lead", "Tin", "Iron", "Copper", "Quicksilver", "Silver", "Gold",) var metal_type : String = "Lead"

@onready var sprite = $Sprite

func _ready():
	sprite.texture = load("res://Art/Metals/" + str(metal_type) + ".png")
