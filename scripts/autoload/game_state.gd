extends Node

signal state_changed(
    category: String,
    key: String,
    value: Variant
)

var player_stats: Dictionary = {
    "hp": 100,
    "max_hp": 100,
    "stamina": 100,
    "mental_stability": 100,
    "courage": 0,
    "knowledge": 0,
    "combat_ability": 0
}

var relationships: Dictionary = {
    "emilia": {
        "trust": 0,
        "affection": 0,
        "suspicion": 0,
        "fear": 0,
        "resentment": 0
    }
}

var world_state: Dictionary = {
    "world_stability": 100,
    "threat_level": 0,
    "political_influence": 0,
    "public_reputation": 0,
    "timeline_instability": 0
}

var story_state: Dictionary = {
    "chapter_id": "chapter_01",
    "current_node": "start",
    "current_timeline": 1
}

var story_flags: Dictionary = {}

var choice_history: Array[String] = []


func get_player_stat(stat_name: String) -> int:
    return int(player_stats.get(stat_name, 0))


func change_player_stat(
    stat_name: String,
    amount: int
) -> void:

    if not player_stats.has(stat_name):
        push_warning(
            "Unknown player stat: " + stat_name
        )
        return

    player_stats[stat_name] += amount

    if stat_name == "hp":
        player_stats["hp"] = clampi(
            int(player_stats["hp"]),
            0,
            int(player_stats["max_hp"])
        )

    if stat_name == "max_hp":
        player_stats["max_hp"] = maxi(1, int(player_stats["max_hp"]))
        player_stats["hp"] = clampi(int(player_stats["hp"]), 0, int(player_stats["max_hp"]))
        state_changed.emit("player", "hp", player_stats["hp"])
    if stat_name in ["stamina", "mental_stability"]:
        player_stats[stat_name] = clampi(int(player_stats[stat_name]), 0, 100)

    state_changed.emit(
        "player",
        stat_name,
        player_stats[stat_name]
    )


func change_relationship(
    character_id: String,
    relationship_type: String,
    amount: int
) -> void:

    if not relationships.has(character_id):
        relationships[character_id] = {}

    if not relationships[character_id].has(
        relationship_type
    ):
        relationships[character_id][
            relationship_type
        ] = 0

    var new_value: int = (
        int(
            relationships[character_id][
                relationship_type
            ]
        ) + amount
    )

    relationships[character_id][
        relationship_type
    ] = clampi(
        new_value,
        -100,
        100
    )

    state_changed.emit(
        "relationship",
        character_id + "." + relationship_type,
        relationships[character_id][relationship_type]
    )


func get_relationship(
    character_id: String,
    relationship_type: String
) -> int:

    if not relationships.has(character_id):
        return 0

    return int(
        relationships[character_id].get(
            relationship_type,
            0
        )
    )


func set_story_flag(
    flag_name: String,
    value: bool = true
) -> void:

    story_flags[flag_name] = value

    state_changed.emit(
        "story",
        flag_name,
        value
    )


func has_story_flag(flag_name: String) -> bool:
    return bool(
        story_flags.get(flag_name, false)
    )


func record_choice(choice_id: String) -> void:

    choice_history.append(choice_id)

    state_changed.emit(
        "story",
        "choice_history",
        choice_history
    )


func set_story_position(chapter_id: String, node_id: String) -> void:
    story_state["chapter_id"] = chapter_id
    story_state["current_node"] = node_id
    state_changed.emit("story", "current_node", node_id)


# A new game reset is intentionally separate from future timeline restoration.
var timeline_data: Dictionary = {}
var persistent_memory: Dictionary = {}
var _initial_state: Dictionary = {}

func _ready() -> void:
    _initial_state = snapshot()

func snapshot() -> Dictionary:
    return {
        "player_stats": player_stats.duplicate(true),
        "relationships": relationships.duplicate(true),
        "world_state": world_state.duplicate(true),
        "story_state": story_state.duplicate(true),
        "story_flags": story_flags.duplicate(true),
        "choice_history": choice_history.duplicate(),
        "timeline_data": timeline_data.duplicate(true),
        "persistent_memory": persistent_memory.duplicate(true)
    }

func initial_state() -> Dictionary:
    return _initial_state.duplicate(true)

func restore_validated(data: Dictionary) -> void:
    # Only SaveManager-validated snapshots or internal initial state enter here.
    player_stats = data["player_stats"].duplicate(true)
    relationships = data["relationships"].duplicate(true)
    world_state = data["world_state"].duplicate(true)
    story_state = data["story_state"].duplicate(true)
    story_flags = data["story_flags"].duplicate(true)
    choice_history.assign(data["choice_history"])
    timeline_data = data["timeline_data"].duplicate(true)
    persistent_memory = data["persistent_memory"].duplicate(true)
    state_changed.emit("all", "restored", null)

func reset_new_game() -> void:
    restore_validated(initial_state())
