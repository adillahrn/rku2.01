extends Node2D

@onready var hover_sfx: AudioStreamPlayer = $HoverSFX
@onready var button_manager: Node = $Button_manager

func _ready() -> void:
	AudioManager.play_bgm("res://assets/music/bgm_opening_landing1.mp3")
	# Hubungkan signal mouse_entered ke semua button di dalam Button_manager
	for button in button_manager.get_children():
		if button is Button:
			button.mouse_entered.connect(_on_button_mouse_entered)

func _on_button_mouse_entered() -> void:
	if hover_sfx:
		# Random pitch sedikit agar suara tidak terlalu kaku saat di-hover cepat
		hover_sfx.pitch_scale = randf_range(0.9, 1.1)
		hover_sfx.play()

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/opening_cutscene.tscn")

func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/rku.tscn")

func _on_how_to_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/htp.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
