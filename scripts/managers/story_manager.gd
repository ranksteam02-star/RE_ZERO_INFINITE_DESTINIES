extends Node

signal line_requested(line: Dictionary)
signal choices_requested(node_id: String, choices: Array, prompt: String)
signal dialogue_finished
signal story_error(message: String)

const Choices = preload("res://scripts/systems/choice_system.gd")
var choosing: bool = false
var busy: bool = false

var chapter_id: String = ""
var current_node: String = ""
var nodes: Dictionary = {}
var active: bool = false
var last_error: String = ""

func load_story(path: String) -> bool:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return _fail("เปิดไฟล์บทสนทนาไม่ได้: " + path)
    var parser := JSON.new()
    if parser.parse(file.get_as_text()) != OK:
        return _fail("JSON ไม่ถูกต้อง บรรทัด %d: %s" % [parser.get_error_line(), parser.get_error_message()])
    return load_data(parser.data)

func load_data(data: Variant) -> bool:
    # Validate the entire graph before replacing any live story or GameState.
    if not data is Dictionary:
        return _fail("ข้อมูลบทสนทนาต้องเป็น Dictionary")
    if not data.get("chapter_id") is String or str(data.get("chapter_id", "")).is_empty():
        return _fail("ไม่พบ chapter_id")
    if not data.get("nodes") is Dictionary or not data.get("start_node") is String:
        return _fail("ไม่พบ nodes หรือ start_node")
    var candidate: Dictionary = data["nodes"]
    if not candidate.has(data["start_node"]):
        return _fail("ไม่พบ start_node ใน nodes")
    var choice_ids: Array[String] = []
    for id in candidate:
        var line: Variant = candidate[id]
        if not line is Dictionary:
            return _fail("Node ต้องเป็น Dictionary: " + str(id))
        if line.get("type") == "condition":
            if not line.get("condition") is Dictionary:
                return _fail("Condition node ไม่มี condition")
            var condition: Dictionary = line["condition"]
            if not condition.get("key") is String:
                return _fail("Condition ไม่มี key")
            match condition.get("type"):
                "flag":
                    if not condition.get("value") is bool:
                        return _fail("Flag condition ต้องเป็น bool")
                "stat":
                    if not GameState.player_stats.has(condition["key"]) or not Choices._whole_number(condition.get("gte")):
                        return _fail("Stat condition ไม่ถูกต้อง")
                "relationship":
                    if not condition.get("character") is String or not condition["key"] in Choices.RELATIONSHIP_KEYS or not Choices._whole_number(condition.get("gte")):
                        return _fail("Relationship condition ไม่ถูกต้อง")
                _:
                    return _fail("ไม่รู้จักชนิด condition")
            for branch in ["if_true", "if_false"]:
                if not line.get(branch) is String or not candidate.has(line[branch]):
                    return _fail("Condition ไม่มีปลายทาง")
            continue
        if line.get("type") == "choice":
            if not line.get("text") is String:
                return _fail("Choice node ไม่มี text")
            if not line.get("choices") is Array or line["choices"].is_empty():
                return _fail("Choice node ไม่มีตัวเลือก")
            for choice in line["choices"]:
                var issue: String = Choices.validate(choice)
                if not issue.is_empty():
                    return _fail(issue)
                if choice["id"] in choice_ids:
                    return _fail("Choice ID ซ้ำ: " + choice["id"])
                choice_ids.append(choice["id"])
                if not candidate.has(choice["next_node"]):
                    return _fail("ไม่พบปลายทางของ Choice")
            continue
        if line.get("type") != "dialogue":
            return _fail("รองรับเฉพาะ dialogue, choice และ condition: " + str(id))
        for field in ["speaker", "text", "next_node"]:
            if not line.get(field) is String:
                return _fail("Field ไม่ถูกต้อง: " + str(id) + "." + field)
        for field in ["portrait", "background"]:
            if line.has(field) and not line[field] is String:
                return _fail("Asset path ไม่ถูกต้อง: " + str(id))
            var path: String = line.get(field, "")
            if not path.is_empty() and (not path.begins_with("res://assets/") or not ResourceLoader.exists(path, "Texture2D")):
                return _fail("ไม่พบ Texture2D: " + path)
        if not line["next_node"].is_empty() and not candidate.has(line["next_node"]):
            return _fail("ไม่พบ next_node: " + line["next_node"])
    nodes = candidate.duplicate(true)
    chapter_id = data["chapter_id"]
    current_node = data["start_node"]
    active = true
    last_error = ""
    _present()
    return true

func advance() -> void:
    if not active or choosing or busy:
        return
    var next_id: String = nodes[current_node]["next_node"]
    if next_id.is_empty():
        active = false
        GameState.set_story_flag("dialogue_intro_completed")
        dialogue_finished.emit()
        return
    current_node = next_id
    _present()

func _present() -> void:
    var visited: Dictionary = {}
    while nodes[current_node]["type"] == "condition":
        if visited.has(current_node):
            active = false
            _fail("พบวงวนใน condition nodes: " + current_node)
            return
        visited[current_node] = true
        var node: Dictionary = nodes[current_node]
        var passed: bool = evaluate_condition(node["condition"])
        current_node = node["if_true"] if passed else node["if_false"]
    GameState.set_story_position(chapter_id, current_node)
    choosing = nodes[current_node]["type"] == "choice"
    if choosing:
        choices_requested.emit(current_node, nodes[current_node]["choices"].duplicate(true), nodes[current_node]["text"])
    else:
        line_requested.emit(nodes[current_node].duplicate(true))

func _fail(message: String) -> bool:
    last_error = message
    story_error.emit(message)
    return false


func choose(expected_node: String, choice_id: String) -> bool:
    if busy or not active or not choosing or expected_node != current_node:
        return false
    for choice in nodes[current_node]["choices"]:
        if choice["id"] == choice_id:
            busy = true
            Choices.apply(choice)
            current_node = choice["next_node"]
            _present()
            busy = false
            return true
    return false

func resume_at(node_id: String, completed: bool) -> void:
    current_node = node_id
    active = true
    _present()
    if completed:
        active = false
        dialogue_finished.emit()


func evaluate_condition(condition: Dictionary) -> bool:
    match condition["type"]:
        "flag":
            return GameState.has_story_flag(condition["key"]) == condition["value"]
        "stat":
            return GameState.get_player_stat(condition["key"]) >= int(condition["gte"])
        "relationship":
            return GameState.get_relationship(condition["character"], condition["key"]) >= int(condition["gte"])
    return false
