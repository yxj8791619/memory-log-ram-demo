extends Node2D

const CASE_NAME := "layer_switch_basic"
const TestAssert = preload("res://scripts/tests/test_assert.gd")
const TestHelpers = preload("res://scripts/tests/test_helpers.gd")

@onready var player = $Player_G
@onready var layer_a: Node2D = $Layer_A
@onready var layer_b: Node2D = $Layer_B
@onready var enemy = $Enemy_Dummy

func _ready() -> void:
    await _run_test()


func _run_test() -> void:
    TestAssert.start(CASE_NAME)
    player.layer_switched.connect(_on_player_layer_switched)
    _on_player_layer_switched(player.is_in_layer_b)

    await TestHelpers.wait_physics_frames(self, 2)

    enemy.is_active = false
    enemy.attack_box.monitoring = false

    if not TestAssert.expect_true(not player.is_in_layer_b, CASE_NAME, "player should start in layer A"):
        await _finish(false)
        return
    if not TestAssert.expect_true(not enemy.is_in_layer_b, CASE_NAME, "enemy should start in layer A for switch-is-player-only validation"):
        await _finish(false)
        return
    if not TestAssert.expect_true(layer_a.visible and not layer_b.visible, CASE_NAME, "layer visibility should start on A"):
        await _finish(false)
        return
    if not TestAssert.expect_true(player.get_collision_mask_value(2), CASE_NAME, "player should collide with World_A before switch"):
        await _finish(false)
        return
    if not TestAssert.expect_true(not player.get_collision_mask_value(3), CASE_NAME, "player should not collide with World_B before switch"):
        await _finish(false)
        return

    player.toggle_dimension()
    await TestHelpers.wait_physics_frames(self, 2)

    if not TestAssert.expect_true(player.is_in_layer_b, CASE_NAME, "toggle_dimension should move player into layer B"):
        await _finish(false)
        return
    if not TestAssert.expect_true(not layer_a.visible and layer_b.visible, CASE_NAME, "layer visibility should switch to B"):
        await _finish(false)
        return
    if not TestAssert.expect_true(not player.get_collision_mask_value(2), CASE_NAME, "player should stop colliding with World_A in layer B"):
        await _finish(false)
        return
    if not TestAssert.expect_true(player.get_collision_mask_value(3), CASE_NAME, "player should collide with World_B in layer B"):
        await _finish(false)
        return
    if not TestAssert.expect_true(not enemy.is_in_layer_b, CASE_NAME, "player-only switch should not move enemies between layers"):
        await _finish(false)
        return

    TestAssert.pass_case(CASE_NAME)
    await _finish(true)


func _on_player_layer_switched(is_in_b_layer: bool) -> void:
    layer_a.visible = not is_in_b_layer
    layer_b.visible = is_in_b_layer


func _finish(succeeded: bool) -> void:
    await TestHelpers.finish_test(self, succeeded)
