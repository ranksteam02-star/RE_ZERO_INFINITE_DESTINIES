extends RefCounted

const RELATIONSHIP_KEYS := ["trust", "affection", "suspicion", "fear", "resentment"]

static func validate(choice: Variant) -> String:
    if not choice is Dictionary:
        return "Choice ต้องเป็น Dictionary"
    for key in ["id", "text", "next_node"]:
        if not choice.get(key) is String or choice[key].is_empty():
            return "Choice ไม่มี " + key
    if not choice.get("effects") is Array:
        return "Choice ไม่มี effects"
    for effect in choice["effects"]:
        if not effect is Dictionary or not effect.get("key") is String:
            return "Effect ไม่ถูกต้อง"
        match effect.get("type"):
            "player_stat":
                if not GameState.player_stats.has(effect["key"]) or not _whole_number(effect.get("amount")):
                    return "player_stat effect ไม่ถูกต้อง"
            "relationship":
                if not effect.get("character") is String or effect["character"].is_empty() or not effect["key"] in RELATIONSHIP_KEYS or not _whole_number(effect.get("amount")):
                    return "relationship effect ไม่ถูกต้อง"
            "story_flag":
                if not effect.get("value") is bool or effect["key"].is_empty():
                    return "story_flag effect ไม่ถูกต้อง"
            _:
                return "ไม่รู้จักชนิด effect"
    return ""

static func _whole_number(value: Variant) -> bool:
    return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and absf(float(value)) <= 1000000

static func apply(choice: Dictionary) -> void:
    # StoryManager validates the entire graph before play, and locks selection.
    for effect in choice["effects"]:
        match effect["type"]:
            "player_stat":
                GameState.change_player_stat(effect["key"], int(effect["amount"]))
            "relationship":
                GameState.change_relationship(effect["character"], effect["key"], int(effect["amount"]))
            "story_flag":
                GameState.set_story_flag(effect["key"], effect["value"])
    GameState.record_choice(choice["id"])
