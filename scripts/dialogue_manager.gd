extends Node

signal dialogue_started
signal dialogue_ended

var is_dialogue_active: bool = false
var dialogue_box_scene = preload("res://scenes/dialogue_box.tscn")
var current_dialogue_box = null

var player_has_bag: bool = false
var player_has_key: bool = false
var spawn_at_labkom: bool = false

func start_dialogue(lines: Array) -> void:
	if is_dialogue_active:
		return
		
	is_dialogue_active = true
	dialogue_started.emit()
	
	# spawn dan tampilin dialogue box
	current_dialogue_box = dialogue_box_scene.instantiate()
	get_tree().root.add_child(current_dialogue_box)
	current_dialogue_box.start(lines)
	
	# nunggu dialogue selesai
	await current_dialogue_box.dialogue_finished
	
	current_dialogue_box.queue_free()
	current_dialogue_box = null
	is_dialogue_active = false
	dialogue_ended.emit()
