extends Node2D

const CASE_NAME := "bomb_mutation_mixed_hint"
const TestAssert = preload("res://scripts/tests/test_assert.gd")
const TestHelpers = preload("res://scripts/tests/test_helpers.gd")

@onready var section = $MixedArenaSection

func _ready() -> void:
    await _run_test()


func _run_test() -> void:
    TestAssert.start(CASE_NAME)
    await TestHelpers.wait_physics_frames(self, 2)

    var composition_hint = section.find_child("Hint_Composition", true, false)
    if not TestAssert.expect_true(composition_hint != null, CASE_NAME, "mixed arena should include Hint_Composition for bomb mutation guidance"):
        await _finish(false)
        return

    var text: String = (composition_hint as Label).text
    if not TestAssert.expect_true(text.contains("炸弹 + 切层键"), CASE_NAME, "mixed arena should explicitly mention the bomb mutation input"):
        await _finish(false)
        return
    if not TestAssert.expect_true(text.contains("异化爆发"), CASE_NAME, "mixed arena should explicitly mention the mutation result"):
        await _finish(false)
        return

    TestAssert.pass_case(CASE_NAME)
    await _finish(true)


func _finish(succeeded: bool) -> void:
    await TestHelpers.finish_test(self, succeeded)
