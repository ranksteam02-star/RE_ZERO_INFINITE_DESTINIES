extends SceneTree

func _initialize() -> void:
    call_deferred("capture")

func capture() -> void:
    var main: Node = load("res://scenes/main/Main.tscn").instantiate()
    root.add_child(main)
    var story: Node = main.get_node("StoryManager")
    var ui: Control = main.get_node("UI/HUD/DialogueUI")
    story.resume_at("a1_3", false)
    ui.finish_reveal()
    await screenshot("dialogue-preview")
    story.resume_at("c1", false)
    await screenshot("choices-preview")
    root.size = Vector2i(960, 540)
    await create_timer(0.2).timeout
    story.resume_at("a6_mid_3", false)
    ui.finish_reveal()
    await screenshot("dialogue-960x540")
    root.size = Vector2i(1920, 1080)
    await create_timer(0.2).timeout
    story.resume_at("ending_names_7", false)
    ui.finish_reveal()
    ui.request_continue()
    await screenshot("ending-1920x1080")
    main.queue_free()
    await process_frame
    quit()

func screenshot(file_name: String) -> void:
    print("CAPTURE: " + file_name)
    await create_timer(0.3).timeout
    await RenderingServer.frame_post_draw
    var result: Error = root.get_texture().get_image().save_png("res://docs/design/" + file_name + ".png")
    if result != OK:
        printerr("Screenshot failed: " + file_name)
        quit(1)
