extends CanvasLayer

signal computer_closed
signal access_card_obtained

enum State { WELCOME, LOGIN, LOADING_PASSWORD, QUIZ_1, QUIZ_2, QUIZ_3, LOADING_QUIZ, SUCCESS, FAILURE }

var current_state: State = State.WELCOME
var password_correct: bool = false
var score: int = 0

var questions: Array[Dictionary] = [
	{
		"title": "Question 1 / 3",
		"text": "Which number is represented by 1001\u2082?",
		"choices": ["A. 7", "B. 8", "C. 9", "D. 10"],
		"correct": 2
	},
	{
		"title": "Question 2 / 3",
		"text": "Which Git command uploads your local commits to GitHub?",
		"choices": ["A. git clone", "B. git pull", "C. git push", "D. git status"],
		"correct": 2
	},
	{
		"title": "Question 3 / 3",
		"text": "If TRUE AND FALSE, the result is...",
		"choices": ["A. TRUE", "B. FALSE", "C. NULL", "D. ERROR"],
		"correct": 1
	}
]

var bg_light: TextureRect
var bg_dark: TextureRect
var win_title: Label
var win_body: VBoxContainer
var body_text: Label
var sub_text: Label
var choice_container: VBoxContainer
var action_btn: Button
var loading_img: TextureRect
var lock_img: TextureRect
var password_input: LineEdit

func _ready() -> void:
	visible = false
	bg_light = get_node_or_null("BgLight")
	bg_dark = get_node_or_null("BgDark")

	var window_content = get_node_or_null("WindowContent")
	if window_content:
		win_title = window_content.get_node_or_null("TitleLabel")
		win_body = window_content.get_node_or_null("Body")
		body_text = window_content.get_node_or_null("Body/BodyText")
		sub_text = window_content.get_node_or_null("Body/SubText")
		choice_container = window_content.get_node_or_null("Body/ChoiceContainer")
		loading_img = window_content.get_node_or_null("Body/LoadingImg")
		lock_img = window_content.get_node_or_null("Body/LockImg")
		password_input = window_content.get_node_or_null("Body/PasswordInput")
		action_btn = window_content.get_node_or_null("ActionBtn")
	else:
		win_title = find_child("TitleLabel", true, false) as Label
		win_body = find_child("Body", true, false) as VBoxContainer
		body_text = find_child("BodyText", true, false) as Label
		sub_text = find_child("SubText", true, false) as Label
		choice_container = find_child("ChoiceContainer", true, false) as VBoxContainer
		loading_img = find_child("LoadingImg", true, false) as TextureRect
		lock_img = find_child("LockImg", true, false) as TextureRect
		password_input = find_child("PasswordInput", true, false) as LineEdit
		action_btn = find_child("ActionBtn", true, false) as Button

	if not win_title:
		push_error("[computer_ui] Missing node WindowContent/TitleLabel")
	if not body_text:
		push_error("[computer_ui] Missing node WindowContent/Body/BodyText")
	if not action_btn:
		push_error("[computer_ui] Missing node WindowContent/ActionBtn")
	if not loading_img:
		push_error("[computer_ui] Missing node WindowContent/Body/LoadingImg")

	if action_btn:
		action_btn.pressed.connect(_on_action_btn_pressed)
		
	if password_input:
		# Style the password LineEdit input box retro
		var normal_sb = _create_retro_stylebox(Color(0.85, 0.85, 0.9), Color(0.3, 0.3, 0.4))
		password_input.add_theme_stylebox_override("normal", normal_sb)
		var font = load("res://assets/fonts/Nintendo-DS-BIOS-vasified.ttf")
		if font:
			password_input.add_theme_font_override("font", font)
		password_input.add_theme_font_size_override("font_size", 18)
		password_input.text_submitted.connect(_on_password_submitted)

func open() -> void:
	score = 0
	password_correct = false
	visible = true
	_show_state(State.WELCOME)

func close() -> void:
	visible = false
	print("[DEBUG COMPUTER] close() called. Emitting computer_closed.")
	computer_closed.emit()

