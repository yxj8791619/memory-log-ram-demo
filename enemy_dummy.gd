extends CharacterBody2D

enum AIState {
    PATROL,
    CHASE
}

var gravity: float = 980.0
var health: int = 100
@export var is_in_layer_b: bool = false
@export var layer_shift_upward_force: float = 220.0
@export var layer_shift_horizontal_force: float = 180.0
var speed: float = 100.0
var chase_speed: float = 150.0
var acceleration: float = 900.0
var facing_direction: int = 1
var attack_damage: int = 20
var vision_distance: float = 400.0
var vision_height_tolerance: float = 40.0
@export var chase_memory_duration: float = 0.75
@export var chase_memory_horizontal_mult: float = 1.35
@export var chase_memory_max_y_delta: float = 220.0
var chase_memory_left: float = 0.0
var patrol_range: float = 90.0
var ledge_probe_forward: float = 15.0
var ledge_probe_depth: float = 20.0
var is_active: bool = false
var state: int = AIState.PATROL
var patrol_center_x: float = 0.0
var player_ref: Node = null
var alert_timer: Timer

@onready var attack_box: Area2D = $AttackBox
@onready var hurtbox: Area2D = $Hurtbox
@onready var screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@onready var vision_ray: RayCast2D = $VisionRay
@onready var ledge_check: RayCast2D = $LedgeCheck
@onready var alert_mark: Label = $AlertMark
@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
    add_to_group("kick_targets")
    if not attack_box.body_entered.is_connected(_on_attack_box_body_entered):
        attack_box.body_entered.connect(_on_attack_box_body_entered)
    if not screen_notifier.screen_entered.is_connected(_on_screen_entered):
        screen_notifier.screen_entered.connect(_on_screen_entered)
    if not screen_notifier.screen_exited.is_connected(_on_screen_exited):
        screen_notifier.screen_exited.connect(_on_screen_exited)

    alert_timer = Timer.new()
    alert_timer.one_shot = true
    alert_timer.wait_time = 0.45
    add_child(alert_timer)
    if not alert_timer.timeout.is_connected(_on_alert_timer_timeout):
        alert_timer.timeout.connect(_on_alert_timer_timeout)

    patrol_center_x = global_position.x
    alert_mark.visible = false
    _configure_rays()
    _update_facing_setup()
    _refresh_player_ref()
    _apply_layer_visual_state()


func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y += gravity * delta

    _refresh_player_ref()
    _refresh_layer_interaction_state()

    if not is_active:
        chase_memory_left = 0.0
        _set_patrol_state()
        _apply_horizontal_velocity(0.0, delta)
        move_and_slide()
        return

    if not _is_on_same_layer_as_player():
        chase_memory_left = 0.0
        _set_patrol_state()
    elif _is_player_in_layer_b():
        chase_memory_left = 0.0
        _set_patrol_state()
    elif _can_see_player():
        chase_memory_left = chase_memory_duration
        _set_chase_state()
    elif state == AIState.CHASE and chase_memory_left > 0.0:
        chase_memory_left -= delta
        if chase_memory_left > 0.0 and _is_chase_memory_valid():
            _set_chase_state()
        else:
            chase_memory_left = 0.0
            _set_patrol_state()
    else:
        chase_memory_left = 0.0
        _set_patrol_state()

    var target_speed: float = 0.0
    if state == AIState.PATROL:
        var left_limit: float = patrol_center_x - patrol_range
        var right_limit: float = patrol_center_x + patrol_range
        var reach_patrol_edge: bool = (global_position.x <= left_limit and facing_direction < 0) or (global_position.x >= right_limit and facing_direction > 0)
        var blocked_patrol: bool = _is_blocked_ahead() or reach_patrol_edge
        if blocked_patrol:
            facing_direction *= -1
            _update_facing_setup()
        target_speed = speed * facing_direction
    else:
        _face_player_horizontally()
        if _is_blocked_ahead():
            target_speed = 0.0
        else:
            target_speed = chase_speed * facing_direction

    _apply_horizontal_velocity(target_speed, delta)
    move_and_slide()


func _on_attack_box_body_entered(body: Node) -> void:
    if body.has_method("take_damage"):
        body.take_damage(attack_damage)


func _configure_rays() -> void:
    vision_ray.enabled = true
    vision_ray.set_collision_mask_value(1, true)
    vision_ray.set_collision_mask_value(2, true)
    vision_ray.set_collision_mask_value(3, true)

    ledge_check.enabled = true
    ledge_check.set_collision_mask_value(2, true)
    ledge_check.set_collision_mask_value(3, false)
    ledge_check.target_position = Vector2(ledge_probe_forward * facing_direction, ledge_probe_depth)


func _update_facing_setup() -> void:
    vision_ray.target_position.x = vision_distance * facing_direction
    ledge_check.position.x = _get_body_half_width() * facing_direction
    ledge_check.target_position.x = ledge_probe_forward * facing_direction
    $Sprite2D.flip_h = (facing_direction == -1)


