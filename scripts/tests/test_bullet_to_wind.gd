extends Node2D

const CASE_NAME := "bullet_to_wind"
const TestAssert = preload("res://scripts/tests/test_assert.gd")
const TestHelpers = preload("res://scripts/tests/test_helpers.gd")

@onready var player = $Player_G

func _ready() -> void:
    await _run_test()


func _run_test() -> void:
    TestAssert.start(CASE_NAME)

    var bullet_scene: PackedScene = load("res://bullet.tscn")
    if bullet_scene == null:
        TestAssert.blocked_case(CASE_NAME, "bullet scene missing")
        await _finish(false)
        return

    var bullet = bullet_scene.instantiate()
    add_child(bullet)
    bullet.global_position = player.global_position + Vector2(32, 0)
    bullet.direction = 1.0

    await TestHelpers.wait_physics_frames(self, 2)

    bullet.on_dimension_switched(true)
    await TestHelpers.wait_physics_frames(self, 4)

    if not TestAssert.expect_true(bullet.is_wind_path, CASE_NAME, "bullet should convert into wind path after layer switch"):
        await _finish(false)
        return
    if not TestAssert.expect_equal(bullet.damage, 0, CASE_NAME, "wind path should stop dealing bullet damage"):
        await _finish(false)
        return
    if not TestAssert.expect_true(bullet.collision_shape.shape is RectangleShape2D, CASE_NAME, "wind path collision should become a rectangle"):
        await _finish(false)
        return
    if not TestAssert.expect_true(bullet.wind_current_length > 12.0, CASE_NAME, "wind path should expand after conversion"):
        await _finish(false)
        return

    bullet._on_body_entered(player)
    await TestHelpers.wait_physics_frames(self, 1)

    if not TestAssert.expect_true(player.is_wind_buffed, CASE_NAME, "player should gain wind buff after entering wind path"):
        await _finish(false)
        return
    if not TestAssert.expect_true(player.wind_speed_multiplier > 1.0, CASE_NAME, "wind buff should increase player speed multiplier"):
        await _finish(false)
        return

    bullet._on_body_exited(player)
    await TestHelpers.wait_physics_frames(self, 1)

    if not TestAssert.expect_true(not player.is_wind_buffed, CASE_NAME, "player should leave direct wind state after exiting wind path"):
        await _finish(false)
        return
    if not TestAssert.expect_true(player.wind_buff_active, CASE_NAME, "wind buff should remain in decay state after exit"):
        await _finish(false)
        return

    TestAssert.pass_case(CASE_NAME)
    await _finish(true)


func _finish(succeeded: bool) -> void:
    await TestHelpers.finish_test(self, succeeded)
