extends Node2D

const CASE_NAME := "control_shield_route_hint"
const TestAssert = preload("res://scripts/tests/test_assert.gd")
const TestHelpers = preload("res://scripts/tests/test_helpers.gd")

@onready var wind_section = $WindSection

func _ready() -> void:
    await _run_test()


func _run_test() -> void:
    TestAssert.start(CASE_NAME)
    await TestHelpers.wait_physics_frames(self, 2)

    var shield_hint = wind_section.find_child("Hint_ControlShield", true, false)
    var fallback_hint = wind_section.find_child("Hint_ShieldFallbackZone", true, false)
    if not TestAssert.expect_true(shield_hint != null, CASE_NAME, "wind tutorial should include a control shield route hint"):
        await _finish(false)
        return
    if not TestAssert.expect_true(fallback_hint != null, CASE_NAME, "wind tutorial should include the fallback-zone hint near the control shield prompt"):
        await _finish(false)
        return

    var shield_text: String = (shield_hint as Label).text
    if not TestAssert.expect_true(shield_text.contains("控制技 + 切层键"), CASE_NAME, "control shield route hint should name the shield input explicitly"):
        await _finish(false)
        return
    if not TestAssert.expect_true(shield_text.contains("护盾"), CASE_NAME, "control shield route hint should explain the shield result explicitly"):
        await _finish(false)
        return
    if not TestAssert.expect_true(shield_text.contains("切入 B 层"), CASE_NAME, "control shield route hint should explain the route usage in B layer"):
        await _finish(false)
        return
    if not TestAssert.expect_true(not shield_text.contains("主路线失手"), CASE_NAME, "control shield route hint should focus on input/result, leaving timing to the fallback-zone label"):
        await _finish(false)
        return
    if not TestAssert.expect_true((shield_hint as Label).position.distance_to((fallback_hint as Label).position) < 320.0, CASE_NAME, "control shield route hint should sit near the fallback-zone label so the player reads timing and input together"):
        await _finish(false)
        return

    TestAssert.pass_case(CASE_NAME)
    await _finish(true)


func _finish(succeeded: bool) -> void:
    await TestHelpers.finish_test(self, succeeded)
