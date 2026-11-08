extends AnimatedSprite3D
## Four facing directions, independently authored contact/passing poses.
var facing := "down"
func configure(path: String) -> void:
    var sheet: Texture2D = load(path)
    sprite_frames = SpriteFrames.new()
    sprite_frames.remove_animation("default")
    var directions := ["down", "left", "right", "up"]
    for row in range(4):
        for state in ["idle", "walk"]:
            var animation_name: String = state + "_" + directions[row]
            sprite_frames.add_animation(animation_name)
            sprite_frames.set_animation_speed(animation_name, 8.0 if state == "walk" else 1.0)
            var columns: Array = [2, 3, 4, 5] if state == "walk" else [0, 1, 0]
            for index in range(columns.size()):
                var texture_frame := AtlasTexture.new()
                texture_frame.atlas = sheet
                texture_frame.region = Rect2(columns[index] * 256, row * 256, 256, 256)
                var duration: float = 1.0 if state == "walk" else [2.8, 0.13, 0.7][index]
                sprite_frames.add_frame(animation_name, texture_frame, duration)
    pixel_size = 0.0075
    billboard = BaseMaterial3D.BILLBOARD_ENABLED
    alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
    alpha_scissor_threshold = 0.5
    texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
    shaded = false
    play("idle_down")

func update_motion(screen_motion: Vector2) -> void:
    var moving := screen_motion.length() > 0.15
    if moving:
        if absf(screen_motion.x) > absf(screen_motion.y):
            facing = "right" if screen_motion.x > 0 else "left"
        else:
            facing = "down" if screen_motion.y > 0 else "up"
    var next_animation: String = ("walk_" if moving else "idle_") + facing
    if animation != next_animation:
        play(next_animation)
