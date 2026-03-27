extends Node2D

const CASE_NAME := "return_combo_tutorial"
const TestAssert = preload("res://scripts/tests/test_assert.gd")
const TestHelpers = preload("res://scripts/tests/test_helpers.gd")

@onready var section = $ReturnComboSection

func _ready() -> void:
    await _run_test()


func _run_test() -> void:
    TestAssert.start(CASE_NAME)
    await TestHelpers.wait_physics_frames(self, 2)

    var combo_hint = section.find_child("Hint_ReturnCombo", true, false)
    var split_hint = section.find_child("Hint_SplitDecision", true, false)

    if not TestAssert.expect_true(combo_hint != null, CASE_NAME, "return combo tutorial should include Hint_ReturnCombo"):
        await _finish(false)
        return
    if not TestAssert.expect_true(split_hint != null, CASE_NAME, "return combo tutorial should include Hint_SplitDecision"):
        await _finish(false)
        return

    var combo_text: String = (combo_hint as Label).text
    var split_text: String = (split_hint as Label).text

    if not TestAssert.expect_true(combo_text.contains("普通锤击留在 B 层"), CASE_NAME, "return combo hint should explicitly explain that basic hammer stays in B"):
        await _finish(false)
        return
    if not TestAssert.expect_true(combo_text.contains("TAB / 右键只切自己"), CASE_NAME, "return combo hint should explicitly explain plain layer switch behavior"):
        await _finish(false)
        return
    if not TestAssert.expect_true(combo_text.contains("锤攻击 + 切层键"), CASE_NAME, "return combo hint should explicitly name the return-cut input"):
        await _finish(false)
        return
    if not TestAssert.expect_true(combo_text.contains("带回 A 层"), CASE_NAME, "return combo hint should explain the carry-back result"):
        await _finish(false)
        return
    if not TestAssert.expect_true(split_text.contains("稳杀"), CASE_NAME, "split decision hint should preserve the stay-in-B kill framing"):
        await _finish(false)
        return
    if not TestAssert.expect_true(split_text.contains("收尾"), CASE_NAME, "split decision hint should preserve the return-to-A finisher framing"):
        await _finish(false)
        return

    TestAssert.pass_case(CASE_NAME)
    await _finish(true)


func _finish(succeeded: bool) -> void:
    await TestHelpers.finish_test(self, succeeded)
