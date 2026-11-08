extends Node

func _ready() -> void:
    var main: Node = load("res://scenes/main/Main.tscn").instantiate()
    add_child(main)
    var saves: Node = main.get_node("SaveManager")
    var story: Node = main.get_node("StoryManager")
    saves.save_path = "user://persistence_test_slot.json"
    if "--write" in OS.get_cmdline_user_args():
        while not story.choosing:
            story.advance()
        story.choose("c1", "c1_help")
        if not saves.save_game(story):
            get_tree().quit(1)
            return
        print("PASS: wrote campaign save in first process")
        get_tree().quit()
    elif "--read" in OS.get_cmdline_user_args():
        var valid: bool = saves.load_game(story) and story.current_node == "a1_help_0" and GameState.get_player_stat("hp") == 90 and GameState.choice_history == ["c1_help"]
        if valid:
            print("PASS: separate process restored campaign node, HP and choice exactly once")
        else:
            printerr("FAIL: cross-process persistence")
        for suffix in ["", ".bak", ".tmp"]:
            if FileAccess.file_exists(saves.save_path + suffix):
                DirAccess.remove_absolute(saves.save_path + suffix)
        get_tree().quit(0 if valid else 1)
    else:
        printerr("Use -- --write followed by -- --read")
        get_tree().quit(1)
