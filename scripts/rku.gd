extends Node2D

@onready var camera: Camera2D = $Camera2D
@onready var player: Player = $player
@onready var fade_rect: ColorRect = $ScreenEffects/FadeRect

var is_flickering: bool = true
var camera_follow_player: bool = false
var interact_prompt: Sprite2D = null
var quest_ui = null

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
		
	# set batas layar untuk membatasi pergerakan player
	setup_screen_boundaries()
	
	# inisialisasi petunjuk interaksi pintu keluar
	create_interact_prompt()
	
	# Inisialisasi QuestUI
	var quest_ui_scene = load("res://scenes/quest_ui.tscn")
	if quest_ui_scene:
		quest_ui = quest_ui_scene.instantiate()
		add_child(quest_ui)
	
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
	
	# Set quest keluar dari kelas
	if quest_ui:
		quest_ui.set_quest("☐ Leave the classroom")
	
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
		
	# Update visibility petunjuk interaksi pintu keluar
	if is_instance_valid(player) and player.can_move and not DialogueManager.is_dialogue_active:
		if abs(player.position.x - 576.0) <= 25.0 and player.position.y >= 133.0 and player.position.y <= 200.0:
			if interact_prompt:
				interact_prompt.visible = true
				# Animasi melayang naik-turun halus (micro-animation)
				var time = Time.get_ticks_msec() / 1000.0
				interact_prompt.position.y = 125.0 + sin(time * 5.0) * 3.0
		else:
			if interact_prompt:
				interact_prompt.visible = false
	else:
		if interact_prompt:
			interact_prompt.visible = false

func flicker_lights() -> void:
	while is_flickering:
		# nunggu waktu random sebelum lampu kedip lagi
		await get_tree().create_timer(randf_range(0.4, 1.5)).timeout
		if not is_flickering or not is_instance_valid(self):
			break
			
		# kedip dua kali (redupin terus balikin ke redup kebiruan baseline)
		if not is_instance_valid(self): return
		self.modulate = Color(0.5, 0.5, 0.65)
		await get_tree().create_timer(0.06).timeout
		if not is_instance_valid(self): return
		self.modulate = Color(0.8, 0.8, 0.95)
		await get_tree().create_timer(0.05).timeout
		if not is_instance_valid(self): return
		self.modulate = Color(0.5, 0.5, 0.65)
		await get_tree().create_timer(0.08).timeout
		if not is_instance_valid(self): return
		self.modulate = Color(0.8, 0.8, 0.95)


func setup_screen_boundaries() -> void:
	var bg_sprite = $Sprite2D
	if not bg_sprite or not bg_sprite.texture:
		return
		
	var texture_size = bg_sprite.texture.get_size()
	var pos = bg_sprite.position
	
	# Hitung batas luar berdasarkan ukuran background sprite (576x384)
	var left = pos.x - texture_size.x / 2
	var right = pos.x + texture_size.x / 2
	var top = 135.0
	var bottom = pos.y + texture_size.y / 2
	
	# Buat StaticBody2D baru untuk batas layar
	var boundaries = StaticBody2D.new()
	boundaries.name = "ScreenBoundaries"
	add_child(boundaries)
	
	# Tambahkan collision shape untuk masing-masing sisi (Kiri, Kanan, Atas, Bawah)
	# Menggunakan SegmentShape2D agar pemain tidak bisa keluar dari batas background
	
	# Kiri
	var left_shape = CollisionShape2D.new()
	var left_segment = SegmentShape2D.new()
	left_segment.a = Vector2(left, top)
	left_segment.b = Vector2(left, bottom)
	left_shape.shape = left_segment
	boundaries.add_child(left_shape)
	
	# Kanan
	var right_shape = CollisionShape2D.new()
	var right_segment = SegmentShape2D.new()
	right_segment.a = Vector2(right, top)
	right_segment.b = Vector2(right, bottom)
	right_shape.shape = right_segment
	boundaries.add_child(right_shape)
	
	# Atas
	var top_shape = CollisionShape2D.new()
	var top_segment = SegmentShape2D.new()
	top_segment.a = Vector2(left, top)
	top_segment.b = Vector2(right, top)
	top_shape.shape = top_segment
	boundaries.add_child(top_shape)
	
	# Bawah
	var bottom_shape = CollisionShape2D.new()
	var bottom_segment = SegmentShape2D.new()
	bottom_segment.a = Vector2(left, bottom)
	bottom_segment.b = Vector2(right, bottom)
	bottom_shape.shape = bottom_segment
	boundaries.add_child(bottom_shape)


func create_interact_prompt() -> void:
	interact_prompt = Sprite2D.new()
	var tex = load("res://assets/images/ui/enter room.png")
	if tex:
		interact_prompt.texture = tex
	# Posisikan sedikit di atas pintu
	interact_prompt.position = Vector2(550, 130)
	interact_prompt.visible = false
	add_child(interact_prompt)


func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(player) or not player.can_move or DialogueManager.is_dialogue_active:
		return
		
	var is_interact = false
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		is_interact = true
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E or event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			is_interact = true
			
	if is_interact:
		if abs(player.position.x - 576.0) <= 25.0 and player.position.y >= 133.0 and player.position.y <= 200.0:
			get_viewport().set_input_as_handled()
			exit_classroom()


func exit_classroom() -> void:
	player.can_move = false
	DialogueManager.player_has_bag = player.has_bag
	DialogueManager.player_has_key = player.has_key
	if fade_rect:
		fade_rect.visible = true
		var fade_tween = create_tween()
		fade_tween.tween_property(fade_rect, "color", Color(0, 0, 0, 1), 1.0)
		await fade_tween.finished
	get_tree().change_scene_to_file("res://scenes/koridor.tscn")