func _is_blocked_ahead() -> bool:
    ledge_check.force_raycast_update()
    var is_at_ledge: bool = not ledge_check.is_colliding()
    var hit_wall: bool = is_on_wall()
    return is_at_ledge or hit_wall


func _apply_horizontal_velocity(target_speed: float, delta: float) -> void:
    velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)


func _set_patrol_state() -> void:
    state = AIState.PATROL


func _set_chase_state() -> void:
    if state != AIState.CHASE:
        alert_mark.text = "!"
        alert_mark.visible = true
        alert_timer.start()
    state = AIState.CHASE


func _face_player_horizontally() -> void:
    if player_ref and player_ref is Node2D:
        var dir: int = signi((player_ref as Node2D).global_position.x - global_position.x)
        if dir != 0 and dir != facing_direction:
            facing_direction = dir
            _update_facing_setup()


func _refresh_player_ref() -> void:
    if player_ref and is_instance_valid(player_ref):
        return
    var current_scene: Node = get_tree().current_scene
    if current_scene:
        player_ref = current_scene.find_child("Player_G", true, false)


func _is_player_in_layer_b() -> bool:
    if not player_ref or not is_instance_valid(player_ref):
        return false
    return bool(player_ref.get("is_in_layer_b"))


func _is_on_same_layer_as_player() -> bool:
    if not player_ref or not is_instance_valid(player_ref):
        return true
    return bool(player_ref.get("is_in_layer_b")) == is_in_layer_b


func _can_see_player() -> bool:
    if not player_ref or not is_instance_valid(player_ref):
        return false
    if not _is_player_height_valid():
        return false
    vision_ray.force_raycast_update()
    if not vision_ray.is_colliding():
        return false
    var collider: Object = vision_ray.get_collider()
    return collider == player_ref


func _is_player_height_valid() -> bool:
    if not player_ref or not is_instance_valid(player_ref):
        return false
    if player_ref is not Node2D:
        return false
    var y_delta: float = absf((player_ref as Node2D).global_position.y - global_position.y)
    return y_delta <= vision_height_tolerance


func _is_chase_memory_valid() -> bool:
    if not player_ref or not is_instance_valid(player_ref):
        return false
    if player_ref is not Node2D:
        return false
    var p: Node2D = player_ref as Node2D
    var dx: float = absf(p.global_position.x - global_position.x)
    if dx > vision_distance * chase_memory_horizontal_mult:
        return false
    var dy: float = absf(p.global_position.y - global_position.y)
    if dy > chase_memory_max_y_delta:
        return false
    return true


func _get_body_half_width() -> float:
    if body_shape and body_shape.shape and body_shape.shape is RectangleShape2D:
        var rect: RectangleShape2D = body_shape.shape as RectangleShape2D
        return rect.size.x * 0.5
    return 14.0


func _on_screen_entered() -> void:
    is_active = true


func _on_screen_exited() -> void:
    is_active = false
    state = AIState.PATROL
    chase_memory_left = 0.0
    alert_mark.visible = false


func _refresh_layer_interaction_state() -> void:
    var same_layer: bool = _is_on_same_layer_as_player()
    attack_box.monitoring = same_layer
    hurtbox.monitorable = same_layer


func _apply_layer_visual_state() -> void:
    if is_in_layer_b:
        sprite.modulate = Color(0.55, 0.86, 1.0, 0.78)
    else:
        sprite.modulate = Color(1, 1, 1, 1)


func set_enemy_layer_state(in_b_layer: bool) -> void:
    is_in_layer_b = in_b_layer
    _apply_layer_visual_state()
    _refresh_layer_interaction_state()


func force_shift_to_layer_a(direction: int = 1) -> void:
    if not is_in_layer_b:
        return

    var resolved_dir: int = direction if direction != 0 else facing_direction
    set_enemy_layer_state(false)
    chase_memory_left = 0.0
    state = AIState.PATROL
    velocity.x = resolved_dir * layer_shift_horizontal_force
    velocity.y = -layer_shift_upward_force
    alert_mark.text = "A"
    alert_mark.visible = true
    alert_timer.start()


func force_shift_to_layer_b(direction: int = 1) -> void:
    if is_in_layer_b:
        return

    var resolved_dir: int = direction if direction != 0 else facing_direction
    set_enemy_layer_state(true)
    chase_memory_left = 0.0
    state = AIState.PATROL
    velocity.x = resolved_dir * layer_shift_horizontal_force
    velocity.y = -layer_shift_upward_force
    alert_mark.text = "B"
    alert_mark.visible = true
    alert_timer.start()


func take_damage(amount: int, knockback_dir: float, force: float) -> void:
    health -= amount
    print("沙包挨揍了！受到伤害: ", amount, " 剩余血量: ", health)
    velocity.x = knockback_dir * force
    velocity.y = -200
    modulate = Color(10, 10, 10, 1)
    await get_tree().create_timer(0.1).timeout
    modulate = Color(1, 1, 1, 1)
    if health <= 0:
        print("沙包被锤爆了！")
        queue_free()


func _on_alert_timer_timeout() -> void:
    if is_instance_valid(alert_mark):
        alert_mark.visible = false
