extends Area2D

var start_y: float = 0.0
var time_passed: float = 0.0

func _ready() -> void:
    start_y = position.y
    if not body_entered.is_connected(_on_body_entered):
        body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
    time_passed += delta * 3.0
    position.y = start_y + sin(time_passed) * 5.0


func _on_body_entered(body: Node) -> void:
    if body.name == "Player_G":
        print("获取缓存碎片！")
        queue_free()
