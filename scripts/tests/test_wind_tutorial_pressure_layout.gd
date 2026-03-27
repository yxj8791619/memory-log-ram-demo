extends Node2D

const CASE_NAME := "wind_tutorial_pressure_layout"
const TestAssert = preload("res://scripts/tests/test_assert.gd")
const TestHelpers = preload("res://scripts/tests/test_helpers.gd")

@onready var section = $WindSection

func _ready() -> void:
    await _run_test()


func _run_test() -> void:
    TestAssert.start(CASE_NAME)
    await TestHelpers.wait_physics_frames(self, 2)

    var turret = section.find_child("Spawn_B_BackgroundTurret_01", true, false)
    var wind_hint = section.find_child("Hint_WindPath", true, false)
    var input_hint = section.find_child("Hint_WindInput", true, false)

    if not TestAssert.expect_true(turret != null, CASE_NAME, "wind tutorial should include a Background Turret pressure source"):
        await _finish(false)
        return
    if not TestAssert.expect_true(wind_hint != null, CASE_NAME, "wind tutorial should include Hint_WindPath"):
        await _finish(false)
        return
    if not TestAssert.expect_true(input_hint != null, CASE_NAME, "wind tutorial should include Hint_WindInput"):
        await _finish(false)
        return
    if not TestAssert.expect_true((wind_hint as Label).text.contains("后台炮台"), CASE_NAME, "wind tutorial path hint should mention the turret pressure explicitly"):
        await _finish(false)
        return
    if not TestAssert.expect_true((input_hint as Label).text.contains("高台压力"), CASE_NAME, "wind tutorial input hint should explain the local chase pressure explicitly"):
        await _finish(false)
        return

    TestAssert.pass_case(CASE_NAME)
    await _finish(true)


func _finish(succeeded: bool) -> void:
    await TestHelpers.finish_test(self, succeeded)
