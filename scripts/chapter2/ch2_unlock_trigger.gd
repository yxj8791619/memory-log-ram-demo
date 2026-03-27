extends Area2D

@export var unlock_layer_switch: bool = true
@export var unlock_hammer: bool = true
@export var unlock_kick_to_b: bool = true
@export var hint_text: String = "C.O.R.E. 已授权切层与重锤。"
@export var unlocked_text: String = "权限已解锁：切层 / 踢怪 / B 层重锤"
@export var next_step_text: String = "下一段：继续向右，用枪把子弹送进 B 层风道，跨过高差追击路线。"

var is_triggered: bool = false

@onready var hint_label: Label = $HintLabel

func _ready() -> void:
    hint_label.text = hint_text
    hint_label.visible = true
    hint_label.modulate = Color(0.84, 0.95, 1.0, 1.0)
    if not body_entered.is_connected(_on_body_entered):
        body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
    if is_triggered:
        return
    if body.name != "Player_G":
        return

    is_triggered = true
    if unlock_layer_switch and "can_switch_layer" in body:
        body.can_switch_layer = true
    if unlock_hammer and "can_use_hammer" in body:
        body.can_use_hammer = true
    if unlock_kick_to_b and "can_kick_to_b" in body:
        body.can_kick_to_b = true

    hint_label.text = "%s\n%s" % [unlocked_text, next_step_text]
    hint_label.modulate = Color(1.0, 0.94, 0.62, 1.0)
    print("Chapter2: ability unlock triggered.")
