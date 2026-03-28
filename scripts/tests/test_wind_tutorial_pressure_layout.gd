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
    var chase_trigger = section.find_child("Trigger_RevealChasePlan", true, false)
    var fallback_trigger = section.find_child("Trigger_RevealFallback", true, false)
    var route_beam = section.find_child("WindRouteBeam", true, false)
    var chase_zone = section.find_child("ChasePressureZone", true, false)
    var shield_zone = section.find_child("ShieldFallbackZone", true, false)
    var late_pickup = section.find_child("Pickup_03", true, false)
    var wind_hint = section.find_child("Hint_WindPath", true, false)
    var input_hint = section.find_child("Hint_WindInput", true, false)
    var route_step_01 = section.find_child("Hint_RouteStep01", true, false)
    var route_step_02 = section.find_child("Hint_RouteStep02", true, false)
    var shield_zone_hint = section.find_child("Hint_ShieldFallbackZone", true, false)

    if not TestAssert.expect_true(turret != null, CASE_NAME, "wind tutorial should include a Background Turret pressure source"):
        await _finish(false)
        return
    if not TestAssert.expect_true(front_hound != null, CASE_NAME, "wind tutorial should include a Front Hound chase threat instead of a dummy placeholder"):
        await _finish(false)
        return
    if not TestAssert.expect_true(prep_ledge != null, CASE_NAME, "wind tutorial should include a prep ledge that bridges into the chase route"):
        await _finish(false)
        return
    if not TestAssert.expect_true(chase_trigger != null, CASE_NAME, "wind tutorial should include a chase-plan reveal trigger"):
        await _finish(false)
        return
    if not TestAssert.expect_true(fallback_trigger != null, CASE_NAME, "wind tutorial should include a fallback reveal trigger"):
        await _finish(false)
        return
    if not TestAssert.expect_true(route_beam != null, CASE_NAME, "wind tutorial should include a visible mid-route beam for the main wind lane"):
        await _finish(false)
        return
    if not TestAssert.expect_true(chase_zone != null, CASE_NAME, "wind tutorial should include a visible chase-pressure zone signal"):
        await _finish(false)
        return
    if not TestAssert.expect_true(shield_zone != null, CASE_NAME, "wind tutorial should include a visible shield fallback zone for human-readable testing"):
        await _finish(false)
        return
    if not TestAssert.expect_true(late_pickup != null, CASE_NAME, "wind tutorial should keep the late-route pickup marker for pacing checks"):
        await _finish(false)
        return
    if not TestAssert.expect_true((front_hound as Node2D).global_position.x < (turret as Node2D).global_position.x, CASE_NAME, "wind tutorial should stage the front chase threat before the backline turret pressure"):
        await _finish(false)
        return
    if not TestAssert.expect_true((chase_zone as ColorRect).global_position.x <= (front_hound as Node2D).global_position.x + 40.0, CASE_NAME, "wind tutorial should place the chase-pressure zone around the front threat rather than near the late fallback area"):
        await _finish(false)
        return
    if not TestAssert.expect_true((route_beam as ColorRect).global_position.x > (front_hound as Node2D).global_position.x, CASE_NAME, "wind tutorial should reveal the main-route beam after the hound so it reads as the continuation path"):
        await _finish(false)
        return
    if not TestAssert.expect_true((route_beam as ColorRect).global_position.x < (shield_zone as ColorRect).global_position.x, CASE_NAME, "wind tutorial should keep the main-route beam before the shield fallback zone"):
        await _finish(false)
        return
    if not TestAssert.expect_true((shield_zone as ColorRect).global_position.x >= (turret as Node2D).global_position.x - 240.0, CASE_NAME, "wind tutorial should place the shield fallback zone near the late-pressure area"):
        await _finish(false)
        return
    if not TestAssert.expect_true((shield_zone as ColorRect).global_position.x > (late_pickup as Node2D).global_position.x, CASE_NAME, "wind tutorial should place the shield fallback zone after the late main-route pickup so it reads as a fallback route"):
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
    if not TestAssert.expect_true(route_step_02 != null, CASE_NAME, "wind tutorial should include Hint_RouteStep02"):
        await _finish(false)
        return
    if not TestAssert.expect_true(shield_zone_hint != null, CASE_NAME, "wind tutorial should include Hint_ShieldFallbackZone"):
        await _finish(false)
        return
    if not TestAssert.expect_true((wind_hint as Label).position.distance_to((route_step_02 as Label).position) < 260.0, CASE_NAME, "wind tutorial should place the main-route hint near the chase-step label to reduce mid-route scanning"):
        await _finish(false)
        return
    if not TestAssert.expect_true(not (wind_hint as Label).visible, CASE_NAME, "wind tutorial should hide the chase-plan hint until the player reaches the mid-route reveal zone"):
        await _finish(false)
        return
    if not TestAssert.expect_true(not (route_beam as ColorRect).visible, CASE_NAME, "wind tutorial should hide the route beam until the player reaches the mid-route reveal zone"):
        await _finish(false)
        return
    if not TestAssert.expect_true(not (chase_zone as ColorRect).visible, CASE_NAME, "wind tutorial should hide the chase-pressure zone until the player reaches the mid-route reveal zone"):
        await _finish(false)
        return
    if not TestAssert.expect_true(not (shield_zone as ColorRect).visible, CASE_NAME, "wind tutorial should hide the fallback-zone whitebox signal until the late-route reveal fires"):
        await _finish(false)
        return
    if not TestAssert.expect_true(not (shield_zone_hint as Label).visible, CASE_NAME, "wind tutorial should hide the fallback-zone hint until the player reaches the late route"):
        await _finish(false)
        return
    if not TestAssert.expect_true((wind_hint as Label).text.contains("后台炮台"), CASE_NAME, "wind tutorial path hint should mention the turret pressure explicitly"):
        await _finish(false)
        return
    if not TestAssert.expect_true((wind_hint as Label).text.contains("Front Hound"), CASE_NAME, "wind tutorial path hint should mention the foreground chase threat explicitly"):
        await _finish(false)
        return
    if not TestAssert.expect_true((wind_hint as Label).text.contains("先被"), CASE_NAME, "wind tutorial path hint should make the pressure order explicit"):
        await _finish(false)
        return
    if not TestAssert.expect_true((wind_hint as Label).text.contains("主路线先走枪 -> 风道"), CASE_NAME, "wind tutorial path hint should keep the main route focused on gun-to-wind"):
        await _finish(false)
        return
    if not TestAssert.expect_true((wind_hint as Label).text.contains("护盾只留给后段兜底"), CASE_NAME, "wind tutorial path hint should describe shield as a late fallback instead of the default route"):
        await _finish(false)
        return
    if not TestAssert.expect_true((input_hint as Label).text.contains("高台压力"), CASE_NAME, "wind tutorial input hint should explain the local chase pressure explicitly"):
        await _finish(false)
        return
    if not TestAssert.expect_true((input_hint as Label).text.contains("先开枪做风道"), CASE_NAME, "wind tutorial input hint should stay focused on the short entry decision"):
        await _finish(false)
        return
    if not TestAssert.expect_true((route_step_01 as Label).text.contains("先开枪做 B 层风道"), CASE_NAME, "wind tutorial should mark the first route step explicitly"):
        await _finish(false)
        return
    if not TestAssert.expect_true((route_step_01 as Label).text.contains("中间预备台"), CASE_NAME, "wind tutorial should keep the prep ledge instruction inside the first route step"):
        await _finish(false)
        return
    if not TestAssert.expect_true((route_step_02 as Label).text.contains("先躲 Front Hound"), CASE_NAME, "wind tutorial should mark the foreground chase step explicitly"):
        await _finish(false)
        return
    if not TestAssert.expect_true((shield_zone_hint as Label).text.contains("护盾兜底区"), CASE_NAME, "wind tutorial should label the shield fallback zone explicitly"):
        await _finish(false)
        return
    if not TestAssert.expect_true((shield_zone_hint as Label).text.contains("炮台线太狠"), CASE_NAME, "wind tutorial should move the late shield timing into the fallback-zone label explicitly"):
        await _finish(false)
        return
    if not TestAssert.expect_true((shield_zone_hint as Label).text.contains("退路"), CASE_NAME, "wind tutorial should describe the shield fallback zone as a fallback route explicitly"):
        await _finish(false)
        return

    TestAssert.pass_case(CASE_NAME)
    await _finish(true)


func _finish(succeeded: bool) -> void:
    await TestHelpers.finish_test(self, succeeded)
