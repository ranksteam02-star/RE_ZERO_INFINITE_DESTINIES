extends Node

var failures: int = 0
var visited: Dictionary = {}
var endings: Dictionary = {}

func _ready() -> void:
    call_deferred("run")

func run() -> void:
    var story: Node = load("res://scripts/managers/story_manager.gd").new()
    add_child(story)
    if not story.load_story("res://data/stories/the_thirteenth_bell.json"):
        printerr("Campaign load failed: " + story.last_error)
        get_tree().quit(1)
        return
    var routes: int = 4096
    var min_pages: int = 1000
    var max_pages: int = 0
    for route in range(routes):
        GameState.reset_new_game()
        story.resume_at("a1_0", false)
        var choice_index: int = 0
        var pages: int = 0
        var steps: int = 0
        while story.active and steps < 300:
            steps += 1
            visited[story.current_node] = true
            if story.choosing:
                var options: Array = story.nodes[story.current_node]["choices"]
                var selected: int = (route >> choice_index) & 1
                if not story.choose(story.current_node, options[selected]["id"]):
                    failures += 1
                    break
                choice_index += 1
            else:
                pages += 1
                story.advance()
        if story.active or choice_index != 12 or GameState.choice_history.size() != 12:
            printerr("Route failed: %d at %s" % [route, story.current_node])
            failures += 1
        var expected: String
        if GameState.has_story_flag("chose_restoration"):
            expected = "ending_names_7" if GameState.get_player_stat("knowledge") >= 18 and GameState.has_story_flag("distributed_records") else "ending_borrowed_7"
        else:
            expected = "ending_dawn_7" if GameState.get_relationship("emilia", "trust") >= 20 else "ending_solitary_7"
        if story.current_node != expected:
            printerr("Unexpected ending on route %d" % route)
            failures += 1
        endings[story.current_node] = int(endings.get(story.current_node, 0)) + 1
        min_pages = mini(min_pages, pages)
        max_pages = maxi(max_pages, pages)
    var visible_nodes: int = 0
    for id in story.nodes:
        if story.nodes[id]["type"] != "condition":
            visible_nodes += 1
            if not visited.has(id):
                printerr("Unvisited content: " + id)
                failures += 1
    if endings.size() != 4:
        failures += 1
    print("CAMPAIGN: %d routes; %d/%d visible nodes; %d endings; %d-%d dialogue pages per playthrough; %d failures" % [routes, visited.size(), visible_nodes, endings.size(), min_pages, max_pages, failures])
    print("Ending distribution: ", endings)
    # Guard against infinite condition chains supplied by future content authors.
    var cycle := {"chapter_id": "cycle", "start_node": "loop", "nodes": {
        "loop": {"type": "condition", "condition": {"type": "flag", "key": "x", "value": true}, "if_true": "loop", "if_false": "loop"}}}
    story.load_data(cycle)
    if story.active or story.last_error.is_empty():
        failures += 1
        printerr("Condition cycle did not stop safely")
    else:
        print("PASS: condition cycles stop with a readable error")
    get_tree().quit(0 if failures == 0 else 1)
