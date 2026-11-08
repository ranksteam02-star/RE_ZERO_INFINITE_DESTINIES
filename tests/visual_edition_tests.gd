extends Node
var failures: int = 0
var count: int = 0
var game: Node
func check(ok: bool, title: String) -> void:
    count += 1
    print(("PASS: " if ok else "FAIL: ") + title)
    if not ok:
        failures += 1
func _ready() -> void:
    call_deferred("run")
func key(code: Key, down: bool) -> void:
    var event := InputEventKey.new()
    event.physical_keycode = code
    event.keycode = code
    event.pressed = down
    Input.parse_input_event(event)
func run() -> void:
    game = load("res://scenes/main/Game.tscn").instantiate()
    game.settings_path = "user://visual_test_settings.cfg"
    add_child(game)
    check(game.mode == "menu" and game.menu.visible and not game.world.active, "Boot opens title, world controls disabled")
    check(game.music.stream != null and game.music.stream.get_length() > 30, "Original ambience loads")
    game.open_settings()
    check(game.settings.visible and game.menu_buttons[0].disabled, "Settings captures focus and disables underlying menu")
    game._set_volume(0.42)
    game.text_size = 36
    game.text_speed = 56
    game._write_settings()
    game.volume = 0
    game.text_size = 26
    game._read_settings()
    check(is_equal_approx(game.volume, 0.42) and game.text_size == 36 and game.text_speed == 56, "Audio/text settings round-trip")
    game.close_settings()
    check(not game.settings.visible and not game.menu_buttons[0].disabled, "Settings restores menu input")
    game.start_journey()
    check(game.mode == "town" and game.world.active and game.world.camera.current, "New journey opens orthographic plaza")
    await get_tree().physics_frame
    var start: Vector3 = game.world.player.position
    key(KEY_D, true)
    for i in range(30):
        await get_tree().physics_frame
    key(KEY_D, false)
    check(game.world.player.position.distance_to(start) > 0.5, "Physical D input moves player")
    game.world.player.position = Vector3(13.7, 0.1, 8.5)
    game.world.player.velocity = Vector3.ZERO
    key(KEY_D, true)
    for i in range(40):
        await get_tree().physics_frame
    key(KEY_D, false)
    check(game.world.player.position.x < 14.1, "Boundary collision prevents leaving plaza")
    check(not game.world.try_interact(), "Interaction rejected when far from Emilia")
    game.world.player.position = game.world.npc_position + Vector3(0.5, 0.1, 0.5)
    await get_tree().physics_frame
    await get_tree().physics_frame
    check(game.world.try_interact(), "Nearby NPC interaction accepted")
    check(game.mode == "story" and game.main.story.active and not game.world.active, "NPC opens campaign and freezes exploration")
    game.main.story.resume_at("a1_3", false)
    check(game.main.dialogue.portrait.texture is AtlasTexture, "Generated Emilia portrait displayed")
    check(game.main.dialogue.dialogue_text.get_theme_font_size("normal_font_size") == 36, "Reading size preference applied")
    var node_before: String = game.main.story.current_node
    game.show_menu()
    check(game.main.process_mode == Node.PROCESS_MODE_DISABLED and not game.main.get_node("UI").visible, "Menu pauses and hides narrative")
    game.resume_game()
    check(game.mode == "story" and game.main.story.current_node == node_before, "Resume preserves current narrative node")
    game.main.saves.save_path = "user://visual_test_save.json"
    game.main.story.resume_at("c1", false)
    check(game.main.saves.save_game(game.main.story), "Save works through new shell")
    game.main.story.choose("c1", "c1_help")
    game.show_menu()
    game.load_saved_game()
    check(game.mode == "story" and game.main.story.current_node == "c1" and GameState.get_player_stat("hp") == 100, "Title Load restores choice without replayed effects")
    game.show_town()
    check(game.mode == "town" and game.world.camera.current, "Return from story reactivates town camera")
    game.open_story()
    check(game.main.story.current_node == "c1", "Town round-trip preserves story position")
    for suffix in ["", ".tmp", ".bak"]:
        var path: String = game.main.saves.save_path + suffix
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(path)
    if FileAccess.file_exists(game.settings_path):
        DirAccess.remove_absolute(game.settings_path)
    game.queue_free()
    await get_tree().process_frame
    print("VISUAL EDITION: %d checks, %d failures" % [count, failures])
    get_tree().quit(0 if failures == 0 else 1)
