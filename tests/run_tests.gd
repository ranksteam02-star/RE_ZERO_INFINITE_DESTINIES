extends Node

var checks: int = 0
var failures: int = 0
var finished_count: int = 0
var main: Node
var story: Node
var ui: Control
var saves: Node

func check(condition: bool, title: String) -> void:
    checks += 1
    if condition:
        print("PASS: " + title)
    else:
        failures += 1
        printerr("FAIL: " + title)

func _ready() -> void:
    call_deferred("run")

func run() -> void:
    main = load("res://scenes/main/Main.tscn").instantiate()
    main.story_path = main.STORY_PATH
    add_child(main)
    story = main.get_node("StoryManager")
    ui = main.get_node("UI/HUD/DialogueUI")
    saves = main.get_node("SaveManager")
    saves.save_path = "user://automated_test_slot.json"
    clean_test_files()
    check(GameState.get_player_stat("hp") == 100 and GameState.choice_history.is_empty(), "Initial HP/history")
    check(GameState.get_relationship("emilia", "trust") == 0 and not GameState.has_story_flag("helped_emilia"), "Initial relationship/flag")
    main._test_state()
    check(GameState.get_player_stat("hp") == 90 and GameState.get_relationship("emilia", "trust") == 10, "Baseline help changes HP/trust")
    check(GameState.has_story_flag("helped_emilia") and GameState.choice_history.size() == 1, "Baseline flag/history")
    for i in range(20):
        main._test_state()
    check(GameState.get_player_stat("hp") == 0 and GameState.get_relationship("emilia", "trust") == 100, "Upper trust/lower HP clamps")
    GameState.change_relationship("emilia", "trust", -1000)
    check(GameState.get_relationship("emilia", "trust") == -100, "Lower trust clamp")
    GameState.change_player_stat("max_hp", -200)
    check(GameState.get_player_stat("max_hp") == 1, "Max HP cannot be negative")
    GameState.change_player_stat("hp", 1000)
    check(GameState.get_player_stat("hp") == 1, "HP respects maximum")
    var snapshot: Dictionary = GameState.snapshot()
    snapshot["relationships"]["emilia"]["trust"] = 42
    check(GameState.get_relationship("emilia", "trust") == -100, "Snapshot uses deep copy")
    main._replay()
    check(GameState.get_player_stat("hp") == 100 and GameState.choice_history.is_empty(), "New game restores defaults")
    check(story.current_node == "start" and ui.revealing, "First dialogue/typewriter starts")
    ui.set_process(false)
    ui._process(0.05)
    check(ui.dialogue_text.visible_ratio > 0 and ui.dialogue_text.visible_ratio < 1, "Typewriter progresses without replacing Thai text")
    var original_text: String = ui.dialogue_text.text
    ui.request_continue()
    check(not ui.revealing and story.current_node == "start" and ui.dialogue_text.visible_ratio == 1, "First continue reveals only")
    check(ui.dialogue_text.text == original_text, "Full text is preserved during reveal")
    ui.request_continue()
    check(story.current_node == "arrival" and GameState.story_state["current_node"] == "arrival", "Second continue updates story and GameState")
    var font: Font = load("res://assets/fonts/Sarabun-Regular.ttf")
    check(font.has_char("ก".unicode_at(0)) and font.has_char("้".unicode_at(0)) and font.has_char(65), "Bundled font contains Thai consonant, tone mark and Latin")
    ui.finish_reveal()
    var key := InputEventKey.new()
    key.keycode = KEY_SPACE
    key.pressed = true
    get_viewport().push_input(key)
    await get_tree().process_frame
    key = InputEventKey.new()
    key.keycode = KEY_SPACE
    key.pressed = false
    get_viewport().push_input(key)
    check(story.current_node == "meeting", "Keyboard Space advances exactly once")
    check(ui.portrait.texture != null and ui.background.texture != null, "Portrait and background loaded")
    ui.finish_reveal()
    ui.continue_button.pressed.emit()
    check(story.current_node == "reply" and ui.portrait.texture == null, "Mouse-button signal advances and clears prior portrait")
    ui.finish_reveal()
    ui.request_continue()
    ui.finish_reveal()
    ui.request_continue()
    check(story.current_node == "decision" and ui.choices.get_child_count() == 2, "Choice UI presents both options")
    story.advance()
    check(story.current_node == "decision", "Continue cannot bypass choices")
    check(saves.save_game(story), "Save before choice")
    ui.choices.get_child(0).pressed.emit()
    check(story.current_node == "helped" and GameState.get_player_stat("hp") == 90 and GameState.get_relationship("emilia", "trust") == 10, "Help route applies effects and branches")
    check(GameState.choice_history == ["choice_help_emilia"] and GameState.has_story_flag("helped_emilia"), "Real choice recorded once")
    check(not story.choose("decision", "choice_help_emilia") and GameState.get_player_stat("hp") == 90, "Stale/double selection rejected")
    check(saves.load_game(story) and story.current_node == "decision" and GameState.get_player_stat("hp") == 100 and GameState.choice_history.is_empty(), "Load restores pre-choice state atomically")
    ui.choices.get_child(1).pressed.emit()
    check(story.current_node == "observed" and GameState.get_player_stat("hp") == 100 and GameState.get_relationship("emilia", "trust") == -5, "Observe route differs from help")
    story.dialogue_finished.connect(func(): finished_count += 1)
    ui.finish_reveal()
    ui.request_continue()
    ui.request_continue()
    check(not story.active and finished_count == 1 and GameState.has_story_flag("dialogue_intro_completed"), "Ending completes once; extra input is ignored")
    check(saves.save_game(story), "Save completed route and retain backup")
    main._replay()
    check(saves.load_game(story) and story.current_node == "observed" and not ui.active, "Load completed route without replaying effects")
    check(GameState.choice_history == ["choice_observe_emilia"], "History round trip")
    var file := FileAccess.open(saves.save_path, FileAccess.WRITE)
    file.store_string("{broken")
    file.close()
    check(saves.load_game(story) and story.current_node == "decision", "Corrupted primary recovers previous valid backup")
    file = FileAccess.open(saves.save_path + ".bak", FileAccess.WRITE)
    file.store_string("{broken")
    file.close()
    var before: Dictionary = GameState.snapshot()
    check(not saves.load_game(story) and GameState.snapshot() == before, "Both files corrupt: reject without modifying live state")
    var payload := {"save_version": 1, "state": {"story_state": GameState.story_state.duplicate(true)}}
    check(not saves.validate_payload(payload, story).is_empty(), "Missing optional save fields receive defaults")
    payload["save_version"] = 999
    check(saves.validate_payload(payload, story).is_empty(), "Unknown save version rejected")
    payload = {"save_version": 1, "state": GameState.snapshot(), "completed": false}
    payload["state"]["player_stats"]["hp"] = "bad"
    check(saves.validate_payload(payload, story).is_empty(), "Wrong numeric types rejected")
    payload["state"] = GameState.snapshot()
    payload["state"]["story_state"]["current_node"] = "missing"
    check(saves.validate_payload(payload, story).is_empty(), "Missing saved node rejected")
    payload["state"] = GameState.snapshot()
    payload["completed"] = true
    check(saves.validate_payload(payload, story).is_empty(), "Completed marker invalid at a choice node")
    var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(main.STORY_PATH))
    data["nodes"]["start"]["next_node"] = "missing"
    check(not story.load_data(data) and GameState.snapshot() == before, "Invalid story destination rejected transactionally")
    data = JSON.parse_string(FileAccess.get_file_as_string(main.STORY_PATH))
    data["nodes"]["decision"]["choices"][0]["effects"].append({"type": "execute", "key": "unsafe"})
    check(not story.load_data(data), "Unknown effect type rejected before gameplay")
    check(not story.load_data([]), "Non-object story rejected safely")
    check(not story.load_story("res://data/stories/not_found.json"), "Missing story file reported safely")
    main._replay()
    check(saves.save_game(story) and saves.load_game(story), "New save repairs corrupted files")
    clean_test_files()
    main.queue_free()
    await get_tree().process_frame
    print("RESULT: %d checks, %d failures" % [checks, failures])
    get_tree().quit(0 if failures == 0 else 1)

func clean_test_files() -> void:
    for suffix in ["", ".bak", ".tmp"]:
        if FileAccess.file_exists(saves.save_path + suffix):
            DirAccess.remove_absolute(saves.save_path + suffix)
