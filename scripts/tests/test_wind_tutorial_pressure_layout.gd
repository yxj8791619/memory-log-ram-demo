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
    var front_hound = section.find_child("Spawn_A_FrontHound_Chase_01", true, false)
    var prep_ledge = section.find_child("PrepLedge_A", true, false)
    var wind_hint = section.find_child("Hint_WindPath", true, false)
    var input_hint = section.find_child("Hint_WindInput", true, false)
    var route_step_01 = section.find_child("Hint_RouteStep01", true, false)
    var route_step_01b = section.find_child("Hint_RouteStep01B", true, false)
    var route_step_02 = section.find_child("Hint_RouteStep02", true, false)
    var route_step_03 = section.find_child("Hint_RouteStep03", true, false)

    if not TestAssert.expect_true(turret != null, CASE_NAME, "wind tutorial should include a Background Turret pressure source"):
        await _finish(false)
        return
    if not TestAssert.expect_true(front_hound != null, CASE_NAME, "wind tutorial should include a Front Hound chase threat instead of a dummy placeholder"):
        await _finish(false)
        return
    if not TestAssert.expect_true(prep_ledge != null, CASE_NAME, "wind tutorial should include a prep ledge that bridges into the chase route"):
        await _finish(false)
        return
    if not TestAssert.expect_true(wind_hint != null, CASE_NAME, "wind tutorial should include Hint_WindPath"):
        await _finish(false)
        return
    if not TestAssert.expect_true(input_hint != null, CASE_NAME, "wind tutorial should include Hint_WindInput"):
        await _finish(false)
        return
    if not TestAssert.expect_true(route_step_01 != null, CASE_NAME, "wind tutorial should include Hint_RouteStep01"):
        await _finish(false)
        return
    if not TestAssert.expect_true(route_step_01b != null, CASE_NAME, "wind tutorial should include Hint_RouteStep01B"):
        await _finish(false)
        return
    if not TestAssert.expect_true(route_step_02 != null, CASE_NAME, "wind tutorial should include Hint_RouteStep02"):
        await _finish(false)
        return
    if not TestAssert.expect_true(route_step_03 != null, CASE_NAME, "wind tutorial should include Hint_RouteStep03"):
        await _finish(false)
        return
    if not TestAssert.expect_true((wind_hint as Label).text.contains("后台炮台"), CASE_NAME, "wind tutorial path hint should mention the turret pressure explicitly"):
        await _finish(false)
        return
    if not TestAssert.expect_true((wind_hint as Label).text.contains("Front Hound"), CASE_NAME, "wind tutorial path hint should mention the foreground chase threat explicitly"):
        await _finish(false)
        return
    if not TestAssert.expect_true((input_hint as Label).text.contains("高台压力"), CASE_NAME, "wind tutorial input hint should explain the local chase pressure explicitly"):
        await _finish(false)
        return
    if not TestAssert.expect_true((route_step_01 as Label).text.contains("先开枪做 B 层风道"), CASE_NAME, "wind tutorial should mark the first route step explicitly"):
        await _finish(false)
        return
    if not TestAssert.expect_true((route_step_01b as Label).text.contains("中间预备台"), CASE_NAME, "wind tutorial should mark the prep ledge step explicitly"):
        await _finish(false)
        return
    if not TestAssert.expect_true((route_step_02 as Label).text.contains("沿风道继续追"), CASE_NAME, "wind tutorial should mark the chase step explicitly"):
        await _finish(false)
        return
    if not TestAssert.expect_true((route_step_03 as Label).text.contains("带护盾切进 B 层"), CASE_NAME, "wind tutorial should mark the fallback shield step explicitly"):
        await _finish(false)
        return

    TestAssert.pass_case(CASE_NAME)
    await _finish(true)


func _finish(succeeded: bool) -> void:
    await TestHelpers.finish_test(self, succeeded)
