extends Node2D

@export var enemy_scene: PackedScene

var is_triggered: bool = false
var enemies_alive: int = 0

@onready var trigger_area: Area2D = $TriggerArea
@onready var left_door: StaticBody2D = $LeftDoor
@onready var right_door: StaticBody2D = $RightDoor
@onready var left_door_visual: ColorRect = $LeftDoor/ColorRect
@onready var right_door_visual: ColorRect = $RightDoor/ColorRect
@onready var left_door_shape: CollisionShape2D = $LeftDoor/CollisionShape2D
@onready var right_door_shape: CollisionShape2D = $RightDoor/CollisionShape2D
@onready var spawn_points: Node2D = $SpawnPoints

func _ready() -> void:
    _set_doors_enabled(false)
    if not trigger_area.body_entered.is_connected(_on_trigger_area_body_entered):
        trigger_area.body_entered.connect(_on_trigger_area_body_entered)


func _on_trigger_area_body_entered(body: Node) -> void:
    if is_triggered:
        return
    if body.name != "Player_G":
        return

    is_triggered = true
    _set_doors_enabled(true)
    _spawn_enemies()


func _spawn_enemies() -> void:
    if enemy_scene == null:
        print("ArenaTrigger: enemy_scene 未配置。")
        return

    var spawned_count: int = 0
    for point in spawn_points.get_children():
        if point is Marker2D:
            var enemy: Node = enemy_scene.instantiate()
            get_tree().current_scene.add_child(enemy)
            if enemy is Node2D:
                enemy.global_position = (point as Marker2D).global_position
            if not enemy.tree_exited.is_connected(_on_enemy_died):
                enemy.tree_exited.connect(_on_enemy_died)
            spawned_count += 1

    enemies_alive = spawned_count
    if enemies_alive <= 0:
        _set_doors_enabled(false)


func _on_enemy_died() -> void:
    enemies_alive -= 1
    if enemies_alive <= 0:
        _set_doors_enabled(false)
        print("竞技场清理完毕！")


func _set_doors_enabled(enabled: bool) -> void:
    left_door_visual.visible = enabled
    right_door_visual.visible = enabled
    left_door_shape.disabled = not enabled
    right_door_shape.disabled = not enabled
