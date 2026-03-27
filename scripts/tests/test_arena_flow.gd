extends Node2D

const CASE_NAME := "arena_flow_basic"
const TestAssert = preload("res://scripts/tests/test_assert.gd")
const TestHelpers = preload("res://scripts/tests/test_helpers.gd")

@onready var arena_trigger = $ArenaTrigger
@onready var player = $Player_G

func _ready() -> void:
    await _run_test()


func _run_test() -> void:
    TestAssert.start(CASE_NAME)
    await TestHelpers.wait_physics_frames(self, 2)

    if not TestAssert.expect_true(not arena_trigger.left_door_visual.visible, CASE_NAME, "doors should start open"):
        await _finish(false)
        return
    if not TestAssert.expect_true(arena_trigger.left_door_shape.disabled and arena_trigger.right_door_shape.disabled, CASE_NAME, "door collisions should start disabled"):
        await _finish(false)
        return

    arena_trigger._on_trigger_area_body_entered(player)
    await TestHelpers.wait_physics_frames(self, 2)

    if not TestAssert.expect_true(arena_trigger.is_triggered, CASE_NAME, "trigger should enter triggered state after player entry"):
        await _finish(false)
        return
    if not TestAssert.expect_true(arena_trigger.left_door_visual.visible and arena_trigger.right_door_visual.visible, CASE_NAME, "doors should close after trigger activation"):
        await _finish(false)
        return
    if not TestAssert.expect_true(not arena_trigger.left_door_shape.disabled and not arena_trigger.right_door_shape.disabled, CASE_NAME, "door collisions should enable after trigger activation"):
        await _finish(false)
        return
    if not TestAssert.expect_equal(arena_trigger.enemies_alive, 3, CASE_NAME, "arena should spawn one enemy per spawn point"):
        await _finish(false)
        return

    var cleanup_count: int = arena_trigger.enemies_alive
    for _i in range(cleanup_count):
        arena_trigger._on_enemy_died()

    await get_tree().process_frame

    if not TestAssert.expect_equal(arena_trigger.enemies_alive, 0, CASE_NAME, "enemy counter should reach zero after arena cleanup"):
        await _finish(false)
        return
    if not TestAssert.expect_true(not arena_trigger.left_door_visual.visible and not arena_trigger.right_door_visual.visible, CASE_NAME, "doors should reopen after cleanup"):
        await _finish(false)
        return
    if not TestAssert.expect_true(arena_trigger.left_door_shape.disabled and arena_trigger.right_door_shape.disabled, CASE_NAME, "door collisions should disable after cleanup"):
        await _finish(false)
        return

    TestAssert.pass_case(CASE_NAME)
    await _finish(true)
func _finish(succeeded: bool) -> void:
    await TestHelpers.finish_test(self, succeeded)
