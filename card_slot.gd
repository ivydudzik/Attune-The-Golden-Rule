@tool
extends Panel

@export_enum("Catalyst", "Dormant") var slot_type : String = "Dormant"

func _ready():
	#if Engine.is_editor_hint():
		match slot_type:
			"Catalyst":
				$"Catalyst Marker".visible = true
			"Dormant":
				$"Catalyst Marker".visible = false
