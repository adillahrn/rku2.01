extends Node2D

func _ready() -> void:
	AudioManager.play_bgm("res://assets/music/bgm_opening_landing1.mp3")

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/opening_cutscene.tscn")

func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/rku.tscn")

func _on_how_to_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/htp.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
