extends CharacterBody2D

enum AIState {
    PATROL,
    CHASE
}

@export var is_in_layer_b: bool = false
@export var max_health: int = 180
@export var gravity: float = 980.0
@export var a_patrol_speed: float = 48.0
@export var a_chase_speed: float = 72.0
@export var b_patrol_speed: float = 30.0
@export var b_chase_speed: float = 52.0
@export var acceleration: float = 520.0
@export var vision_distance: float = 360.0
@export var vision_height_tolerance: float = 64.0
@export var patrol_range: float = 72.0
@export var attack_damage: int = 20
@export var front_guard_a_multiplier: float = 0.15
@export var front_guard_b_multiplier: float = 0.4
@export var back_exposed_b_multiplier: float = 1.3
@export var turn_delay_a: float = 0.3
@export var turn_delay_b: float = 1.05
@export var layer_shift_upward_force: float = 220.0
@export var layer_shift_horizontal_force: float = 160.0

var health: int = 180
var facing_direction: int = -1
var state: int = AIState.PATROL
var patrol_center_x: float = 0.0
var player_ref: Node = null
var chase_memory_left: float = 0.0
var is_active: bool = false
var pending_facing_direction: int = -1
var is_turning: bool = false

@onready var sprite: ColorRect = $VisualRoot/Body
@onready var shield_visual: ColorRect = $VisualRoot/ShieldPanel
@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var attack_box: Area2D = $AttackBox
@onready var vision_ray: RayCast2D = $VisionRay
@onready var ledge_check: RayCast2D = $LedgeCheck
@onready var alert_mark: Label = $AlertMark
@onready var screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@onready var turn_timer: Timer = $TurnTimer
@onready var alert_timer: Timer = $AlertTimer
@onready var visual_root: Node2D = $VisualRoot

func _ready() -> void:
    health = max_health
    add_to_group("kick_targets")
    patrol_center_x = global_position.x

    if not attack_box.body_entered.is_connected(_on_attack_box_body_entered):
        attack_box.body_entered.connect(_on_attack_box_body_entered)
    if not screen_notifier.screen_entered.is_connected(_on_screen_entered):
        screen_notifier.screen_entered.connect(_on_screen_entered)
    if not screen_notifier.screen_exited.is_connected(_on_screen_exited):
        screen_notifier.screen_exited.connect(_on_screen_exited)
    if not turn_timer.timeout.is_connected(_on_turn_timer_timeout):
        turn_timer.timeout.connect(_on_turn_timer_timeout)
    if not alert_timer.timeout.is_connected(_on_alert_timer_timeout):
        alert_timer.timeout.connect(_on_alert_timer_timeout)

    _configure_rays()
    _update_facing_setup()
    _refresh_player_ref()
    _apply_layer_visual_state()
    _refresh_layer_interaction_state()
    alert_mark.visible = false


func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y += gravity * delta

    _refresh_player_ref()
    _refresh_layer_interaction_state()

    if not is_active:
        velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
        move_and_slide()
        return

    var same_layer: bool = _is_on_same_layer_as_player()
    if not same_layer:
        state = AIState.PATROL
    elif _can_see_player():
        state = AIState.CHASE
    else:
        state = AIState.PATROL

    var target_speed: float = 0.0
    if is_turning:
        target_speed = 0.0
    elif state == AIState.PATROL:
        var left_limit: float = patrol_center_x - patrol_range
        var right_limit: float = patrol_center_x + patrol_range
        var reached_edge: bool = (global_position.x <= left_limit and facing_direction < 0) or (global_position.x >= right_limit and facing_direction > 0)
        if _is_blocked_ahead() or reached_edge:
            _begin_turn(-facing_direction)
        target_speed = _get_patrol_speed() * facing_direction
    else:
        _face_player_horizontally()
        target_speed = _get_chase_speed() * facing_direction

    velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)
    move_and_slide()


func _get_patrol_speed() -> float:
    return b_patrol_speed if is_in_layer_b else a_patrol_speed


func _get_chase_speed() -> float:
    return b_chase_speed if is_in_layer_b else a_chase_speed


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


func _update_facing_setup() -> void:
    visual_root.scale.x = facing_direction
    vision_ray.target_position.x = vision_distance * facing_direction
    ledge_check.position.x = _get_body_half_width() * facing_direction
    ledge_check.target_position = Vector2(18.0 * facing_direction, 24.0)


