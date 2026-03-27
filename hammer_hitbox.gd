extends Area2D

@export var damage: int = 50       
@export var knockback_force: float = 600.0 
var hit_targets: Dictionary = {}
var swing_memory_frames: int = 0
var swing_mode: String = "basic"
var return_cut_consumed: bool = false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var player_ref: Node = get_parent().get_parent()
@onready var swing_flash: ColorRect = $SwingFlash
@onready var return_flash: ColorRect = $ReturnFlash

func _on_area_entered(area: Area2D) -> void:
    _try_hit_area(area)


func _on_body_entered(body: Node2D) -> void:
    _try_hit_body(body)


func _physics_process(delta: float) -> void:
    if collision_shape.disabled:
        if swing_memory_frames > 0:
            swing_memory_frames -= 1
        else:
            hit_targets.clear()
            return_cut_consumed = false
            if swing_flash:
                swing_flash.visible = false
            if return_flash:
                return_flash.visible = false
        return

    for area in get_overlapping_areas():
        _try_hit_area(area)
    for body in get_overlapping_bodies():
        _try_hit_body(body)
    _try_hit_nearby_targets()
    swing_memory_frames = 6


func _try_hit_area(area: Area2D) -> void:
    if area == null or area.name != "Hurtbox":
        return

    var enemy: Node = area.get_parent()
    if enemy == null:
        return

    _apply_hit_to_enemy(enemy)


func _try_hit_body(body: Node2D) -> void:
    if body == null:
        return
    if body.has_node("Hurtbox"):
        _apply_hit_to_enemy(body)


func _apply_hit_to_enemy(enemy: Node) -> void:
    if enemy == null:
        return

    var enemy_id: int = enemy.get_instance_id()
    if hit_targets.has(enemy_id):
        return
    hit_targets[enemy_id] = true

    var dir: int = signi(enemy.global_position.x - global_position.x)
    if dir == 0:
        dir = 1

    if enemy.has_method("take_damage"):
        enemy.take_damage(damage, dir, knockback_force)

    if swing_mode == "return_cut" and not return_cut_consumed and player_ref and bool(player_ref.get("is_in_layer_b")) and bool(enemy.get("is_in_layer_b")) and enemy.has_method("force_shift_to_layer_a"):
        return_cut_consumed = true
        enemy.force_shift_to_layer_a(dir)
        if player_ref.has_method("toggle_dimension"):
            player_ref.toggle_dimension("return_cut")


func _try_hit_nearby_targets() -> void:
    if player_ref == null:
        return
    for enemy in get_tree().get_nodes_in_group("kick_targets"):
        if enemy == null or not is_instance_valid(enemy):
            continue
        if not enemy.has_method("take_damage"):
            continue
        if not _is_enemy_in_hammer_range(enemy):
            continue
        _apply_hit_to_enemy(enemy)


func _is_enemy_in_hammer_range(enemy: Node2D) -> bool:
    if enemy == null:
        return false
    if player_ref and bool(player_ref.get("is_in_layer_b")) != bool(enemy.get("is_in_layer_b")):
        return false

    var local_delta: Vector2 = enemy.global_position - player_ref.global_position
    if absf(local_delta.y) > 56.0:
        return false

    var facing: int = int(player_ref.get("facing_direction"))
    if facing >= 0:
        return local_delta.x >= -16.0 and local_delta.x <= 92.0
    return local_delta.x <= 16.0 and local_delta.x >= -92.0


func perform_basic_swing() -> void:
    swing_mode = "basic"
    return_cut_consumed = false
    hit_targets.clear()
    if swing_flash:
        swing_flash.visible = true
        swing_flash.color = Color(0.55, 0.9, 1.0, 0.35)
    if return_flash:
        return_flash.visible = false
    _try_hit_nearby_targets()
    swing_memory_frames = 6


func perform_return_cut() -> void:
    swing_mode = "return_cut"
    return_cut_consumed = false
    hit_targets.clear()
    if swing_flash:
        swing_flash.visible = true
        swing_flash.color = Color(1.0, 0.86, 0.45, 0.42)
    if return_flash:
        return_flash.visible = true
    _try_hit_nearby_targets()
    swing_memory_frames = 8
