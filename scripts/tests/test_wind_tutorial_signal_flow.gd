extends Node2D

const CASE_NAME := "wind_tutorial_signal_flow"
const TestAssert = preload("res://scripts/tests/test_assert.gd")
const TestHelpers = preload("res://scripts/tests/test_helpers.gd")

@onready var wind_section = $WindSection
@onready var player = $Player_G

func _ready() -> void:
    await _run_test()


func _run_test() -> void:
    TestAssert.start(CASE_NAME)
    await TestHelpers.wait_physics_frames(self, 2)

    var chase_trigger = wind_section.find_child("Trigger_RevealChasePlan", true, false)
    var fallback_trigger = wind_section.find_child("Trigger_RevealFallback", true, false)
    var wind_hint = wind_section.find_child("Hint_WindPath", true, false)
    var shield_zone = wind_section.find_child("ShieldFallbackZone", true, false)
    var shield_zone_hint = wind_section.find_child("Hint_ShieldFallbackZone", true, false)
    var shield_input_hint = wind_section.find_child("Hint_ControlShield", true, false)

    if not TestAssert.expect_true(chase_trigger != null and fallback_trigger != null, CASE_NAME, "wind tutorial should include both reveal triggers"):
        await _finish(false)
        return
    if not TestAssert.expect_true(not (wind_hint as Label).visible, CASE_NAME, "wind path hint should start hidden"):
        await _finish(false)
        return
    if not TestAssert.expect_true(not (shield_zone_hint as Label).visible, CASE_NAME, "shield fallback hint should start hidden"):
        await _finish(false)
        return
    if not TestAssert.expect_true(not (shield_input_hint as Label).visible, CASE_NAME, "shield input hint should start hidden"):
        await _finish(false)
        return
    if not TestAssert.expect_true(not (shield_zone as ColorRect).visible, CASE_NAME, "shield fallback zone should start hidden"):
        await _finish(false)
        return

    chase_trigger._on_body_entered(player)
    await TestHelpers.wait_physics_frames(self, 1)

    if not TestAssert.expect_true((wind_hint as Label).visible, CASE_NAME, "mid-route reveal should show the chase-plan hint"):
        await _finish(false)
        return
    if not TestAssert.expect_true(not (shield_zone_hint as Label).visible, CASE_NAME, "late fallback hint should still stay hidden after the mid-route reveal"):
        await _finish(false)
        return

    fallback_trigger._on_body_entered(player)
    await TestHelpers.wait_physics_frames(self, 1)

    if not TestAssert.expect_true((shield_zone as ColorRect).visible, CASE_NAME, "late-route reveal should show the fallback zone"):
        await _finish(false)
        return
    if not TestAssert.expect_true((shield_zone_hint as Label).visible, CASE_NAME, "late-route reveal should show the fallback hint"):
        await _finish(false)
        return
    if not TestAssert.expect_true((shield_input_hint as Label).visible, CASE_NAME, "late-route reveal should show the shield input hint"):
        await _finish(false)
        return

    TestAssert.pass_case(CASE_NAME)
    await _finish(true)


func _finish(succeeded: bool) -> void:
    await TestHelpers.finish_test(self, succeeded)
