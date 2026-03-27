extends Node2D

const CASE_NAME := "chapter2_ground_survives_layer_switch"
const TestAssert = preload("res://scripts/tests/test_assert.gd")
const TestHelpers = preload("res://scripts/tests/test_helpers.gd")

@onready var chapter = $Chapter2Main
@onready var player = $Chapter2Main/Player_G

func _ready() -> void:
    await _run_test()


func _run_test() -> void:
    TestAssert.start(CASE_NAME)
    await TestHelpers.wait_physics_frames(self, 24)

    var start_y: float = player.global_position.y
    if not TestAssert.expect_true(player.is_on_floor(), CASE_NAME, "player should start grounded in chapter2 before switch"):
        await _finish(false)
        return

    player.can_switch_layer = true
    player.toggle_dimension()
    await TestHelpers.wait_physics_frames(self, 6)

    if not TestAssert.expect_true(player.is_in_layer_b, CASE_NAME, "player should be in layer B after switch"):
        await _finish(false)
        return
    if not TestAssert.expect_true(player.is_on_floor(), CASE_NAME, "player should remain grounded after switching in chapter2"):
        await _finish(false)
        return
    if not TestAssert.expect_true(absf(player.global_position.y - start_y) <= 8.0, CASE_NAME, "player should not fall out of world after switching in chapter2"):
        await _finish(false)
        return

    TestAssert.pass_case(CASE_NAME)
    await _finish(true)


func _finish(succeeded: bool) -> void:
    await TestHelpers.finish_test(self, succeeded)
