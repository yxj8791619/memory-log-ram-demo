extends Node2D

const CASE_NAME := "front_hound_profile"
const TestAssert = preload("res://scripts/tests/test_assert.gd")
const TestHelpers = preload("res://scripts/tests/test_helpers.gd")

@onready var hound = $FrontHound

func _ready() -> void:
    await _run_test()


func _run_test() -> void:
    TestAssert.start(CASE_NAME)
    await TestHelpers.wait_physics_frames(self, 2)

    hound.facing_direction = 1
    hound.velocity = Vector2.ZERO
    hound.set_enemy_layer_state(false)
    hound._maybe_start_pounce()
    var a_velocity: Vector2 = hound.velocity

    hound.pounce_ready = true
    hound.velocity = Vector2.ZERO
    hound.set_enemy_layer_state(true)
    hound._maybe_start_pounce()
    var b_velocity: Vector2 = hound.velocity

    if not TestAssert.expect_true(absf(b_velocity.y) > absf(a_velocity.y), CASE_NAME, "B layer pounce should have a larger vertical component"):
        await _finish(false)
        return
    if not TestAssert.expect_true(absf(b_velocity.x) < absf(a_velocity.x), CASE_NAME, "B layer pounce should trade horizontal clarity for floatier arc"):
        await _finish(false)
        return

    TestAssert.pass_case(CASE_NAME)
    await _finish(true)


func _finish(succeeded: bool) -> void:
    await TestHelpers.finish_test(self, succeeded)