func _get_body_half_width() -> float:
    if body_shape.shape is RectangleShape2D:
        return (body_shape.shape as RectangleShape2D).size.x * 0.5
    return 18.0


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


func _refresh_layer_interaction_state() -> void:
    var same_layer: bool = _is_on_same_layer_as_player()
    attack_box.monitoring = same_layer
    hurtbox.monitorable = same_layer


func _can_see_player() -> bool:
    if not player_ref or not is_instance_valid(player_ref):
        return false
    if player_ref is not Node2D:
        return false
    if absf((player_ref as Node2D).global_position.y - global_position.y) > vision_height_tolerance:
        return false
    vision_ray.force_raycast_update()
    if not vision_ray.is_colliding():
        return false
    return vision_ray.get_collider() == player_ref


func _face_player_horizontally() -> void:
    if not player_ref or player_ref is not Node2D:
        return
    var dir: int = signi((player_ref as Node2D).global_position.x - global_position.x)
    if dir != 0 and dir != facing_direction:
        _begin_turn(dir)


func _is_blocked_ahead() -> bool:
    ledge_check.force_raycast_update()
    var reached_ledge: bool = not ledge_check.is_colliding()
    return reached_ledge or is_on_wall()


func _begin_turn(target_direction: int) -> void:
    if target_direction == 0 or target_direction == facing_direction:
        return
    pending_facing_direction = target_direction
    is_turning = true
    turn_timer.wait_time = turn_delay_b if is_in_layer_b else turn_delay_a
    turn_timer.start()


func _on_turn_timer_timeout() -> void:
    facing_direction = pending_facing_direction
    is_turning = false
    _update_facing_setup()


func _on_screen_entered() -> void:
    is_active = true


func _on_screen_exited() -> void:
    is_active = false
    state = AIState.PATROL
    alert_mark.visible = false


func _on_alert_timer_timeout() -> void:
    if is_instance_valid(alert_mark):
        alert_mark.visible = false


func _apply_layer_visual_state() -> void:
    if is_in_layer_b:
        sprite.color = Color(0.42, 0.65, 1.0, 1.0)
        shield_visual.color = Color(0.64, 0.85, 1.0, 0.95)
    else:
        sprite.color = Color(0.45, 0.5, 0.58, 1.0)
        shield_visual.color = Color(0.82, 0.9, 1.0, 0.98)


func set_enemy_layer_state(in_b_layer: bool) -> void:
    is_in_layer_b = in_b_layer
    _apply_layer_visual_state()
    _refresh_layer_interaction_state()


func force_shift_to_layer_b(direction: int = 1) -> void:
    if is_in_layer_b:
        return
    var resolved_dir: int = direction if direction != 0 else facing_direction
    set_enemy_layer_state(true)
    state = AIState.PATROL
    velocity.x = resolved_dir * layer_shift_horizontal_force
    velocity.y = -layer_shift_upward_force
    alert_mark.text = "B"
    alert_mark.visible = true
    alert_timer.start()


func force_shift_to_layer_a(direction: int = 1) -> void:
    if not is_in_layer_b:
        return
    var resolved_dir: int = direction if direction != 0 else facing_direction
    set_enemy_layer_state(false)
    state = AIState.PATROL
    velocity.x = resolved_dir * layer_shift_horizontal_force
    velocity.y = -layer_shift_upward_force
    alert_mark.text = "A"
    alert_mark.visible = true
    alert_timer.start()


func _is_front_hit(knockback_dir: float) -> bool:
    var attack_dir: int = signi(knockback_dir)
    if attack_dir == 0:
        attack_dir = 1
    return attack_dir != facing_direction


func take_damage(amount: int, knockback_dir: float, force: float) -> void:
    var actual_damage: int = amount
    if _is_front_hit(knockback_dir):
        var multiplier: float = front_guard_b_multiplier if is_in_layer_b else front_guard_a_multiplier
        actual_damage = max(1, int(round(float(amount) * multiplier)))
    elif is_in_layer_b:
        actual_damage = int(round(float(amount) * back_exposed_b_multiplier))

    health -= actual_damage
    velocity.x = knockback_dir * force
    velocity.y = -160.0
    alert_mark.text = "!"
    alert_mark.visible = true
    alert_timer.start()

    if health <= 0:
        queue_free()
