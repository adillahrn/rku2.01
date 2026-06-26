extends CanvasLayer

@onready var quest_box: TextureRect = $Control/QuestBox
@onready var quest_text: RichTextLabel = $Control/QuestBox/QuestText

func _ready() -> void:
	if quest_box:
		quest_box.visible = false

func set_quest(text: String) -> void:
	if quest_text:
		quest_text.text = text
	if quest_box:
		quest_box.visible = true

func hide_quest() -> void:
	if quest_box:
		quest_box.visible = false
