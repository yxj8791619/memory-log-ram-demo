extends Node2D

@export var enemy_scene: PackedScene

var is_triggered: bool = false
var enemies_alive: int = 0
var current_wave_index: int = -1

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

	start_arena_for_test()


func start_arena_for_test() -> void:
	if is_triggered:
		return
	is_triggered = true
	_set_doors_enabled(true)
	if _has_custom_waves():
		current_wave_index = -1
		_spawn_next_wave()
	else:
		_spawn_default_wave()


func _spawn_default_wave() -> void:
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
		if _has_custom_waves() and current_wave_index + 1 < _get_wave_count():
			_spawn_next_wave()
			return
		_set_doors_enabled(false)
		print("竞技场清理完毕！")


func _set_doors_enabled(enabled: bool) -> void:
	left_door_visual.visible = enabled
	right_door_visual.visible = enabled
	left_door_shape.disabled = not enabled
	right_door_shape.disabled = not enabled


func _has_custom_waves() -> bool:
	return _get_wave_count() > 0


func _get_wave_count() -> int:
	var waves_root: Node = get_node_or_null("Waves")
	if waves_root == null:
		return 0
	return waves_root.get_child_count()


func _spawn_next_wave() -> void:
	current_wave_index += 1
	var waves_root: Node = get_node_or_null("Waves")
	if waves_root == null or current_wave_index >= waves_root.get_child_count():
		_set_doors_enabled(false)
		return

	var wave_node: Node = waves_root.get_child(current_wave_index)
	var spawned_count: int = 0
	for point in wave_node.get_children():
		if not point.has_method("get"):
			continue
		var scene: PackedScene = point.get("enemy_scene")
		if scene == null:
			continue
		var enemy: Node = scene.instantiate()
		get_tree().current_scene.add_child(enemy)
		if enemy is Node2D and point is Node2D:
			enemy.global_position = (point as Node2D).global_position
		if not enemy.tree_exited.is_connected(_on_enemy_died):
			enemy.tree_exited.connect(_on_enemy_died)
		spawned_count += 1

	enemies_alive = spawned_count
	if enemies_alive <= 0:
		if current_wave_index + 1 < _get_wave_count():
			_spawn_next_wave()
		else:
			_set_doors_enabled(false)
