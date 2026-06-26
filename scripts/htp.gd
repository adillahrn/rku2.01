extends Control

func _ready() -> void:
	# nyalain input processing
	set_process_input(true)

func _input(event: InputEvent) -> void:
	# kalau player klik mouse atau pencet keyboard apa aja, balikin ke main menu
	var is_back = false
	if event is InputEventMouseButton and event.pressed:
		is_back = true
	elif event is InputEventKey and event.pressed:
		is_back = true
		
	if is_back:
		get_viewport().set_input_as_handled()
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
