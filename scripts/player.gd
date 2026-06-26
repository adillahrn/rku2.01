class_name Player extends CharacterBody2D

@export var move_speed: float = 100.0
@export var run_speed: float = 170.0
@export var anim_fps: float = 8.0
@export var has_bag: bool = false
@export var has_key: bool = false

@onready var sprite: Sprite2D = $Sprite2D

var can_move: bool = true
var current_anim: String = ""
var frame_index: float = 0.0
var facing_direction: String = "down"
var anim_textures: Dictionary = {}

func _ready() -> void:
	_load_textures()
	_update_animation("idle", "down")

# fungsi buat load texture
func _load_textures() -> void:
	var base_path = "res://assets/images/karakter/"
	var suffixes = ["", "_tas"]
	var actions = [
		"idle_down", "idle_up", "idle_side",
		"walk_down", "walk_up", "walk_side",
		"run_down", "run_up", "run_side"
	]
	
	# loop buat masukin texture ke dictionary
	for action in actions:
		for suf in suffixes:
			var key = action + suf
			var path = base_path + key + ".png"
			if ResourceLoader.exists(path):
				anim_textures[key] = load(path)
			else:
				push_warning("Animation texture not found: " + path)

# fungsi buat ngereact input
func _physics_process(delta: float) -> void:
	# cek apakah bisa gerak atau nggak terutama buat cutscene atau dialogue
	if not can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_animation("idle", facing_direction)
		return
		
	# tahan SHIFT buat lari
	var is_running = Input.is_key_pressed(KEY_SHIFT)
	var current_speed = run_speed if is_running else move_speed
	
	# ngatur arah gerak
	var direction: Vector2 = Vector2.ZERO
	direction.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	direction.y = Input.get_action_strength("down") - Input.get_action_strength("up")

	# logic buat movement
	if direction.length() > 0:
		direction = direction.normalized()
		velocity = direction * current_speed
		
		# Tentukan arah
		if abs(direction.x) > abs(direction.y):
			facing_direction = "side"
			sprite.flip_h = (direction.x > 0)
		else:
			if direction.y > 0:
				facing_direction = "down"
			else:
				facing_direction = "up"
				
		var state = "run" if is_running else "walk"
		_update_animation(state, facing_direction)
	else:
		velocity = Vector2.ZERO
		_update_animation("idle", facing_direction)

	move_and_slide()
	
	# Logger tabrakan untuk debug di console editor
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider:
			print("[DEBUG COLLISION] Menabrak: ", collider.name, " di koordinat global: ", collision.get_position(), " | Normal: ", collision.get_normal())
			
	_animate(delta)

# fungsi buat ngatur animasi
func _update_animation(state: String, dir: String) -> void:
	var key = state + "_" + dir
	if has_bag:
		key += "_tas"
		
	if not anim_textures.has(key):
		key = state + "_" + dir
		
	if current_anim == key:
		return
		
	current_anim = key
	if anim_textures.has(key):
		sprite.texture = anim_textures[key]
		# Walk and Run animations are 4 frames, Idle is 1 frame
		if state == "walk" or state == "run":
			sprite.hframes = 4
		else:
			sprite.hframes = 1
		sprite.frame = 0
		frame_index = 0.0
	else:
		sprite.texture = null

# fungsi buat ngatur animasi juga
func _animate(delta: float) -> void:
	if sprite.hframes > 1:
		frame_index += delta * anim_fps
		if frame_index >= sprite.hframes:
			frame_index = 0.0
		sprite.frame = int(frame_index)
