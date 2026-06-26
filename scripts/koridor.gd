extends Node2D

var player: Player = null
var camera: Camera2D = null
var fade_rect: ColorRect = null

func _ready() -> void:
	# Set baseline environment redup kebiruan pas start
	self.modulate = Color(0.8, 0.8, 0.95)
	
	# Instance Player
	var player_scene = load("res://scenes/player.tscn")
	if player_scene:
		player = player_scene.instantiate()
		player.position = Vector2(60, 240) # Posisi keluar dari pintu RKU di kiri
		player.has_bag = DialogueManager.player_has_bag
		add_child(player)
		player.can_move = false # Kunci kontrol sementara pas transition masuk
		
	# Instance Camera2D dan ikuti player
	camera = Camera2D.new()
	# Set limit agar kamera tidak scroll keluar batas koridor (1056x384)
	camera.limit_left = 0
	camera.limit_right = 1015
	camera.limit_top = 0
	camera.limit_bottom = 384
	add_child(camera)
	
	# Tambah CanvasLayer & ColorRect buat screen transition (Fade In)
	var screen_effects = CanvasLayer.new()
	add_child(screen_effects)
	
	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 1) # Mulai dari hitam pekat
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_effects.add_child(fade_rect)
	
	# Nonaktifkan collision dari TileSet background agar player tidak menabrak ubin dinding yang salah letak
	var bg_layer = $background
	if bg_layer and bg_layer.tile_set:
		bg_layer.tile_set.set_physics_layer_collision_layer(0, 0)
		bg_layer.tile_set.set_physics_layer_collision_mask(0, 0)
		
	# Inisialisasi padding
	setup_boundaries()
	
	# Transisi masuk: Fade in selama 1.0 detik
	var fade_tween = create_tween()
	fade_tween.tween_property(fade_rect, "color", Color(0, 0, 0, 0), 1.0)
	await fade_tween.finished
	fade_rect.visible = false
	
	# Balikin kontrol gerak ke player
	if is_instance_valid(player):
		player.can_move = true

func _process(_delta: float) -> void:
	if is_instance_valid(player):
		camera.position = player.position

func setup_boundaries() -> void:
	# Ukuran koridor 1056x384. Batas atas jalan koridor disesuaikan agar tidak menembus dinding atas (y=210)
	var left = 0.0
	var right = 1015.0
	var top = 210.0
	var bottom = 384.0
	
	# Buat StaticBody2D
	var boundaries = StaticBody2D.new()
	boundaries.name = "ScreenBoundaries"
	add_child(boundaries)
	
	# Tambahkan collision shape untuk masing-masing sisi
	
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
