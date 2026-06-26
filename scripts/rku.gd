extends Node2D

@onready var camera: Camera2D = $Camera2D
@onready var player: Player = $player

var is_flickering: bool = true
var camera_follow_player: bool = false

func _ready() -> void:
	# cek error biar ga crash kalau nodenya ilang
	if not has_node("player") or not has_node("Camera2D"):
		push_error("player or Camera2D node not found in Rku scene!")
		return
		
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
	
	# matiin lampu kedap kedip, balikin lampu normal
	is_flickering = false
	self.modulate = Color(1, 1, 1)
	
	# nunggu bentar
	await get_tree().create_timer(0.8).timeout
	
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
			
		# kedip dua kali (redupin terus balikin normal)
		self.modulate = Color(0.65, 0.65, 0.75)
		await get_tree().create_timer(0.06).timeout
		self.modulate = Color(1.0, 1.0, 1.0)
		await get_tree().create_timer(0.05).timeout
		self.modulate = Color(0.65, 0.65, 0.75)
		await get_tree().create_timer(0.08).timeout
		self.modulate = Color(1.0, 1.0, 1.0)
