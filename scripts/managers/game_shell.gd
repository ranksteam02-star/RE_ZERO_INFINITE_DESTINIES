extends Node

const THEME = preload("res://assets/theme.tres")
const WORLD_SCRIPT = preload("res://scripts/systems/town_world.gd")
const MAIN_SCENE = preload("res://scenes/main/Main.tscn")
var world: Node3D
var main: Node
var canvas: CanvasLayer
var menu: Control
var town_hud: Control
var settings: Control
var hint: Label
var toast: Label
var continue_button: Button
var load_button: Button
var mode: String = "menu"
var previous_mode: String = "town"
var music: AudioStreamPlayer
var volume: float = 0.3
var text_speed: float = 35.0
var text_size: int = 31
var menu_buttons: Array[Button] = []
var settings_path: String = "user://settings.cfg"
var settings_focus: Control
var disabled_before_settings: Dictionary = {}

func _ready() -> void:
    get_tree().auto_accept_quit = false
    _read_settings()
    world = WORLD_SCRIPT.new()
    add_child(world)
    world.hide()
    world.interaction_requested.connect(open_story)
    canvas = CanvasLayer.new()
    canvas.layer = 10
    add_child(canvas)
    _build_menu()
    _build_town_hud()
    _build_settings()
    music = AudioStreamPlayer.new()
    var stream: AudioStreamOggVorbis = load("res://assets/music/twilight.ogg")
    stream.loop = true
    music.stream = stream
    add_child(music)
    _set_volume(volume)
    if DisplayServer.get_name() != "headless":
        music.play()
    show_menu()

func full_control(parent: Node) -> Control:
    var control := Control.new()
    control.theme = THEME
    parent.add_child(control)
    control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    return control

func label(parent: Node, text: String, size: int, color: Color = Color("f0e5d3")) -> Label:
    var result := Label.new()
    result.text = text
    result.add_theme_font_size_override("font_size", size)
    result.add_theme_color_override("font_color", color)
    parent.add_child(result)
    return result

func button(parent: Node, text: String, callback: Callable) -> Button:
    var result := Button.new()
    result.text = text
    result.alignment = HORIZONTAL_ALIGNMENT_LEFT
    result.custom_minimum_size.y = 65
    result.pressed.connect(callback)
    parent.add_child(result)
    return result

func _build_menu() -> void:
    menu = full_control(canvas)
    var art := TextureRect.new()
    art.texture = load("res://assets/art/twilight_city.png")
    art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    art.mouse_filter = Control.MOUSE_FILTER_IGNORE
    menu.add_child(art)
    art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var shade := ColorRect.new()
    var shader := Shader.new()
    shader.code = "shader_type canvas_item; void fragment(){ float darkness = mix(0.92, 0.04, smoothstep(0.05,0.85,UV.x)); COLOR = vec4(0.02,0.035,0.075,darkness); }"
    var mat := ShaderMaterial.new()
    mat.shader = shader
    shade.material = mat
    shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    menu.add_child(shade)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 11)
    menu.add_child(column)
    column.anchor_left = 0.075
    column.anchor_top = 0.12
    column.anchor_right = 0.40
    column.anchor_bottom = 0.89
    label(column, "A   S T O R Y   O F   C H O I C E S", 19, Color("d8b878"))
    label(column, "RE:ZERO", 102)
    label(column, "I N F I N I T E   D E S T I N I E S", 25, Color("d8b878"))
    var divider := HSeparator.new()
    column.add_child(divider)
    label(column, "ระฆังครั้งที่สิบสาม", 36)
    label(column, "บางความทรงจำ… ต้องมีใครสักคนช่วยจำ", 24, Color("c2bdd0"))
    var space := Control.new()
    space.custom_minimum_size.y = 24
    column.add_child(space)
    continue_button = button(column, "กลับเข้าเกม   ›", resume_game)
    menu_buttons.append(button(column, "เริ่มการเดินทาง   ›", start_journey))
    load_button = button(column, "เล่นต่อจากบันทึก", load_saved_game)
    menu_buttons.append(load_button)
    menu_buttons.append(button(column, "อ่านเนื้อเรื่องทันที", start_story_direct))
    menu_buttons.append(button(column, "ตั้งค่า", open_settings))
    menu_buttons.append(button(column, "ออกจากเกม", quit_game))
    toast = label(column, "", 23, Color("e7c382"))
    toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    var footer := label(menu, "6 ตอน   ·   12 การตัดสินใจ   ·   4 ฉากจบ", 22, Color("e1d8cf"))
    footer.anchor_left = 0.64
    footer.anchor_top = 0.92
    footer.anchor_right = 0.96
    footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    var version := label(menu, "แฟนโปรเจกต์  /  Visual Edition 0.4", 18, Color("b5adbc"))
    version.anchor_left = 0.075
    version.anchor_top = 0.95

