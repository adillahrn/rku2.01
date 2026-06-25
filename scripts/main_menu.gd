extends Node2D


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_how_to_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/htp.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
