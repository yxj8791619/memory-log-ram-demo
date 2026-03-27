extends Node2D

const CASE_NAME := "chapter2_first10_smoke"
const TestAssert = preload("res://scripts/tests/test_assert.gd")
const TestHelpers = preload("res://scripts/tests/test_helpers.gd")

@onready var chapter = $Chapter2Main

func _ready() -> void:
    await _run_test()


func _run_test() -> void:
    TestAssert.start(CASE_NAME)
    await TestHelpers.wait_physics_frames(self, 3)

    var player: Node = chapter.find_child("Player_G", true, false)
    var sections_root: Node = chapter.find_child("Sections", true, false)
    var unlock_trigger: Node = chapter.find_child("Trigger_UnlockLayer", true, false)

    if not TestAssert.expect_true(player != null, CASE_NAME, "chapter2 main scene should include Player_G"):
        await _finish(false)
        return
    if not TestAssert.expect_true(sections_root != null, CASE_NAME, "chapter2 main scene should include Sections root"):
        await _finish(false)
        return
    if not TestAssert.expect_true(sections_root.get_child_count() >= 6, CASE_NAME, "chapter2 should include at least 6 section pack units"):
        await _finish(false)
        return
    if not TestAssert.expect_true(unlock_trigger != null, CASE_NAME, "chapter2 route should include unlock trigger"):
        await _finish(false)
        return

    var expected_sections: Array[String] = [
        "Section_01_RunIntro",
        "Section_02_WrongLayerRoom",
        "Section_03_UnlockArena",
        "Section_04_WindTutorial",
        "Section_05_ReturnComboTutorial",
        "Section_06_FirstMixedArena"
    ]
    for section_name in expected_sections:
        var node: Node = sections_root.find_child(section_name, false, false)
        if not TestAssert.expect_true(node != null, CASE_NAME, "missing section %s" % section_name):
            await _finish(false)
            return

    TestAssert.pass_case(CASE_NAME)
    await _finish(true)


func _finish(succeeded: bool) -> void:
    await TestHelpers.finish_test(self, succeeded)