func _create_retro_stylebox(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = border_color
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb

func _show_state(state: State) -> void:
	current_state = state

	# Reset visibility and Modulation
	if win_title:
		win_title.modulate = Color(1, 1, 1) # White text for light theme titlebar
	if body_text:
		body_text.visible = true
		body_text.modulate = Color(0.05, 0.05, 0.15) # Dark color for light theme body
	if sub_text:
		sub_text.visible = false
		sub_text.modulate = Color(0.05, 0.05, 0.15) # Dark color for light theme subtext
	if password_input:
		password_input.visible = false
	if choice_container:
		choice_container.visible = false
	if action_btn:
		action_btn.visible = false
	if loading_img:
		loading_img.visible = false
	if lock_img:
		lock_img.visible = false

	# Setup background and action button theme based on State category (Light/Dark theme)
	match state:
		State.WELCOME, State.LOGIN, State.LOADING_PASSWORD, State.QUIZ_1, State.QUIZ_2, State.QUIZ_3, State.LOADING_QUIZ:
			if bg_dark:
				bg_dark.visible = false
			if bg_light:
				bg_light.visible = true
			if action_btn:
				var light_normal = _create_retro_stylebox(Color(0.75, 0.75, 0.8), Color(0.3, 0.3, 0.4))
				var light_hover = _create_retro_stylebox(Color(0.85, 0.85, 0.9), Color(0.4, 0.4, 0.6))
				var light_pressed = _create_retro_stylebox(Color(0.6, 0.6, 0.65), Color(0.2, 0.2, 0.3))
				var light_focus = StyleBoxEmpty.new()
				action_btn.add_theme_stylebox_override("normal", light_normal)
				action_btn.add_theme_stylebox_override("hover", light_hover)
				action_btn.add_theme_stylebox_override("pressed", light_pressed)
				action_btn.add_theme_stylebox_override("focus", light_focus)
				action_btn.add_theme_color_override("font_color", Color(0.05, 0.05, 0.15))
				action_btn.add_theme_color_override("font_hover_color", Color(0.0, 0.0, 0.2))
				action_btn.add_theme_color_override("font_pressed_color", Color(0.0, 0.0, 0.0))
				action_btn.add_theme_color_override("font_focus_color", Color(0.05, 0.05, 0.15))
		State.SUCCESS, State.FAILURE:
			if bg_dark:
				bg_dark.visible = true
			if bg_light:
				bg_light.visible = false
			if action_btn:
				var dark_normal = _create_retro_stylebox(Color(0.1, 0.2, 0.1), Color(0.2, 0.8, 0.3))
				var dark_hover = _create_retro_stylebox(Color(0.15, 0.3, 0.15), Color(0.3, 1.0, 0.4))
				var dark_pressed = _create_retro_stylebox(Color(0.05, 0.1, 0.05), Color(0.1, 0.6, 0.2))
				var dark_focus = StyleBoxEmpty.new()
				action_btn.add_theme_stylebox_override("normal", dark_normal)
				action_btn.add_theme_stylebox_override("hover", dark_hover)
				action_btn.add_theme_stylebox_override("pressed", dark_pressed)
				action_btn.add_theme_stylebox_override("focus", dark_focus)
				action_btn.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
				action_btn.add_theme_color_override("font_hover_color", Color(0.5, 1.0, 0.6))
				action_btn.add_theme_color_override("font_pressed_color", Color(0.2, 0.8, 0.3))
				action_btn.add_theme_color_override("font_focus_color", Color(0.2, 1.0, 0.3))

	match state:
		State.WELCOME:
			if win_title:
				win_title.text = "FMIPA Computer System"
			if body_text:
				body_text.text = "Welcome, User.\n\nFMIPA Computer Laboratory\n\n-"
			if action_btn:
				action_btn.visible = true
				action_btn.text = "Continue >"
		State.LOGIN:
			score = 0
			if win_title:
				win_title.text = "System Authentication"
			if body_text:
				body_text.text = "Student verification required.\nPlease enter password:"
			if password_input:
				password_input.visible = true
				password_input.text = ""
				password_input.grab_focus()
			if action_btn:
				action_btn.visible = true
				action_btn.text = "SUBMIT"
		State.LOADING_PASSWORD:
			if win_title:
				win_title.text = "System Authentication"
			if body_text:
				body_text.text = "Verifying password...\n\nPlease wait..."
			if loading_img:
				loading_img.visible = true
				_run_loading_password()
			else:
				if password_correct:
					_show_state(State.QUIZ_1)
				else:
					_show_state(State.FAILURE)
		State.QUIZ_1, State.QUIZ_2, State.QUIZ_3:
			var q_idx = state - State.QUIZ_1
			var q = questions[q_idx]
			if win_title:
				win_title.text = q["title"]
			if body_text:
				body_text.text = q["text"]
			if choice_container:
				choice_container.visible = true
				_build_choices(q["choices"], q["correct"])
		State.LOADING_QUIZ:
			if win_title:
				win_title.text = "System Authentication"
			if body_text:
				body_text.text = "Checking verification answers...\n\nPlease wait..."
			if loading_img:
				loading_img.visible = true
				_run_loading_quiz()
			else:
				if score >= 3:
					_show_state(State.SUCCESS)
				else:
					_show_state(State.FAILURE)
		State.SUCCESS:
			if win_title:
				win_title.text = "FMIPA System Terminal"
				win_title.modulate = Color(0.2, 1.0, 0.3)
			if body_text:
				body_text.modulate = Color(0.2, 1.0, 0.3)
				body_text.text = "I'm always behind you.\nYou must be faster.\nYou're almost late."
			if action_btn:
				action_btn.visible = true
				action_btn.text = "Close"
			print("[DEBUG COMPUTER] State SUCCESS reached. Emitting access_card_obtained.")
			access_card_obtained.emit()
		State.FAILURE:
			if win_title:
				win_title.text = "Authentication System"
				win_title.modulate = Color(0.2, 1.0, 0.3)
			if body_text:
				body_text.modulate = Color(0.2, 1.0, 0.3)
				body_text.text = "VERIFICATION FAILED\n\nAccess Denied.\nIncorrect credentials detected."
			if lock_img:
				lock_img.visible = true
				lock_img.modulate = Color(1.0, 0.3, 0.3) # Modulate lock to red on failure!
			if action_btn:
				action_btn.visible = true
				action_btn.text = "Retry"

func _on_password_submitted(text: String) -> void:
	if current_state == State.LOGIN:
		_submit_password(text)

func _submit_password(text: String) -> void:
	if text.strip_edges().to_lower() == "student":
		password_correct = true
	else:
		password_correct = false
	_show_state(State.LOADING_PASSWORD)

func _build_choices(choices: Array, correct_idx: int) -> void:
	for child in choice_container.get_children():
		child.queue_free()
	
	var font = load("res://assets/fonts/Nintendo-DS-BIOS-vasified.ttf")
	
	for i in choices.size():
		var btn = Button.new()
		btn.text = choices[i]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		# Stylized retro button overrides for choices
		var normal_sb = _create_retro_stylebox(Color(0.75, 0.75, 0.8), Color(0.3, 0.3, 0.4))
		var hover_sb = _create_retro_stylebox(Color(0.85, 0.85, 0.9), Color(0.4, 0.4, 0.6))
		var pressed_sb = _create_retro_stylebox(Color(0.6, 0.6, 0.65), Color(0.2, 0.2, 0.3))
		var focus_sb = StyleBoxEmpty.new()
		
		btn.add_theme_stylebox_override("normal", normal_sb)
		btn.add_theme_stylebox_override("hover", hover_sb)
		btn.add_theme_stylebox_override("pressed", pressed_sb)
		btn.add_theme_stylebox_override("focus", focus_sb)
		
		btn.add_theme_color_override("font_color", Color(0.05, 0.05, 0.15))
		btn.add_theme_color_override("font_hover_color", Color(0.0, 0.0, 0.2))
		btn.add_theme_color_override("font_pressed_color", Color(0.0, 0.0, 0.0))
		btn.add_theme_color_override("font_focus_color", Color(0.05, 0.05, 0.15))
		
		if font:
			btn.add_theme_font_override("font", font)
		btn.add_theme_font_size_override("font_size", 18)
		btn.pressed.connect(_on_choice_pressed.bind(i, correct_idx))
		choice_container.add_child(btn)

func _on_choice_pressed(chosen: int, correct: int) -> void:
	if chosen == correct:
		score += 1
	# Move to next quiz state or loading
	match current_state:
		State.QUIZ_1: _show_state(State.QUIZ_2)
		State.QUIZ_2: _show_state(State.QUIZ_3)
		State.QUIZ_3: _show_state(State.LOADING_QUIZ)

func _run_loading_password() -> void:
	if not loading_img:
		if password_correct:
			_show_state(State.QUIZ_1)
		else:
			_show_state(State.FAILURE)
		return

	# Spin animation on loading image via rotation
	var start_rotation = loading_img.rotation_degrees
	var tween = create_tween().set_loops(4)
	tween.tween_property(loading_img, "rotation_degrees", start_rotation + 360.0, 0.5)
	await tween.finished
	if password_correct:
		_show_state(State.QUIZ_1)
	else:
		_show_state(State.FAILURE)

func _run_loading_quiz() -> void:
	if not loading_img:
		if score >= 3:
			_show_state(State.SUCCESS)
		else:
			_show_state(State.FAILURE)
		return

	# Spin animation on loading image via rotation
	var start_rotation = loading_img.rotation_degrees
	var tween = create_tween().set_loops(4)
	tween.tween_property(loading_img, "rotation_degrees", start_rotation + 360.0, 0.5)
	await tween.finished
	if score >= 3:
		_show_state(State.SUCCESS)
	else:
		_show_state(State.FAILURE)

func _on_action_btn_pressed() -> void:
	match current_state:
		State.WELCOME:
			_show_state(State.LOGIN)
		State.LOGIN:
			if password_input:
				_submit_password(password_input.text)
		State.SUCCESS:
			close()
		State.FAILURE:
			_show_state(State.LOGIN)
