extends Node2D


func _on_online_button_pressed():
	get_tree().change_scene_to_file("res://game.tscn")
