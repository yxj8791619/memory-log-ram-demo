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
    var turret = wind_section.find_child("Spawn_B_BackgroundTurret_01", true, false)
    var hound = wind_section.find_child("Spawn_A_FrontHound_Chase_01", true, false)
    var route_beam = wind_section.find_child("WindRouteBeam", true, false)
    var chase_zone = wind_section.find_child("ChasePressureZone", true, false)
    var turret_lane = wind_section.find_child("TurretPressureLane", true, false)
    var exit_beacon = wind_section.find_child("ExitGoalBeacon", true, false)
    var exit_landing = wind_section.find_child("ExitLandingZone", true, false)
    var fallback_gate = wind_section.find_child("FallbackGate", true, false)
    var fallback_stand = wind_section.find_child("FallbackStandZone", true, false)
    var wind_hint = wind_section.find_child("Hint_WindPath", true, false)
    var shield_zone = wind_section.find_child("ShieldFallbackZone", true, false)
    var shield_zone_hint = wind_section.find_child("Hint_ShieldFallbackZone", true, false)
    var shield_input_hint = wind_section.find_child("Hint_ControlShield", true, false)

    if not TestAssert.expect_true(chase_trigger != null and fallback_trigger != null and turret != null and hound != null, CASE_NAME, "wind tutorial should include both reveal triggers, the backline turret, and the chase hound"):
        await _finish(false)
        return
    if not TestAssert.expect_true(route_beam != null and chase_zone != null and turret_lane != null and exit_beacon != null and exit_landing != null and fallback_gate != null and fallback_stand != null, CASE_NAME, "wind tutorial should include whitebox signals for the chase lane, pressure zone, exit goal, exit landing, fallback gate, fallback stand, and late turret lane"):
        await _finish(false)
        return
    if not TestAssert.expect_true(absf(float(turret.get("fire_interval")) - 1.7) < 0.01, CASE_NAME, "wind turret should start in a slower pressure state before the fallback reveal"):
        await _finish(false)
        return
    if not TestAssert.expect_true(absf(float(hound.get("chase_speed_scale")) - 0.82) < 0.01, CASE_NAME, "wind hound should start in a softer chase state before the mid-route reveal"):
        await _finish(false)
        return
    if not TestAssert.expect_true(absf(float(hound.get("pounce_cooldown_scale")) - 1.25) < 0.01, CASE_NAME, "wind hound should start with a slower pounce cadence before the mid-route reveal"):
        await _finish(false)
        return
    if not TestAssert.expect_true(not (wind_hint as Label).visible, CASE_NAME, "wind path hint should start hidden"):
        await _finish(false)
        return
    if not TestAssert.expect_true(not (route_beam as ColorRect).visible, CASE_NAME, "wind route beam should start hidden"):
        await _finish(false)
        return
    if not TestAssert.expect_true(not (chase_zone as ColorRect).visible, CASE_NAME, "chase pressure zone should start hidden"):
        await _finish(false)
        return
    if not TestAssert.expect_true(not (turret_lane as ColorRect).visible, CASE_NAME, "turret pressure lane should start hidden"):
        await _finish(false)
        return
    if not TestAssert.expect_true(not (exit_beacon as ColorRect).visible, CASE_NAME, "exit goal beacon should start hidden"):
        await _finish(false)
        return
    if not TestAssert.expect_true(not (exit_landing as ColorRect).visible, CASE_NAME, "exit landing zone should start hidden"):
        await _finish(false)
        return
    if not TestAssert.expect_true(not (fallback_gate as ColorRect).visible, CASE_NAME, "fallback gate should start hidden"):
        await _finish(false)
        return
    if not TestAssert.expect_true(not (fallback_stand as ColorRect).visible, CASE_NAME, "fallback stand zone should start hidden"):
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
    if not TestAssert.expect_true((route_beam as ColorRect).visible, CASE_NAME, "mid-route reveal should show the wind-route beam"):
        await _finish(false)
        return
    if not TestAssert.expect_true((chase_zone as ColorRect).visible, CASE_NAME, "mid-route reveal should show the chase pressure zone"):
        await _finish(false)
        return
    if not TestAssert.expect_true((exit_beacon as ColorRect).visible, CASE_NAME, "mid-route reveal should show the exit goal beacon"):
        await _finish(false)
        return
    if not TestAssert.expect_true((exit_landing as ColorRect).visible, CASE_NAME, "mid-route reveal should show the exit landing zone"):
        await _finish(false)
        return
    if not TestAssert.expect_true(absf(float(hound.get("chase_speed_scale")) - 1.0) < 0.01, CASE_NAME, "mid-route reveal should restore the hound to full chase speed"):
        await _finish(false)
        return
    if not TestAssert.expect_true(absf(float(hound.get("pounce_cooldown_scale")) - 1.0) < 0.01, CASE_NAME, "mid-route reveal should restore the hound to full pounce cadence"):
        await _finish(false)
        return
    if not TestAssert.expect_true(not (shield_zone_hint as Label).visible, CASE_NAME, "late fallback hint should still stay hidden after the mid-route reveal"):
        await _finish(false)
        return
    if not TestAssert.expect_true(not (turret_lane as ColorRect).visible, CASE_NAME, "late turret lane should still stay hidden after the mid-route reveal"):
        await _finish(false)
        return
    if not TestAssert.expect_true(not (fallback_gate as ColorRect).visible, CASE_NAME, "fallback gate should still stay hidden after the mid-route reveal"):
        await _finish(false)
        return
    if not TestAssert.expect_true(not (fallback_stand as ColorRect).visible, CASE_NAME, "fallback stand zone should still stay hidden after the mid-route reveal"):
        await _finish(false)
        return

    fallback_trigger._on_body_entered(player)
    await TestHelpers.wait_physics_frames(self, 1)

    if not TestAssert.expect_true((turret_lane as ColorRect).visible, CASE_NAME, "late-route reveal should show the turret pressure lane"):
        await _finish(false)
        return
    if not TestAssert.expect_true((fallback_gate as ColorRect).visible, CASE_NAME, "late-route reveal should show the fallback gate"):
        await _finish(false)
        return
    if not TestAssert.expect_true((fallback_stand as ColorRect).visible, CASE_NAME, "late-route reveal should show the fallback stand zone"):
        await _finish(false)
        return
    if not TestAssert.expect_true((shield_zone as ColorRect).visible, CASE_NAME, "late-route reveal should show the fallback zone"):
        await _finish(false)
        return
    if not TestAssert.expect_true((shield_zone_hint as Label).visible, CASE_NAME, "late-route reveal should show the fallback hint"):
        await _finish(false)
        return
    if not TestAssert.expect_true((shield_input_hint as Label).visible, CASE_NAME, "late-route reveal should show the shield input hint"):
        await _finish(false)
        return
    if not TestAssert.expect_true(absf(float(turret.get("fire_interval")) - 1.05) < 0.01, CASE_NAME, "late-route reveal should speed up the turret to make the fallback timing real"):
        await _finish(false)
        return

    TestAssert.pass_case(CASE_NAME)
    await _finish(true)


func _finish(succeeded: bool) -> void:
    await TestHelpers.finish_test(self, succeeded)
