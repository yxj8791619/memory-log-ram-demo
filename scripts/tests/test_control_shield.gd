extends Node2D

const CASE_NAME := "control_shield_basic"
const TestAssert = preload("res://scripts/tests/test_assert.gd")
const TestHelpers = preload("res://scripts/tests/test_helpers.gd")

@onready var player = $Player_G
@onready var shield_ring: ColorRect = $Player_G/ControlShieldRing
@onready var combo_rule_hint: Label = $Player_G/Camera2D/ComboRuleHint

func _ready() -> void:
    await _run_test()


func _run_test() -> void:
    TestAssert.start(CASE_NAME)
    await TestHelpers.wait_physics_frames(self, 2)

    player.can_switch_layer = true
    var initial_health: int = player.current_health

    player._handle_combat_input(false, false, true, false, false, true)
    await TestHelpers.wait_physics_frames(self, 2)

    if not TestAssert.expect_true(player.is_in_layer_b, CASE_NAME, "control skill plus switch should move the player into layer B"):
        await _finish(false)
        return
    if not TestAssert.expect_true(player.control_shield_active, CASE_NAME, "control shield should become active after the shift"):
        await _finish(false)
        return
    if not TestAssert.expect_true(shield_ring.visible, CASE_NAME, "control shield should have a visible whitebox indicator"):
        await _finish(false)
        return
    if not TestAssert.expect_true(combo_rule_hint.text.contains("生成护盾"), CASE_NAME, "control shield should show an explicit rule hint"):
        await _finish(false)
        return

    player.take_damage(20)
    await TestHelpers.wait_physics_frames(self, 1)

    if not TestAssert.expect_equal(player.current_health, initial_health, CASE_NAME, "shield should negate damage while active"):
        await _finish(false)
        return

    await player.control_shield_timer.timeout
    await TestHelpers.wait_physics_frames(self, 1)

    if not TestAssert.expect_true(not player.control_shield_active, CASE_NAME, "control shield should end after its duration"):
        await _finish(false)
        return
    if not TestAssert.expect_true(not shield_ring.visible, CASE_NAME, "control shield indicator should hide after the duration"):
        await _finish(false)
        return

    player.take_damage(20)
    await TestHelpers.wait_physics_frames(self, 1)

    if not TestAssert.expect_equal(player.current_health, initial_health - 20, CASE_NAME, "damage should apply again after shield expires"):
        await _finish(false)
        return

    TestAssert.pass_case(CASE_NAME)
    await _finish(true)


func _finish(succeeded: bool) -> void:
    await TestHelpers.finish_test(self, succeeded)
