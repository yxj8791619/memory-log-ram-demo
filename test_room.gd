extends Node2D

@onready var layer_a: TileMapLayer = $Layer_A
@onready var layer_b: TileMapLayer = $Layer_B

func _ready() -> void:
    # 确保开局只显示 A 层
    layer_a.visible = true
    layer_b.visible = false

# 接收到玩家按 TAB 切层的信号
func _on_player_g_layer_switched(is_in_b_layer: bool) -> void:
    # 瞬间切换两层的可见性
    layer_a.visible = !is_in_b_layer
    layer_b.visible = is_in_b_layer
