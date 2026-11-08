extends Node

signal return_requested(destination: String)

const STORY_PATH := "res://data/stories/chapter_01.json"
@export_file("*.json") var story_path: String = "res://data/stories/the_thirteenth_bell.json"
@onready var saves: Node = $SaveManager
@onready var story: Node = $StoryManager
@onready var dialogue: Control = $UI/HUD/DialogueUI
@onready var status: Label = $UI/HUD/Top/Rows/StatusLabel
@onready var error_label: Label = $UI/HUD/Top/Rows/ErrorLabel

func _ready() -> void:
    $UI/HUD/Top/Rows/Tools/TownButton.pressed.connect(func(): return_requested.emit("town"))
    $UI/HUD/Top/Rows/Tools/MenuButton.pressed.connect(func(): return_requested.emit("menu"))
    story.choices_requested.connect(dialogue.show_choices)
    dialogue.choice_selected.connect(story.choose)
    saves.save_notification.connect(_show_error)
    $UI/HUD/Top/Rows/Tools/SaveButton.pressed.connect(func(): saves.save_game(story))
    $UI/HUD/Top/Rows/Tools/LoadButton.pressed.connect(func(): saves.load_game(story))
    $UI/NewGameConfirmation.confirmed.connect(_replay)
    story.line_requested.connect(dialogue.show_line)
    story.line_requested.connect(_update_chapter)
    story.dialogue_finished.connect(dialogue.finish_dialogue)
    story.story_error.connect(_show_error)
    dialogue.continue_requested.connect(story.advance)
    $UI/HUD/Top/Rows/Tools/ReplayButton.pressed.connect(_confirm_new_game)
    $UI/HUD/Top/Rows/Tools/TestChoiceButton.pressed.connect(_test_state)
    $UI/HUD/Top/Rows/Tools/Speed.value_changed.connect(_set_speed)
    GameState.state_changed.connect(_update_status)
    _update_status()
    _replay()

func _replay() -> void:
    error_label.text = ""
    GameState.reset_new_game()
    story.load_story(story_path)

func _test_state() -> void:
    # Deliberately repeatable foundation diagnostic, NOT a narrative choice.
    GameState.change_player_stat("hp", -10)
    GameState.change_relationship("emilia", "trust", 10)
    GameState.set_story_flag("helped_emilia")
    GameState.record_choice("choice_help_emilia")

func _update_status(_category: String = "", _key: String = "", _value: Variant = null) -> void:
    status.text = "พลังชีวิต %d/%d   ·   ความไว้วางใจ %d   ·   ความรู้ %d   ·   ความกล้า %d" % [
        GameState.get_player_stat("hp"), GameState.get_player_stat("max_hp"),
        GameState.get_relationship("emilia", "trust"), GameState.get_player_stat("knowledge"),
        GameState.get_player_stat("courage")]

func _set_speed(value: float) -> void:
    dialogue.characters_per_second = value

func _show_error(message: String) -> void:
    error_label.text = message

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
        var fullscreen: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)
        get_viewport().set_input_as_handled()


func _confirm_new_game() -> void:
    $UI/NewGameConfirmation.popup_centered()

func _update_chapter(line: Dictionary) -> void:
    $UI/HUD/Top/Rows/Subtitle.text = line.get("chapter_title", "บทสนทนาทดสอบ")
