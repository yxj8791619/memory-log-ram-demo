extends Area2D

@export var target_node_paths: Array[NodePath] = []
@export var require_body_name: String = "Player_G"
@export var start_hidden_targets: bool = true
@export var turret_path: NodePath
@export var turret_fire_interval_override: float = -1.0

var is_triggered: bool = false

func _ready() -> void:
    if start_hidden_targets:
        for path in target_node_paths:
            var target := get_node_or_null(path)
            if target is CanvasItem:
                (target as CanvasItem).visible = false
    if not body_entered.is_connected(_on_body_entered):
        body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
    if is_triggered:
        return
    if body.name != require_body_name:
        return

    is_triggered = true
    for path in target_node_paths:
        var target := get_node_or_null(path)
        if target is CanvasItem:
            var canvas_item := target as CanvasItem
            canvas_item.visible = true
            canvas_item.modulate = Color(1.0, 1.0, 1.0, 1.0)

    if turret_fire_interval_override > 0.0:
        var turret := get_node_or_null(turret_path)
        if turret and turret.has_method("set_fire_interval"):
            turret.set_fire_interval(turret_fire_interval_override)