func _build_town_hud() -> void:
    town_hud = full_control(canvas)
    town_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var top := VBoxContainer.new()
    town_hud.add_child(top)
    top.position = Vector2(60, 35)
    label(top, "L U G U N I C A   /   T W I L I G H T", 21, Color("e5c18a"))
    label(top, "ลานเมืองยามสนธยา", 42)
    label(top, "ไปหาเอมิเลียเพื่อเริ่มเรื่องราว", 26)
    var toolbar := HBoxContainer.new()
    town_hud.add_child(toolbar)
    toolbar.anchor_left = 0.64
    toolbar.anchor_right = 0.97
    toolbar.offset_top = 36
    toolbar.add_theme_constant_override("separation", 12)
    button(toolbar, "อ่านเนื้อเรื่อง", open_story)
    button(toolbar, "เมนู  Esc", show_menu)
    var bottom := PanelContainer.new()
    town_hud.add_child(bottom)
    bottom.anchor_left = 0.23
    bottom.anchor_right = 0.77
    bottom.anchor_top = 0.89
    bottom.anchor_bottom = 0.97
    var padding := MarginContainer.new()
    padding.add_theme_constant_override("margin_left", 24)
    padding.add_theme_constant_override("margin_right", 24)
    bottom.add_child(padding)
    hint = label(padding, "W A S D / ลูกศร  เดิน     ·     E  สนทนา     ·     F11  เต็มจอ", 26)
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    town_hud.hide()

func _build_settings() -> void:
    settings = full_control(canvas)
    var dim := ColorRect.new()
    dim.color = Color(0.01, 0.02, 0.04, 0.85)
    settings.add_child(dim)
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var panel := PanelContainer.new()
    settings.add_child(panel)
    panel.anchor_left = 0.3
    panel.anchor_right = 0.7
    panel.anchor_top = 0.21
    panel.anchor_bottom = 0.79
    var margin := MarginContainer.new()
    for key in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
        margin.add_theme_constant_override(key, 38)
    panel.add_child(margin)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 22)
    margin.add_child(column)
    label(column, "ตั้งค่า", 42)
    label(column, "ระดับเสียงดนตรี", 26)
    var volume_slider := HSlider.new()
    volume_slider.max_value = 1
    volume_slider.step = 0.01
    volume_slider.value = volume
    volume_slider.custom_minimum_size.y = 40
    volume_slider.value_changed.connect(_set_volume)
    column.add_child(volume_slider)
    settings_focus = volume_slider
    label(column, "ความเร็วข้อความ", 26)
    var speed_slider := HSlider.new()
    speed_slider.min_value = 5
    speed_slider.max_value = 100
    speed_slider.value = text_speed
    speed_slider.custom_minimum_size.y = 40
    speed_slider.value_changed.connect(func(value: float): text_speed = value; _apply_reading_settings(); _write_settings())
    column.add_child(speed_slider)
    label(column, "ขนาดตัวอักษรบทสนทนา", 26)
    var font_slider := HSlider.new()
    font_slider.min_value = 26
    font_slider.max_value = 40
    font_slider.value = text_size
    font_slider.custom_minimum_size.y = 40
    font_slider.value_changed.connect(func(value: float): text_size = int(value); _apply_reading_settings(); _write_settings())
    column.add_child(font_slider)
    button(column, "สลับเต็มจอ   F11", toggle_fullscreen)
    button(column, "เสร็จแล้ว", close_settings)
    settings.hide()

func _process(_delta: float) -> void:
    if mode == "town":
        hint.text = "E  ·  คุยกับเอมิเลียและอ่านเรื่องต่อ" if world.near_npc else "W A S D / ลูกศร  เดิน     ·     E  สนทนา     ·     F11  เต็มจอ"

func _hide_views() -> void:
    world.active = false
    world.hide()
    town_hud.hide()
    menu.hide()
    if is_instance_valid(main):
        main.get_node("UI").hide()
        main.get_node("World").hide()
        main.process_mode = Node.PROCESS_MODE_DISABLED

