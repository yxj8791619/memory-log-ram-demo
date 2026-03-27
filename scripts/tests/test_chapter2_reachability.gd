extends Node2D

const CASE_NAME := "chapter2_reachability"
const TestAssert = preload("res://scripts/tests/test_assert.gd")
const TestHelpers = preload("res://scripts/tests/test_helpers.gd")

const HORIZONTAL_MARGIN := 8.0
const VERTICAL_MARGIN := 8.0

@onready var player = $Player_G
@onready var section02 = $Section02
@onready var section03 = $Section03
@onready var section04 = $Section04
@onready var section05 = $Section05

func _ready() -> void:
    await _run_test()


func _run_test() -> void:
    TestAssert.start(CASE_NAME)
    await TestHelpers.wait_physics_frames(self, 2)

    var max_jump_height: float = float(player.get("a_jump_height")) + VERTICAL_MARGIN
    var max_horizontal_reach: float = float(player.get("a_run_speed")) * (
        float(player.get("a_time_to_peak")) + float(player.get("a_time_to_descent"))
    ) + HORIZONTAL_MARGIN

    TestAssert.info("A-layer reach metrics: jump=%.1f, horizontal=%.1f" % [max_jump_height, max_horizontal_reach])

    var checks: Array[Dictionary] = [
        {
            "label": "Section02 ground -> mid platform",
            "from": section02.get_node("Terrain/Ground_A"),
            "to": section02.get_node("Terrain/MidPlatform_A"),
            "vertical_only": true
        },
        {
            "label": "Section03 ground -> left perch",
            "from": section03.get_node("Terrain/Ground_A"),
            "to": section03.get_node("Terrain/LeftPerch_A"),
            "vertical_only": true
        },
        {
            "label": "Section03 ground -> right perch",
            "from": section03.get_node("Terrain/Ground_A"),
            "to": section03.get_node("Terrain/RightPerch_A"),
            "vertical_only": true
        },
        {
            "label": "Section04 ground -> high ledge",
            "from": section04.get_node("Terrain/Ground_A"),
            "to": section04.get_node("Terrain/HighLedge_A"),
            "vertical_only": true
        },
        {
            "label": "Section04 high ledge -> chase ledge",
            "from": section04.get_node("Terrain/HighLedge_A"),
            "to": section04.get_node("Terrain/ChaseLedge_A")
        },
        {
            "label": "Section05 ground -> mid platform",
            "from": section05.get_node("Terrain/Ground_A"),
            "to": section05.get_node("Terrain/MidPlatform_A"),
            "vertical_only": true
        },
        {
            "label": "Section05 mid platform -> right platform",
            "from": section05.get_node("Terrain/MidPlatform_A"),
            "to": section05.get_node("Terrain/RightPlatform_A")
        }
    ]

    for check in checks:
        var metrics := _measure_reachability(check["from"], check["to"])
        var label: String = String(check["label"])
        var vertical_ok: bool = metrics.vertical_rise <= max_jump_height
        if not TestAssert.expect_true(vertical_ok, CASE_NAME, "%s exceeds jump height (rise=%.1f, max=%.1f)" % [label, metrics.vertical_rise, max_jump_height]):
            await _finish(false)
            return

        var vertical_only: bool = bool(check.get("vertical_only", false))
        if not vertical_only:
            var horizontal_ok: bool = metrics.horizontal_gap <= max_horizontal_reach
            if not TestAssert.expect_true(horizontal_ok, CASE_NAME, "%s exceeds horizontal reach (gap=%.1f, max=%.1f)" % [label, metrics.horizontal_gap, max_horizontal_reach]):
                await _finish(false)
                return

    TestAssert.pass_case(CASE_NAME)
    await _finish(true)


func _measure_reachability(from_body: StaticBody2D, to_body: StaticBody2D) -> Dictionary:
    var from_rect: Rect2 = _get_surface_rect(from_body)
    var to_rect: Rect2 = _get_surface_rect(to_body)
    var horizontal_gap: float = 0.0
    if from_rect.end.x < to_rect.position.x:
        horizontal_gap = to_rect.position.x - from_rect.end.x
    elif to_rect.end.x < from_rect.position.x:
        horizontal_gap = from_rect.position.x - to_rect.end.x

    var vertical_rise: float = max(0.0, from_rect.position.y - to_rect.position.y)
    return {
        "horizontal_gap": horizontal_gap,
        "vertical_rise": vertical_rise
    }


func _get_surface_rect(body: StaticBody2D) -> Rect2:
    var shape_node: CollisionShape2D = body.get_node("CollisionShape2D")
    var shape: RectangleShape2D = shape_node.shape as RectangleShape2D
    var size: Vector2 = shape.size
    var center: Vector2 = body.global_position + shape_node.position
    return Rect2(center - (size * 0.5), size)


func _finish(succeeded: bool) -> void:
    await TestHelpers.finish_test(self, succeeded)
