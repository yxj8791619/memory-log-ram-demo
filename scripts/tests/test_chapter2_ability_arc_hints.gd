extends Node2D

const CASE_NAME := "chapter2_ability_arc_hints"
const TestAssert = preload("res://scripts/tests/test_assert.gd")
const TestHelpers = preload("res://scripts/tests/test_helpers.gd")

@onready var unlock_section = $UnlockSection
@onready var wind_section = $WindSection
@onready var return_section = $ReturnSection
@onready var mixed_section = $MixedSection

func _ready() -> void:
    await _run_test()


func _run_test() -> void:
    TestAssert.start(CASE_NAME)
    await TestHelpers.wait_physics_frames(self, 2)

    var unlock_trigger = unlock_section.find_child("Trigger_UnlockLayer", true, false)
    var wind_hint = wind_section.find_child("Hint_ControlShield", true, false)
    var return_hint = return_section.find_child("Hint_SplitDecision", true, false)
    var mixed_hint = mixed_section.find_child("Hint_Composition", true, false)

    if not TestAssert.expect_true(unlock_trigger != null, CASE_NAME, "ability arc should include the unlock trigger section"):
        await _finish(false)
        return
    if not TestAssert.expect_true(wind_hint != null, CASE_NAME, "ability arc should include the wind tutorial shield hint"):
        await _finish(false)
        return
    if not TestAssert.expect_true(return_hint != null, CASE_NAME, "ability arc should include the return combo split hint"):
        await _finish(false)
        return
    if not TestAssert.expect_true(mixed_hint != null, CASE_NAME, "ability arc should include the mixed arena composition hint"):
        await _finish(false)
        return

    if not TestAssert.expect_true((unlock_trigger as Area2D).get("unlocked_text").contains("枪转风道"), CASE_NAME, "unlock section should keep the immediate next lesson focused on gun-to-wind"):
        await _finish(false)
        return
    if not TestAssert.expect_true((unlock_trigger as Area2D).get("unlocked_text").contains("后续段落"), CASE_NAME, "unlock section should defer later layer-derived skills to later sections explicitly"):
        await _finish(false)
        return
    if not TestAssert.expect_true((wind_hint as Label).text.contains("控制技 + 切层键"), CASE_NAME, "wind tutorial should mention the shield input explicitly"):
        await _finish(false)
        return
    if not TestAssert.expect_true((return_hint as Label).text.contains("群体切回"), CASE_NAME, "return combo tutorial should foreshadow the next-step group return lesson"):
        await _finish(false)
        return
    if not TestAssert.expect_true((mixed_hint as Label).text.contains("炸弹 + 切层键"), CASE_NAME, "mixed arena should mention bomb mutation as part of the later combo layer"):
        await _finish(false)
        return

    TestAssert.pass_case(CASE_NAME)
    await _finish(true)


func _finish(succeeded: bool) -> void:
    await TestHelpers.finish_test(self, succeeded)