func show_menu() -> void:
    if mode != "menu":
        previous_mode = mode
    _hide_views()
    mode = "menu"
    menu.show()
    continue_button.visible = is_instance_valid(main) or world.player.position.distance_to(world.spawn_point) > 0.1
    load_button.disabled = not (FileAccess.file_exists("user://save_01.json") or FileAccess.file_exists("user://save_01.json.bak"))
    menu_buttons[0].grab_focus()

func start_journey() -> void:
    if is_instance_valid(main):
        # Use the existing confirmation dialog before resetting an ongoing story.
        open_story()
        main._confirm_new_game()
        return
    world.player.position = world.spawn_point
    show_town()

func show_town() -> void:
    _hide_views()
    mode = "town"
    world.show()
    world.active = true
    world.camera.current = true
    town_hud.show()

func _create_story() -> void:
    if is_instance_valid(main):
        return
    main = MAIN_SCENE.instantiate()
    add_child(main)
    main.return_requested.connect(func(destination: String): show_town() if destination == "town" else show_menu())
    _apply_reading_settings()

func open_story() -> void:
    _create_story()
    _hide_views()
    mode = "story"
    main.process_mode = Node.PROCESS_MODE_INHERIT
    main.get_node("UI").show()
    # Decorative old Main/World camera is unused; dialogue uses the painted background.

func start_story_direct() -> void:
    open_story()

func load_saved_game() -> void:
    _create_story()
    if main.saves.load_game(main.story):
        open_story()
    else:
        toast.text = main.saves.last_error
        show_menu()

func resume_game() -> void:
    if previous_mode == "story" and is_instance_valid(main):
        open_story()
    else:
        show_town()

func _apply_reading_settings() -> void:
    if is_instance_valid(main):
        main.dialogue.characters_per_second = text_speed
        main.dialogue.dialogue_text.add_theme_font_size_override("normal_font_size", text_size)
        main.get_node("UI/HUD/Top/Rows/Tools/Speed").value = text_speed

func _set_volume(value: float) -> void:
    volume = clampf(value, 0.0, 1.0)
    if is_instance_valid(music):
        music.volume_db = linear_to_db(maxf(volume, 0.0001))
    _write_settings()

func _read_settings() -> void:
    var config := ConfigFile.new()
    if config.load(settings_path) == OK:
        var v: Variant = config.get_value("audio", "volume", 0.3)
        var speed: Variant = config.get_value("text", "speed", 35.0)
        var size: Variant = config.get_value("text", "size", 31)
        if v is float or v is int:
            volume = clampf(float(v), 0, 1)
        if speed is float or speed is int:
            text_speed = clampf(float(speed), 5, 100)
        if size is int or size is float:
            text_size = clampi(int(size), 26, 40)

func _write_settings() -> void:
    var config := ConfigFile.new()
    config.set_value("audio", "volume", volume)
    config.set_value("text", "speed", text_speed)
    config.set_value("text", "size", text_size)
    config.save(settings_path)

func toggle_fullscreen() -> void:
    var full: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if event.keycode == KEY_ESCAPE:
        if settings.visible:
            close_settings()
        elif mode == "menu":
            resume_game()
        else:
            show_menu()
        get_viewport().set_input_as_handled()
    elif event.keycode == KEY_E and mode == "town":
        world.try_interact()
        get_viewport().set_input_as_handled()
    elif event.keycode == KEY_F11 and mode != "story":
        toggle_fullscreen()
        get_viewport().set_input_as_handled()

func _exit_tree() -> void:
    if is_instance_valid(music):
        music.stop()
        music.stream = null


func open_settings() -> void:
    disabled_before_settings.clear()
    var all_buttons: Array[Button] = menu_buttons.duplicate()
    all_buttons.append(continue_button)
    for item in all_buttons:
        disabled_before_settings[item] = item.disabled
        item.disabled = true
    settings.show()
    settings_focus.grab_focus()

func close_settings() -> void:
    settings.hide()
    for item in disabled_before_settings:
        if is_instance_valid(item):
            item.disabled = disabled_before_settings[item]
    disabled_before_settings.clear()
    menu_buttons[0].grab_focus()

func quit_game() -> void:
    if is_instance_valid(music):
        music.stop()
        music.stream = null
    await get_tree().create_timer(0.15).timeout
    get_tree().quit()

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        quit_game()
