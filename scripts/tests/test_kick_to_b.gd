extends Node2D

const CASE_NAME := "kick_to_b"
const TestAssert = preload("res://scripts/tests/test_assert.gd")
const TestHelpers = preload("res://scripts/tests/test_helpers.gd")

@onready var player = $Player_G
@onready var enemy = $Enemy_Dummy

func _ready() -> void:
    await _run_test()


func _run_test() -> void:
    TestAssert.start(CASE_NAME)
    await TestHelpers.wait_physics_frames(self, 2)

    enemy.is_active = false
    enemy.attack_box.monitoring = false
    enemy.velocity = Vector2.ZERO
    enemy.global_position = player.global_position + Vector2(24, 0)
    player.facing_direction = 1
    player.direction_pivot.scale.x = 1

    if not TestAssert.expect_true(player._is_enemy_in_kick_range(enemy), CASE_NAME, "enemy should be positioned inside kick range before the kick test starts"):
        await _finish(false)
        return

    var initial_health: int = enemy.health
    var kicked: bool = player.perform_kick_to_b()
    await TestHelpers.wait_physics_frames(self, 2)

    if not TestAssert.expect_true(kicked, CASE_NAME, "player should find a target inside kick range"):
        await _finish(false)
        return
    if not TestAssert.expect_true(enemy.is_in_layer_b, CASE_NAME, "enemy should be moved into layer B after kick"):
        await _finish(false)
        return
    if not TestAssert.expect_equal(enemy.health, initial_health, CASE_NAME, "kick should preserve enemy health state"):
        await _finish(false)
        return
    if not TestAssert.expect_true(not enemy.hurtbox.monitorable, CASE_NAME, "enemy hurtbox should stop interacting with A-layer player after kick"):
        await _finish(false)
        return

    player.can_switch_layer = true
    player.toggle_dimension()
    await TestHelpers.wait_physics_frames(self, 2)

    if not TestAssert.expect_true(enemy.hurtbox.monitorable, CASE_NAME, "enemy should become interactable again when player enters the same layer"):
        await _finish(false)
        return

    TestAssert.pass_case(CASE_NAME)
    await _finish(true)


func _finish(succeeded: bool) -> void:
    await TestHelpers.finish_test(self, succeeded)
