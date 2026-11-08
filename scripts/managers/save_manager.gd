extends Node

signal save_notification(message: String)
const SAVE_VERSION: int = 1
const MAX_BYTES: int = 1048576
var save_path: String = "user://save_01.json"
var last_error: String = ""

func save_game(story: Node) -> bool:
    if story.nodes.is_empty() or story.busy:
        return _fail("ยังบันทึกไม่ได้")
    var payload := {"save_version": SAVE_VERSION, "state": GameState.snapshot(), "completed": not story.active}
    var text: String = JSON.stringify(payload, "  ")
    if text.to_utf8_buffer().size() > MAX_BYTES:
        return _fail("ข้อมูลบันทึกใหญ่เกินขนาดที่รองรับ")
    var temp := save_path + ".tmp"
    var file := FileAccess.open(temp, FileAccess.WRITE)
    if file == null:
        return _fail("ไม่สามารถเขียนไฟล์ชั่วคราว")
    file.store_string(text)
    file.flush()
    var write_error: Error = file.get_error()
    file.close()
    if write_error != OK:
        return _fail("เขียน Save ไม่สำเร็จ")
    var backup := save_path + ".bak"
    if FileAccess.file_exists(save_path):
        # Do not replace a known-good backup with a corrupted primary file.
        if not _read_valid(save_path, story).is_empty():
            if FileAccess.file_exists(backup) and DirAccess.remove_absolute(backup) != OK:
                return _fail("ไม่สามารถแทนที่ Backup")
            if DirAccess.rename_absolute(save_path, backup) != OK:
                return _fail("ไม่สามารถสร้าง Backup")
        elif DirAccess.remove_absolute(save_path) != OK:
            return _fail("ไม่สามารถแทนที่ Save ที่เสียหาย")
    if DirAccess.rename_absolute(temp, save_path) != OK:
        if FileAccess.file_exists(backup):
            DirAccess.copy_absolute(backup, save_path)
        return _fail("ไม่สามารถติดตั้ง Save ใหม่; เก็บ Backup ไว้แล้ว")
    last_error = ""
    save_notification.emit("บันทึกสำเร็จ · ช่อง 1")
    return true

func load_game(story: Node) -> bool:
    var data: Dictionary = _read_valid(save_path, story)
    var recovered := false
    if data.is_empty():
        data = _read_valid(save_path + ".bak", story)
        recovered = not data.is_empty()
    if data.is_empty():
        return _fail("ไม่มี Save ที่ใช้ได้ หรือรูปแบบข้อมูลไม่รองรับ; สถานะเกมเดิมยังอยู่")
    GameState.restore_validated(data["state"])
    story.resume_at(data["state"]["story_state"]["current_node"], data["completed"])
    last_error = ""
    save_notification.emit("กู้คืนจาก Backup สำเร็จ" if recovered else "โหลดสำเร็จ · ช่อง 1")
    return true

func _read_valid(path: String, story: Node) -> Dictionary:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null or file.get_length() > MAX_BYTES:
        return {}
    var parser := JSON.new()
    if parser.parse(file.get_as_text()) != OK:
        return {}
    return validate_payload(parser.data, story)

func validate_payload(payload: Variant, story: Node) -> Dictionary:
    if not payload is Dictionary or payload.get("save_version") != SAVE_VERSION:
        return {} # No older format has been released. Future migrations belong here.
    if not payload.get("state") is Dictionary or not payload.get("completed", false) is bool:
        return {}
    var raw: Dictionary = payload["state"]
    var normalized: Dictionary = GameState.initial_state()
    # Core progression is mandatory; optional missing state fields use defaults.
    if not raw.get("story_state") is Dictionary:
        return {}
    for category in normalized:
        if not raw.has(category):
            continue
        if category == "choice_history":
            if not raw[category] is Array:
                return {}
            for id in raw[category]:
                if not id is String:
                    return {}
            normalized[category] = raw[category].duplicate()
        else:
            if not raw[category] is Dictionary:
                return {}
            normalized[category].merge(raw[category].duplicate(true), true)
    for category in ["player_stats", "world_state"]:
        for key in normalized[category]:
            if not _integer(normalized[category][key]):
                return {}
            normalized[category][key] = int(normalized[category][key])
    var stats: Dictionary = normalized["player_stats"]
    if stats["max_hp"] < 1 or stats["hp"] < 0 or stats["hp"] > stats["max_hp"]:
        return {}
    for key in ["stamina", "mental_stability"]:
        if stats[key] < 0 or stats[key] > 100:
            return {}
    for character in normalized["relationships"]:
        if not normalized["relationships"][character] is Dictionary:
            return {}
        for key in normalized["relationships"][character]:
            var value: Variant = normalized["relationships"][character][key]
            if not _integer(value) or float(value) < -100 or float(value) > 100:
                return {}
            normalized["relationships"][character][key] = int(value)
    for value in normalized["story_flags"].values():
        if not value is bool:
            return {}
    var position: Dictionary = normalized["story_state"]
    if not raw["story_state"].has("chapter_id") or not raw["story_state"].has("current_node"):
        return {}
    if position["chapter_id"] != story.chapter_id or not position["current_node"] is String or not story.nodes.has(position["current_node"]):
        return {}
    if not _integer(position["current_timeline"]) or position["current_timeline"] < 1:
        return {}
    position["current_timeline"] = int(position["current_timeline"])
    var completed: bool = payload.get("completed", false)
    if completed and (story.nodes[position["current_node"]]["type"] != "dialogue" or not story.nodes[position["current_node"]]["next_node"].is_empty()):
        return {}
    return {"state": normalized, "completed": completed}

func _integer(value: Variant) -> bool:
    return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and absf(float(value)) <= 1000000

func _fail(message: String) -> bool:
    last_error = message
    save_notification.emit(message)
    return false
