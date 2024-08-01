extends Node2D

const GAME : PackedScene = preload("res://Scenes/game.tscn")

func _on_play_button_pressed():
	get_tree().change_scene_to_packed(GAME)
