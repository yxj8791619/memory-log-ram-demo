extends Node2D

const CASE_NAME := "mixed_arena_flow"
const TestAssert = preload("res://scripts/tests/test_assert.gd")
const TestHelpers = preload("res://scripts/tests/test_helpers.gd")

@onready var arena_section = $Section06
@onready var arena_trigger = $Section06/Encounters/Arena_Wave_01

func _ready() -> void:
    await _run_test()


func _run_test() -> void:
    TestAssert.start(CASE_NAME)
    await TestHelpers.wait_physics_frames(self, 2)

    var waves_root: Node = arena_trigger.get_node("Waves")
    if not TestAssert.expect_equal(waves_root.get_child_count(), 2, CASE_NAME, "mixed arena should define two combat waves"):
        await _finish(false)
        return

    arena_trigger.start_arena_for_test()
    await TestHelpers.wait_physics_frames(self, 2)

    if not TestAssert.expect_equal(arena_trigger.current_wave_index, 0, CASE_NAME, "arena should start at wave 1"):
        await _finish(false)
        return
    if not TestAssert.expect_equal(arena_trigger.enemies_alive, 2, CASE_NAME, "wave 1 should spawn two enemies"):
        await _finish(false)
        return

    arena_trigger._on_enemy_died()
    arena_trigger._on_enemy_died()
    await TestHelpers.wait_physics_frames(self, 2)

    if not TestAssert.expect_equal(arena_trigger.current_wave_index, 1, CASE_NAME, "clearing wave 1 should advance to wave 2"):
        await _finish(false)
        return
    if not TestAssert.expect_equal(arena_trigger.enemies_alive, 2, CASE_NAME, "wave 2 should spawn two enemies"):
        await _finish(false)
        return

    arena_trigger._on_enemy_died()
    arena_trigger._on_enemy_died()
    await TestHelpers.wait_physics_frames(self, 2)

    if not TestAssert.expect_equal(arena_trigger.enemies_alive, 0, CASE_NAME, "all arena enemies should be cleared after wave 2"):
        await _finish(false)
        return
    if not TestAssert.expect_true(arena_trigger.left_door_shape.disabled, CASE_NAME, "left door should reopen after mixed arena clear"):
        await _finish(false)
        return
    if not TestAssert.expect_true(arena_trigger.right_door_shape.disabled, CASE_NAME, "right door should reopen after mixed arena clear"):
        await _finish(false)
        return

    var front_hound_templates: int = waves_root.find_children("Spawn_*FrontHound*", "", true, false).size()
    var page_lock_templates: int = waves_root.find_children("Spawn_*PageLockGuard*", "", true, false).size()
    var support_templates: int = waves_root.find_children("Spawn_*BackgroundTurret*", "", true, false).size()
    var mixed_hint = arena_section.find_child("Hint_MixedArena", true, false)
    var composition_hint = arena_section.find_child("Hint_Composition", true, false)

    if not TestAssert.expect_true(front_hound_templates >= 1, CASE_NAME, "mixed arena should include an A-layer advantage enemy"):
        await _finish(false)
        return
    if not TestAssert.expect_true(page_lock_templates >= 1, CASE_NAME, "mixed arena should include a B-layer advantage enemy"):
        await _finish(false)
        return
    if not TestAssert.expect_true(support_templates >= 1, CASE_NAME, "mixed arena should include a support enemy"):
        await _finish(false)
        return
    if not TestAssert.expect_true(mixed_hint != null, CASE_NAME, "mixed arena should include Hint_MixedArena"):
        await _finish(false)
        return
    if not TestAssert.expect_true(composition_hint != null, CASE_NAME, "mixed arena should include Hint_Composition"):
        await _finish(false)
        return
    if not TestAssert.expect_true((mixed_hint as Label).text.contains("重击 + 切层键"), CASE_NAME, "mixed arena hint should point players toward group return usage"):
        await _finish(false)
        return
    if not TestAssert.expect_true((composition_hint as Label).text.contains("重击单按留在 B 层"), CASE_NAME, "composition hint should explain that heavy attack alone does not switch layers"):
        await _finish(false)
        return

    TestAssert.pass_case(CASE_NAME)
    await _finish(true)


func _finish(succeeded: bool) -> void:
    await TestHelpers.finish_test(self, succeeded)
