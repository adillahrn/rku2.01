extends Control

@onready var background: TextureRect = $Background
@onready var eyelid_top: ColorRect = $EyelidTop
@onready var eyelid_bottom: ColorRect = $EyelidBottom
@onready var flash_overlay: ColorRect = $FlashOverlay

var dialogue_lines: Array[Dictionary] = [
	{"speaker": "Arga", "expression": "bingung", "text": "It was all just a dream?"},
	{"speaker": "Arga", "expression": "kaget", "text": "I overslept ..."},
	{"speaker": "Arga", "expression": "panik", "text": "The GKV presentation!?"},
	{"speaker": "Arga", "expression": "panik", "text": "I'm not ready at all...."}
]

func _ready() -> void:
	# Hide mouse cursor if needed, or keep it
	# Start with eyelids closed (covering the screen) and a white flash overlay
	eyelid_top.size = Vector2(576, 192)
	eyelid_top.position = Vector2(0, 0)
	eyelid_bottom.size = Vector2(576, 192)
	eyelid_bottom.position = Vector2(0, 192)
	
	flash_overlay.color = Color(1, 1, 1, 0)
	flash_overlay.visible = true
	
	# Play peaceful or sleepy closing music
	AudioManager.play_bgm("res://assets/music/bgm_closing.mp3")
	
	# Start waking up sequence after a brief delay
	await get_tree().create_timer(1.5).timeout
	await run_waking_up_animation()

func run_waking_up_animation() -> void:
	# Blink 1: Open slightly, then close
	var tween1 = create_tween().set_parallel(true)
	tween1.tween_property(eyelid_top, "position:y", -40.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween1.tween_property(eyelid_bottom, "position:y", 232.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween1.finished
	
	await get_tree().create_timer(0.3).timeout
	
	var tween1_close = create_tween().set_parallel(true)
	tween1_close.tween_property(eyelid_top, "position:y", 0.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween1_close.tween_property(eyelid_bottom, "position:y", 192.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween1_close.finished
	
	await get_tree().create_timer(0.6).timeout
	
	# Blink 2: Open wider (with some white light/adjusting eyes), then close
	var tween2 = create_tween().set_parallel(true)
	tween2.tween_property(eyelid_top, "position:y", -90.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween2.tween_property(eyelid_bottom, "position:y", 282.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	flash_overlay.color = Color(1, 1, 1, 0.4)
	tween2.tween_property(flash_overlay, "color:a", 0.1, 0.8)
	await tween2.finished
	
	await get_tree().create_timer(0.4).timeout
	
	var tween2_close = create_tween().set_parallel(true)
	tween2_close.tween_property(eyelid_top, "position:y", 0.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween2_close.tween_property(eyelid_bottom, "position:y", 192.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween2_close.tween_property(flash_overlay, "color:a", 0.0, 0.25)
	await tween2_close.finished
	
	await get_tree().create_timer(0.8).timeout
	
	# Blink 3: Open completely, white flash adjusts to clear morning light
	var tween3 = create_tween().set_parallel(true)
	tween3.tween_property(eyelid_top, "position:y", -192.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween3.tween_property(eyelid_bottom, "position:y", 384.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	flash_overlay.color = Color(1, 1, 1, 1.0)
	tween3.tween_property(flash_overlay, "color:a", 0.0, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween3.finished
	
	# Clean up eyelids and flash overlay
	eyelid_top.visible = false
	eyelid_bottom.visible = false
	flash_overlay.visible = false
	
	# Wait a moment before dialog
	await get_tree().create_timer(0.5).timeout
	start_dialogue()

func start_dialogue() -> void:
	await DialogueManager.start_dialogue(dialogue_lines)
	
	# Transition back to main menu
	var fade_tween = create_tween()
	# Reuse flash_overlay for fade out to black
	flash_overlay.visible = true
	flash_overlay.color = Color(0, 0, 0, 0)
	fade_tween.tween_property(flash_overlay, "color", Color(0, 0, 0, 1), 1.5)
	await fade_tween.finished
	
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
