extends Node2D

const CASE_NAME := "hammer_hits_chapter2_enemy"
const TestAssert = preload("res://scripts/tests/test_assert.gd")
const TestHelpers = preload("res://scripts/tests/test_helpers.gd")

@onready var player = $Player_G
@onready var enemy = $FrontHound
@onready var hammer_hitbox = $Player_G/DirectionPivot/HammerHitbox
@onready var hammer_collision: CollisionShape2D = $Player_G/DirectionPivot/HammerHitbox/CollisionShape2D

func _ready() -> void:
    await _run_test()


func _run_test() -> void:
    TestAssert.start(CASE_NAME)
    await TestHelpers.wait_physics_frames(self, 2)

    enemy.is_active = false
    enemy.attack_box.monitoring = false
    enemy.set_enemy_layer_state(true)
    player.can_switch_layer = true
    player.can_use_hammer = true
    player.toggle_dimension()
    player.facing_direction = 1
    player.direction_pivot.scale.x = 1
    enemy.global_position = player.global_position + Vector2(40, 0)
    await TestHelpers.wait_physics_frames(self, 2)

    var initial_health: int = enemy.health
    hammer_collision.disabled = false
    hammer_hitbox.perform_manual_swing()
    await TestHelpers.wait_physics_frames(self, 2)
    hammer_collision.disabled = true

    if not TestAssert.expect_true(enemy.health < initial_health, CASE_NAME, "hammer should damage chapter2 enemy on real overlap"):
        await _finish(false)
        return
    if not TestAssert.expect_true(not enemy.is_in_layer_b, CASE_NAME, "hammer should return chapter2 enemy to A layer"):
        await _finish(false)
        return
    if not TestAssert.expect_true(not player.is_in_layer_b, CASE_NAME, "hammer return should also pull player back to A layer"):
        await _finish(false)
        return

    TestAssert.pass_case(CASE_NAME)
    await _finish(true)


func _finish(succeeded: bool) -> void:
    await TestHelpers.finish_test(self, succeeded)
