extends Node2D

const CASE_NAME := "page_lock_guard_profile"
const TestAssert = preload("res://scripts/tests/test_assert.gd")
const TestHelpers = preload("res://scripts/tests/test_helpers.gd")

@onready var player = $Player_G
@onready var guard = $PageLockGuard

func _ready() -> void:
    await _run_test()


func _run_test() -> void:
    TestAssert.start(CASE_NAME)
    await TestHelpers.wait_physics_frames(self, 2)

    var health_before_front_a: int = guard.health
    guard.facing_direction = -1
    guard._update_facing_setup()
    guard.take_damage(40, 1.0, 0.0)
    await TestHelpers.wait_physics_frames(self, 1)
    var a_front_damage: int = health_before_front_a - guard.health

    if not TestAssert.expect_true(a_front_damage <= 10, CASE_NAME, "front hit in A layer should be heavily reduced"):
        await _finish(false)
        return

    guard.health = guard.max_health
    guard.set_enemy_layer_state(true)
    guard.facing_direction = -1
    guard._update_facing_setup()
    var health_before_back_b: int = guard.health
    guard.take_damage(40, -1.0, 0.0)
    await TestHelpers.wait_physics_frames(self, 1)
    var b_back_damage: int = health_before_back_b - guard.health

    if not TestAssert.expect_true(b_back_damage >= 45, CASE_NAME, "back hit in B layer should deal amplified damage"):
        await _finish(false)
        return

    TestAssert.pass_case(CASE_NAME)
    await _finish(true)


func _finish(succeeded: bool) -> void:
    await TestHelpers.finish_test(self, succeeded)
