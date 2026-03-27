extends SceneTree

const DEFAULT_SCENE_PATH := "res://scenes/tests/test_layer_switch.tscn"

func _init() -> void:
    var args: PackedStringArray = OS.get_cmdline_user_args()
    var scene_path: String = DEFAULT_SCENE_PATH

    if args.size() > 0 and not args[0].is_empty():
        scene_path = args[0]

    print("[TEST INFO] runner_scene=%s" % scene_path)
    var error: Error = change_scene_to_file(scene_path)
    if error != OK:
        print("[TEST BLOCKED] runner_load: cannot load %s (error=%s)" % [scene_path, error])
        quit(1)
