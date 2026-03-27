extends RefCounted
class_name TestHelpers

static func wait_physics_frames(node: Node, frame_count: int = 1) -> void:
    for _i in range(frame_count):
        await node.get_tree().physics_frame


static func finish_test(node: Node, succeeded: bool, exit_code: int = 0) -> void:
    await node.get_tree().process_frame
    node.get_tree().quit(exit_code if succeeded else 1)
