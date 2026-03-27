extends Node2D

const CASE_NAME := "background_turret_profile"
const TestAssert = preload("res://scripts/tests/test_assert.gd")
const TestHelpers = preload("res://scripts/tests/test_helpers.gd")

@onready var player = $Player_G
@onready var turret = $BackgroundTurret

func _ready() -> void:
    await _run_test()


func _run_test() -> void:
    TestAssert.start(CASE_NAME)
    await TestHelpers.wait_physics_frames(self, 2)

    player.global_position = Vector2(220, 480)
    turret.global_position = Vector2(340, 460)

    turret._on_screen_entered()
    await TestHelpers.wait_physics_frames(self, 2)

    if not TestAssert.expect_true(turret.is_in_layer_b, CASE_NAME, "background turret should default to layer B"):
        await _finish(false)
        return

    var health_before: int = player.current_health
    turret._on_fire_timer_timeout()
    await TestHelpers.wait_physics_frames(self, 12)

    if not TestAssert.expect_true(player.current_health < health_before, CASE_NAME, "background turret should pressure the player while the player remains in layer A"):
        await _finish(false)
        return
    if not TestAssert.expect_true(not turret.hurtbox.monitorable, CASE_NAME, "background turret hurtbox should not be directly interactable from layer A"):
        await _finish(false)
        return

    player.toggle_dimension()
    await TestHelpers.wait_physics_frames(self, 2)

    if not TestAssert.expect_true(turret.hurtbox.monitorable, CASE_NAME, "background turret should become directly interactable after the player enters layer B"):
        await _finish(false)
        return

    TestAssert.pass_case(CASE_NAME)
    await _finish(true)


func _finish(succeeded: bool) -> void:
    await TestHelpers.finish_test(self, succeeded)
