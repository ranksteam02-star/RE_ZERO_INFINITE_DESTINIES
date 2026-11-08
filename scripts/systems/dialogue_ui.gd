extends Control

signal choice_selected(node_id: String, choice_id: String)
signal continue_requested

@export_range(1.0, 120.0) var characters_per_second: float = 35.0
@onready var background: TextureRect = $Background
@onready var portrait: TextureRect = $Margin/Layout/CharacterPortrait
@onready var speaker: Label = $Margin/Layout/DialoguePanel/Padding/Content/CharacterName
@onready var dialogue_text: RichTextLabel = $Margin/Layout/DialoguePanel/Padding/Content/DialogueText
@onready var continue_button: Button = $Margin/Layout/DialoguePanel/Padding/Content/ContinueIndicator
@onready var choices: VBoxContainer = $Margin/Layout/DialoguePanel/Padding/Content/ChoiceContainer
var revealing: bool = false
var active: bool = false
var elapsed_characters: float = 0.0

func _ready() -> void:
    continue_button.pressed.connect(request_continue)
    # Shape the complete Thai text before revealing glyphs; never slice UTF-8 text.
    dialogue_text.visible_characters_behavior = TextServer.VC_GLYPHS_AUTO
    portrait.reparent(self)
    portrait.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
    portrait.anchor_left = 0.56
    portrait.anchor_right = 0.98
    portrait.anchor_top = 0.13
    portrait.anchor_bottom = 1.18
    portrait.offset_left = 0
    portrait.offset_right = 0
    portrait.offset_top = 0
    portrait.offset_bottom = 0
    move_child(portrait, 1)
    var shade := ColorRect.new()
    var shader := Shader.new()
    shader.code = "shader_type canvas_item; void fragment(){COLOR=vec4(0.015,0.025,0.06,0.83*(1.0-smoothstep(0.0,0.36,UV.y)));}"
    var mat := ShaderMaterial.new()
    mat.shader = shader
    shade.material = mat
    shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(shade)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    move_child(shade, 1)
    set_process(false)

func show_line(line: Dictionary) -> void:
    clear_choices()
    continue_button.show()
    active = true
    speaker.text = line.get("speaker", "")
    dialogue_text.text = line.get("text", "")
    dialogue_text.scroll_to_line(0)
    dialogue_text.visible_ratio = 0.0
    elapsed_characters = 0.0
    revealing = not dialogue_text.text.is_empty()
    for pair in [[portrait, "portrait"], [background, "background"]]:
        var path: String = line.get(pair[1], "")
        pair[0].texture = null if path.is_empty() else load(path)
    continue_button.disabled = false
    continue_button.text = "แสดงข้อความทั้งหมด  ·  Space / Enter"
    set_process(revealing)

func _process(delta: float) -> void:
    elapsed_characters += delta * characters_per_second
    var total: int = dialogue_text.get_total_character_count()
    dialogue_text.visible_ratio = minf(elapsed_characters / maxf(total, 1), 1.0)
    if dialogue_text.visible_ratio >= 1.0:
        finish_reveal()

func finish_reveal() -> void:
    dialogue_text.visible_characters = -1
    revealing = false
    set_process(false)
    continue_button.text = "อ่านต่อ   ›   Space / Enter"

func request_continue() -> void:
    if not active:
        return
    if revealing:
        finish_reveal()
    else:
        continue_requested.emit()

func finish_dialogue() -> void:
    finish_reveal()
    active = false
    continue_button.text = "จบแล้ว · เริ่มเกมใหม่เพื่อสำรวจเส้นทางอื่น"
    continue_button.disabled = true

func _unhandled_key_input(event: InputEvent) -> void:
    if is_visible_in_tree() and event.is_action_pressed("ui_accept") and not event.is_echo():
        request_continue()
        get_viewport().set_input_as_handled()

func _exit_tree() -> void:
    set_process(false)


func clear_choices() -> void:
    for button in choices.get_children():
        choices.remove_child(button)
        button.queue_free()
    choices.hide()

func show_choices(node_id: String, items: Array, prompt: String) -> void:
    finish_reveal()
    active = false
    clear_choices()
    continue_button.hide()
    choices.show()
    speaker.text = "การตัดสินใจของคุณ"
    dialogue_text.text = prompt
    dialogue_text.visible_characters = -1
    for item in items:
        var button := Button.new()
        button.text = item["text"]
        button.pressed.connect(_select_choice.bind(node_id, item["id"]))
        choices.add_child(button)
    choices.get_child(0).grab_focus()

func _select_choice(node_id: String, choice_id: String) -> void:
    for button in choices.get_children():
        button.disabled = true
    choice_selected.emit(node_id, choice_id)
