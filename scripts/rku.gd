extends Node2D

@onready var camera: Camera2D = $Camera2D
@onready var player: Player = $player
@onready var fade_rect: ColorRect = $ScreenEffects/FadeRect

var is_flickering: bool = true
var camera_follow_player: bool = false

# dialog opening Arga
var dialogue_lines: Array[Dictionary] = [
	{"speaker": "Arga", "expression": "confused", "text": "...What?"},
	{"speaker": "Arga", "expression": "mikir", "text": "Did I really fall asleep here?"},
	{"speaker": "Arga", "expression": "bingung", "text": "Why is it so dark?"},
	{"speaker": "Arga", "expression": "sedih", "text": "Where am I?"},
	{"speaker": "Arga", "expression": "confused", "text": "...RKU 2.01?"},
	{"speaker": "Arga", "expression": "confused", "text": "Wait."},
	{"speaker": "Arga", "expression": "confused", "text": "2:01 AM?"},
	{"speaker": "Arga", "expression": "sedih", "text": "You've got to be kidding me."},
	{"speaker": "Arga", "expression": "sedih", "text": "Did everyone seriously leave me here?"},
	{"speaker": "Arga", "expression": "mikir", "text": "Okay."},
	{"speaker": "Arga", "expression": "mikir", "text": "I need to get out."}
]

func _ready() -> void:
	# cek error biar ga crash kalau nodenya ilang
	if not has_node("player") or not has_node("Camera2D"):
		push_error("player or Camera2D node not found in Rku scene!")
		return
		
	# set baseline environment redup kebiruan pas start
	self.modulate = Color(0.8, 0.8, 0.95)
	
	# matiin gerak player pas opening
	player.can_move = false
	
	# set camera ke depan kelas dan zoom in biar bisa pan di dalem batas
	camera.position = Vector2(288, 100)
	camera.zoom = Vector2(1.6, 1.6)
	
	# batesin kamera biar ga keluar dari background
	var bg_sprite = $Sprite2D
	if bg_sprite and bg_sprite.texture:
		var texture_size = bg_sprite.texture.get_size()
		var pos = bg_sprite.position
		camera.limit_left = int(pos.x - texture_size.x / 2)
		camera.limit_top = int(pos.y - texture_size.y / 2)
		camera.limit_right = int(pos.x + texture_size.x / 2)
		camera.limit_bottom = int(pos.y + texture_size.y / 2)
	
	# transisi masuk (fade in dari hitam perlahan selama 1.5 detik)
	if fade_rect:
		fade_rect.color = Color(0, 0, 0, 1)
		fade_rect.visible = true
		var fade_tween = create_tween()
		fade_tween.tween_property(fade_rect, "color", Color(0, 0, 0, 0), 1.5)
	
	# mulai lampu kedap kedip
	flicker_lights()
	
	# gerakin camera ke player selama 3.5 detik
	var pan_tween = create_tween()
	pan_tween.tween_property(camera, "position", player.position, 3.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await pan_tween.finished
	
	# zoom out camera ke normal selama 1.5 detik
	var zoom_tween = create_tween()
	zoom_tween.tween_property(camera, "zoom", Vector2(1.0, 1.0), 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await zoom_tween.finished
	
	# nunggu bentar sebelum dialog
	await get_tree().create_timer(0.5).timeout
	
	# trigger dialogue pembuka
	await DialogueManager.start_dialogue(dialogue_lines)
	
	# matiin lampu kedap kedip, set lampu ke redup kebiruan yang konstan (baseline)
	is_flickering = false
	self.modulate = Color(0.8, 0.8, 0.95)
	
	# nunggu bentar
	await get_tree().create_timer(0.3).timeout
	
	# balikin kontrol ke player dan pasang camera ke player
	player.can_move = true
	camera_follow_player = true

func _process(_delta: float) -> void:
	if camera_follow_player and is_instance_valid(player):
		camera.position = player.position

func flicker_lights() -> void:
	while is_flickering:
		# nunggu waktu random sebelum lampu kedip lagi
		await get_tree().create_timer(randf_range(0.4, 1.5)).timeout
		if not is_flickering:
			break
			
		# kedip dua kali (redupin terus balikin ke redup kebiruan baseline)
		self.modulate = Color(0.5, 0.5, 0.65)
		await get_tree().create_timer(0.06).timeout
		self.modulate = Color(0.8, 0.8, 0.95)
		await get_tree().create_timer(0.05).timeout
		self.modulate = Color(0.5, 0.5, 0.65)
		await get_tree().create_timer(0.08).timeout
		self.modulate = Color(0.8, 0.8, 0.95)
