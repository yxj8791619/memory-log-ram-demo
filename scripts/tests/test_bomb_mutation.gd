extends Node2D

const CASE_NAME := "bomb_mutation_basic"
const TestAssert = preload("res://scripts/tests/test_assert.gd")
const TestHelpers = preload("res://scripts/tests/test_helpers.gd")

@onready var player = $Player_G
@onready var enemy_a = $Enemy_A
@onready var enemy_b = $Enemy_B
@onready var bomb_field_visual: ColorRect = $Player_G/BombMutationField
@onready var combo_rule_hint: Label = $Player_G/Camera2D/ComboRuleHint

func _ready() -> void:
    await _run_test()


func _run_test() -> void:
    TestAssert.start(CASE_NAME)
    await TestHelpers.wait_physics_frames(self, 2)

    player.can_switch_layer = true
    enemy_a.is_active = false
    enemy_b.is_active = false
    enemy_a.attack_box.monitoring = false
    enemy_b.attack_box.monitoring = false
    enemy_a.global_position = player.global_position + Vector2(52, 0)
    enemy_b.global_position = player.global_position + Vector2(54, 0)
    enemy_b.set_enemy_layer_state(true)

    var initial_a_health: int = enemy_a.health
    var initial_b_health: int = enemy_b.health

    player._handle_combat_input(false, false, false, false, false, false, true)
    await TestHelpers.wait_physics_frames(self, 2)

    if not TestAssert.expect_true(combo_rule_hint.text.contains("留在 A 层"), CASE_NAME, "plain bomb should explain that it stays in layer A"):
        await _finish(false)
        return
    if not TestAssert.expect_true(not player.is_in_layer_b, CASE_NAME, "plain bomb should not switch layers"):
        await _finish(false)
        return
    if not TestAssert.expect_true(enemy_a.health < initial_a_health, CASE_NAME, "plain bomb should damage A-layer enemies in range"):
        await _finish(false)
        return
    if not TestAssert.expect_equal(enemy_b.health, initial_b_health, CASE_NAME, "plain bomb should not damage B-layer enemies while player stays in A"):
        await _finish(false)
        return

    enemy_a.health = 100
    enemy_b.health = 100
    player._handle_combat_input(false, false, true, false, false, false, true)
    await TestHelpers.wait_physics_frames(self, 2)

    if not TestAssert.expect_true(player.is_in_layer_b, CASE_NAME, "bomb plus switch should move the player into layer B"):
        await _finish(false)
        return
    if not TestAssert.expect_true(combo_rule_hint.text.contains("异化爆发"), CASE_NAME, "bomb mutation should show an explicit rule hint"):
        await _finish(false)
        return
    if not TestAssert.expect_true(bomb_field_visual.visible, CASE_NAME, "bomb mutation should leave a visible whitebox field marker"):
        await _finish(false)
        return
    if not TestAssert.expect_equal(enemy_a.health, 100, CASE_NAME, "bomb mutation should stop affecting A-layer enemies once the blast is moved to B"):
        await _finish(false)
        return
    if not TestAssert.expect_true(enemy_b.health < 100, CASE_NAME, "bomb mutation should damage B-layer enemies in range"):
        await _finish(false)
        return

    await player.bomb_mutation_field_timer.timeout
    await TestHelpers.wait_physics_frames(self, 1)

    if not TestAssert.expect_true(not bomb_field_visual.visible, CASE_NAME, "bomb mutation field marker should hide after the duration"):
        await _finish(false)
        return

    TestAssert.pass_case(CASE_NAME)
    await _finish(true)


func _finish(succeeded: bool) -> void:
    await TestHelpers.finish_test(self, succeeded)
