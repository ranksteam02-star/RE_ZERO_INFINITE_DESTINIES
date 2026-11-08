extends SceneTree
var game: Node
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    game = load("res://scenes/main/Game.tscn").instantiate()
    root.add_child(game)
    await shot("visual-menu")
    game.start_journey()
    await shot("visual-town")
    game.open_story()
    game.main.story.resume_at("a1_3", false)
    game.main.dialogue.finish_reveal()
    await shot("visual-dialogue")
    game.main.story.resume_at("c1", false)
    await shot("visual-choice")
    game.show_menu()
    game.settings.show()
    await shot("visual-settings")
    game.music.stop()
    game.music.stream = null
    await create_timer(0.2).timeout
    game.queue_free()
    await process_frame
    quit()
func shot(name: String) -> void:
    print("CAPTURE ", name)
    await create_timer(0.7).timeout
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://docs/design/" + name + ".png")
