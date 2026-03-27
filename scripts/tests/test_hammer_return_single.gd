extends Node2D

const CASE_NAME := "hammer_return_single"
const TestAssert = preload("res://scripts/tests/test_assert.gd")
const TestHelpers = preload("res://scripts/tests/test_helpers.gd")

@onready var player = $Player_G
@onready var enemy = $Enemy_Dummy
@onready var hammer_hitbox = $Player_G/DirectionPivot/HammerHitbox
@onready var hammer_collision: CollisionShape2D = $Player_G/DirectionPivot/HammerHitbox/CollisionShape2D
@onready var combo_rule_hint: Label = $Player_G/Camera2D/ComboRuleHint

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
    enemy.global_position = player.global_position + Vector2(32, 0)

    var initial_health: int = enemy.health

    player._handle_combat_input(true, false, false, false)
    await TestHelpers.wait_physics_frames(self, 2)

    if not TestAssert.expect_true(combo_rule_hint.visible, CASE_NAME, "basic B-layer hammer should show an explicit stay-in-B hint"):
        await _finish(false)
        return
    if not TestAssert.expect_true(combo_rule_hint.text.contains("留在 B 层"), CASE_NAME, "basic B-layer hammer hint should explain that the player stays in B"):
        await _finish(false)
        return
    if not TestAssert.expect_true(player.is_in_layer_b, CASE_NAME, "basic B-layer hammer should not move player back to layer A"):
        await _finish(false)
        return
    if not TestAssert.expect_true(enemy.is_in_layer_b, CASE_NAME, "basic B-layer hammer should not move enemy back to layer A"):
        await _finish(false)
        return
    if not TestAssert.expect_true(enemy.health < initial_health, CASE_NAME, "basic B-layer hammer should still deal damage before the return-cut test"):
        await _finish(false)
        return

    var post_basic_health: int = enemy.health

    if not TestAssert.expect_true(player._should_trigger_return_cut(true), CASE_NAME, "B-layer hammer plus switch input should resolve to return cut"):
        await _finish(false)
        return

    player._handle_combat_input(false, true, false, false)
    await TestHelpers.wait_physics_frames(self, 1)

    if not TestAssert.expect_true(combo_rule_hint.text.contains("只切自己"), CASE_NAME, "plain layer switch hint should explain that TAB / right click only moves the player"):
        await _finish(false)
        return
    if not TestAssert.expect_true(not player.is_in_layer_b, CASE_NAME, "plain layer switch should still move only the player back to A"):
        await _finish(false)
        return
    if not TestAssert.expect_true(enemy.is_in_layer_b, CASE_NAME, "plain layer switch should not drag the enemy back to A"):
        await _finish(false)
        return

    player.toggle_dimension()
    await TestHelpers.wait_physics_frames(self, 1)

    player._handle_combat_input(true, false, true, false)
    hammer_collision.disabled = false
    hammer_hitbox._try_hit_area(enemy.hurtbox)
    await TestHelpers.wait_physics_frames(self, 2)
    hammer_collision.disabled = true

    if not TestAssert.expect_true(combo_rule_hint.text.contains("带怪回 A 层"), CASE_NAME, "return cut hint should explain that attack plus switch carries the target back to A"):
        await _finish(false)
        return
    if not TestAssert.expect_true(not player.is_in_layer_b, CASE_NAME, "player should return to layer A after hammer return hit"):
        await _finish(false)
        return
    if not TestAssert.expect_true(not enemy.is_in_layer_b, CASE_NAME, "enemy should be returned to layer A after hammer return hit"):
        await _finish(false)
        return
    if not TestAssert.expect_true(enemy.health < post_basic_health, CASE_NAME, "return cut should preserve damage when carrying the enemy back to A"):
        await _finish(false)
        return
    if not TestAssert.expect_true(enemy.hurtbox.monitorable, CASE_NAME, "enemy should remain interactable after being returned to A"):
        await _finish(false)
        return

    TestAssert.pass_case(CASE_NAME)
    await _finish(true)


func _finish(succeeded: bool) -> void:
    await TestHelpers.finish_test(self, succeeded)
