extends Node2D

const CASE_NAME := "mixed_arena_combo_regression"
const TestAssert = preload("res://scripts/tests/test_assert.gd")
const TestHelpers = preload("res://scripts/tests/test_helpers.gd")

@onready var chapter = $Chapter2Main

func _ready() -> void:
    await _run_test()


func _run_test() -> void:
    TestAssert.start(CASE_NAME)
    await TestHelpers.wait_physics_frames(self, 3)

    var player = chapter.find_child("Player_G", true, false)
    var mixed_section = chapter.find_child("Section_06_FirstMixedArena", true, false)
    var arena_trigger = mixed_section.find_child("Arena_Wave_01", true, false) if mixed_section else null

    if not TestAssert.expect_true(player != null, CASE_NAME, "chapter2 combo regression should include Player_G"):
        await _finish(false)
        return
    if not TestAssert.expect_true(mixed_section != null, CASE_NAME, "chapter2 combo regression should include the mixed arena section"):
        await _finish(false)
        return
    if not TestAssert.expect_true(arena_trigger != null, CASE_NAME, "mixed arena section should still include Arena_Wave_01"):
        await _finish(false)
        return

    var mixed_hint = mixed_section.find_child("Hint_MixedArena", true, false)
    var composition_hint = mixed_section.find_child("Hint_Composition", true, false)
    var waves_root = arena_trigger.get_node("Waves")

    if not TestAssert.expect_true(mixed_hint != null and (mixed_hint as Label).text.contains("重击 + 切层键"), CASE_NAME, "mixed arena should preserve the group-return teaching hint"):
        await _finish(false)
        return
    if not TestAssert.expect_true(composition_hint != null and (composition_hint as Label).text.contains("后台炮台"), CASE_NAME, "mixed arena should explain the new support enemy pressure"):
        await _finish(false)
        return
    if not TestAssert.expect_true(waves_root.find_children("Spawn_*BackgroundTurret*", "", true, false).size() >= 1, CASE_NAME, "mixed arena should still include Background Turret in wave 2"):
        await _finish(false)
        return

    if not TestAssert.expect_true(player.has_method("perform_control_shield_shift"), CASE_NAME, "chapter2 player should include the control shield prototype entry point"):
        await _finish(false)
        return
    if not TestAssert.expect_true(player.has_method("perform_bomb_mutation_shift"), CASE_NAME, "chapter2 player should include the bomb mutation prototype entry point"):
        await _finish(false)
        return
    if not TestAssert.expect_true(player.has_method("perform_group_return"), CASE_NAME, "chapter2 player should still include the group return prototype entry point"):
        await _finish(false)
        return
    if not TestAssert.expect_true(player.has_node("ControlShieldRing"), CASE_NAME, "chapter2 player should keep the control shield visual indicator"):
        await _finish(false)
        return
    if not TestAssert.expect_true(player.has_node("BombMutationField"), CASE_NAME, "chapter2 player should keep the bomb mutation field indicator"):
        await _finish(false)
        return

    TestAssert.pass_case(CASE_NAME)
    await _finish(true)


func _finish(succeeded: bool) -> void:
    await TestHelpers.finish_test(self, succeeded)
