extends Node2D

const CASE_NAME := "hammer_return_group"
const TestAssert = preload("res://scripts/tests/test_assert.gd")
const TestHelpers = preload("res://scripts/tests/test_helpers.gd")

@onready var player = $Player_G
@onready var enemies: Array[Node] = [$Enemy_A, $Enemy_B, $Enemy_C]
@onready var combo_rule_hint: Label = $Player_G/Camera2D/ComboRuleHint

func _ready() -> void:
    await _run_test()


func _run_test() -> void:
    TestAssert.start(CASE_NAME)
    await TestHelpers.wait_physics_frames(self, 2)

    player.can_switch_layer = true
    player.can_use_hammer = true
    player.toggle_dimension()
    player.facing_direction = 1
    player.direction_pivot.scale.x = 1

    for index in range(enemies.size()):
        var enemy = enemies[index]
        enemy.is_active = false
        enemy.attack_box.monitoring = false
        enemy.set_enemy_layer_state(true)
        enemy.global_position = player.global_position + Vector2(36 + (index * 34), 0)

    player._handle_combat_input(false, false, true, false, true)
    await TestHelpers.wait_physics_frames(self, 2)

    if not TestAssert.expect_true(combo_rule_hint.text.contains("群体带回"), CASE_NAME, "group return should show an explicit group-carry hint"):
        await _finish(false)
        return
    if not TestAssert.expect_true(not player.is_in_layer_b, CASE_NAME, "group return should carry the player back to layer A"):
        await _finish(false)
        return

    var returned_count: int = 0
    var aoe_damaged_count: int = 0
    for enemy in enemies:
        if not enemy.is_in_layer_b:
            returned_count += 1
        if enemy.health <= 15:
            aoe_damaged_count += 1

    if not TestAssert.expect_true(returned_count >= 2, CASE_NAME, "group return should carry multiple enemies back to layer A"):
        await _finish(false)
        return
    if not TestAssert.expect_true(aoe_damaged_count >= 2, CASE_NAME, "group return should trigger follow-up AOE damage on multiple returned enemies"):
        await _finish(false)
        return

    TestAssert.pass_case(CASE_NAME)
    await _finish(true)


func _finish(succeeded: bool) -> void:
    await TestHelpers.finish_test(self, succeeded)
