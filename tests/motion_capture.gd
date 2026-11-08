extends SceneTree
var game: Node
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    game = load("res://scenes/main/Game.tscn").instantiate()
    root.add_child(game)
    game.start_journey()
    await create_timer(0.5).timeout
    var actor = game.world.visual
    assert(actor.sprite_frames.get_animation_names().size() == 8)
    assert(actor.sprite_frames.get_frame_count("walk_down") == 4)
    assert(actor.sprite_frames.get_frame_texture("walk_down",0).region != actor.sprite_frames.get_frame_texture("walk_down",2).region)
    var keys := [KEY_D,KEY_W,KEY_A,KEY_S]
    var names := ["right","up","left","down"]
    for i in range(4):
        game.world.player.position = game.world.spawn_point
        var event := InputEventKey.new()
        event.physical_keycode = keys[i]
        event.pressed = true
        Input.parse_input_event(event)
        await create_timer(0.25).timeout
        assert(actor.animation == "walk_" + names[i], "Wrong walking direction")
        var first_frame: int = actor.frame
        await create_timer(0.15).timeout
        assert(actor.frame != first_frame, "Walking pose must advance")
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://docs/design/motion-"+names[i]+".png")
        event.pressed = false
        Input.parse_input_event(event)
        await create_timer(0.15).timeout
        assert(actor.animation == "idle_" + names[i], "Stopped actor must idle")
    print("PASS: four real walking directions, advancing frames, idle transitions")
    game.music.stop()
    game.music.stream = null
    await create_timer(0.2).timeout
    game.queue_free()
    await process_frame
    quit()
