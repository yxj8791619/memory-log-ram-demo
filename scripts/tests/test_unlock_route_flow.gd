extends Node2D

const CASE_NAME := "unlock_route_flow"
const TestAssert = preload("res://scripts/tests/test_assert.gd")
const TestHelpers = preload("res://scripts/tests/test_helpers.gd")

@onready var player = $Player_G
@onready var unlock_section = $UnlockSection
@onready var wind_section = $WindSection

func _ready() -> void:
    await _run_test()


func _run_test() -> void:
    TestAssert.start(CASE_NAME)
    await TestHelpers.wait_physics_frames(self, 2)

    player.can_switch_layer = false
    player.can_use_hammer = false
    player.can_kick_to_b = false

    var trigger = unlock_section.find_child("Trigger_UnlockLayer", true, false)
    var route_hint = unlock_section.find_child("Hint_PostUnlockRoute", true, false)
    var wind_hint = wind_section.find_child("Hint_WindInput", true, false)

    if not TestAssert.expect_true(trigger != null, CASE_NAME, "unlock section should include Trigger_UnlockLayer"):
        await _finish(false)
        return
    if not TestAssert.expect_true(route_hint != null, CASE_NAME, "unlock section should include an explicit post-unlock route hint"):
        await _finish(false)
        return
    if not TestAssert.expect_true(wind_hint != null, CASE_NAME, "wind tutorial should include an entry hint for the new route"):
        await _finish(false)
        return

    trigger._on_body_entered(player)
    await TestHelpers.wait_physics_frames(self, 1)

    if not TestAssert.expect_true(player.can_switch_layer, CASE_NAME, "unlock trigger should enable layer switching"):
        await _finish(false)
        return
    if not TestAssert.expect_true(player.can_use_hammer, CASE_NAME, "unlock trigger should enable hammer usage"):
        await _finish(false)
        return
    if not TestAssert.expect_true(player.can_kick_to_b, CASE_NAME, "unlock trigger should enable kick-to-B usage"):
        await _finish(false)
        return
    if not TestAssert.expect_true(trigger.hint_label.text.contains("下一段"), CASE_NAME, "unlock trigger should tell the player what the next route objective is"):
        await _finish(false)
        return
    if not TestAssert.expect_true((route_hint as Label).text.contains("向右"), CASE_NAME, "post-unlock route hint should point the player toward the next section"):
        await _finish(false)
        return
    if not TestAssert.expect_true((wind_hint as Label).text.contains("枪"), CASE_NAME, "wind tutorial entry hint should mention the gun-to-wind route"):
        await _finish(false)
        return

    TestAssert.pass_case(CASE_NAME)
    await _finish(true)


func _finish(succeeded: bool) -> void:
    await TestHelpers.finish_test(self, succeeded)
