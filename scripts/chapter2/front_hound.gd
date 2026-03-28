extends CharacterBody2D

enum AIState {
    PATROL,
    CHASE,
    POUNCE
}

@export var is_in_layer_b: bool = false
@export var max_health: int = 90
@export var gravity: float = 980.0
@export var a_patrol_speed: float = 96.0
@export var a_chase_speed: float = 150.0
@export var b_patrol_speed: float = 78.0
@export var b_chase_speed: float = 176.0
@export var acceleration: float = 1200.0
@export var patrol_range: float = 92.0
@export var vision_distance: float = 420.0
@export var vision_height_tolerance: float = 96.0
@export var attack_damage: int = 18
@export var pounce_cooldown_a: float = 1.2
@export var pounce_cooldown_b: float = 0.85
@export var pounce_speed_x_a: float = 220.0
@export var pounce_speed_x_b: float = 190.0
@export var pounce_speed_y_a: float = -180.0
@export var pounce_speed_y_b: float = -320.0
@export var layer_shift_upward_force: float = 220.0
@export var layer_shift_horizontal_force: float = 200.0
@export var chase_speed_scale: float = 1.0
@export var pounce_cooldown_scale: float = 1.0

var health: int = 90
var facing_direction: int = -1
var state: int = AIState.PATROL
var patrol_center_x: float = 0.0
var player_ref: Node = null
var is_active: bool = false
var pounce_ready: bool = true

@onready var body_visual: ColorRect = $VisualRoot/Body
@onready var trail_visual: ColorRect = $VisualRoot/Trail
@onready var visual_root: Node2D = $VisualRoot
@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var attack_box: Area2D = $AttackBox
@onready var hurtbox: Area2D = $Hurtbox
@onready var vision_ray: RayCast2D = $VisionRay
@onready var ledge_check: RayCast2D = $LedgeCheck
@onready var alert_mark: Label = $AlertMark
@onready var screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@onready var pounce_timer: Timer = $PounceTimer
@onready var alert_timer: Timer = $AlertTimer

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
    if not pounce_timer.timeout.is_connected(_on_pounce_timer_timeout):
        pounce_timer.timeout.connect(_on_pounce_timer_timeout)
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
        _maybe_start_pounce()
    elif state != AIState.POUNCE:
        state = AIState.PATROL

    var target_speed: float = velocity.x
    if state == AIState.PATROL:
        var left_limit: float = patrol_center_x - patrol_range
        var right_limit: float = patrol_center_x + patrol_range
        var reached_edge: bool = (global_position.x <= left_limit and facing_direction < 0) or (global_position.x >= right_limit and facing_direction > 0)
        if _is_blocked_ahead() or reached_edge:
            facing_direction *= -1
            _update_facing_setup()
        target_speed = _get_patrol_speed() * facing_direction
    elif state == AIState.CHASE:
        _face_player_horizontally()
        target_speed = _get_chase_speed() * facing_direction

    if state != AIState.POUNCE:
        velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)

    move_and_slide()

    if state == AIState.POUNCE and is_on_floor():
        state = AIState.CHASE if _can_see_player() else AIState.PATROL


func _get_patrol_speed() -> float:
    return b_patrol_speed if is_in_layer_b else a_patrol_speed


func _get_chase_speed() -> float:
    var base_speed: float = b_chase_speed if is_in_layer_b else a_chase_speed
    return base_speed * chase_speed_scale


func _get_pounce_cooldown() -> float:
    var base_cooldown: float = pounce_cooldown_b if is_in_layer_b else pounce_cooldown_a
    return base_cooldown * pounce_cooldown_scale


func _get_pounce_velocity() -> Vector2:
    if is_in_layer_b:
        return Vector2(float(facing_direction) * pounce_speed_x_b, pounce_speed_y_b)
    return Vector2(float(facing_direction) * pounce_speed_x_a, pounce_speed_y_a)


func _maybe_start_pounce() -> void:
    if not pounce_ready:
        return
    if not player_ref or player_ref is not Node2D:
        return
    var target: Node2D = player_ref as Node2D
    var distance: float = global_position.distance_to(target.global_position)
    if distance > 180.0:
        return

    pounce_ready = false
    pounce_timer.wait_time = _get_pounce_cooldown()
    pounce_timer.start()
    velocity = _get_pounce_velocity()
    state = AIState.POUNCE
    alert_mark.text = ">"
    alert_mark.visible = true
    alert_timer.start()


func _on_pounce_timer_timeout() -> void:
    pounce_ready = true


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


func _refresh_player_ref() -> void:
    if player_ref and is_instance_valid(player_ref):
        return
    var current_scene: Node = get_tree().current_scene
    if current_scene:
        player_ref = current_scene.find_child("Player_G", true, false)


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
        facing_direction = dir
        _update_facing_setup()


func _get_body_half_width() -> float:
    if body_shape.shape is RectangleShape2D:
        return (body_shape.shape as RectangleShape2D).size.x * 0.5
    return 14.0


func _update_facing_setup() -> void:
    visual_root.scale.x = facing_direction
    vision_ray.target_position.x = vision_distance * facing_direction
    ledge_check.position.x = _get_body_half_width() * facing_direction
    ledge_check.target_position = Vector2(18.0 * facing_direction, 24.0)


func _is_blocked_ahead() -> bool:
    ledge_check.force_raycast_update()
    return not ledge_check.is_colliding() or is_on_wall()


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
        body_visual.color = Color(0.93, 0.74, 0.42, 1.0)
        trail_visual.color = Color(0.6, 0.84, 1.0, 0.65)
    else:
        body_visual.color = Color(1.0, 0.63, 0.35, 1.0)
        trail_visual.color = Color(1.0, 0.88, 0.54, 0.55)


func set_enemy_layer_state(in_b_layer: bool) -> void:
    is_in_layer_b = in_b_layer
    _apply_layer_visual_state()
    _refresh_layer_interaction_state()


func set_runtime_pressure(chase_scale: float = 1.0, cooldown_scale: float = 1.0) -> void:
    chase_speed_scale = chase_scale
    pounce_cooldown_scale = cooldown_scale


func force_shift_to_layer_b(direction: int = 1) -> void:
    if is_in_layer_b:
        return
    var resolved_dir: int = direction if direction != 0 else facing_direction
    set_enemy_layer_state(true)
    velocity.x = resolved_dir * layer_shift_horizontal_force
    velocity.y = -layer_shift_upward_force
    state = AIState.PATROL
    alert_mark.text = "B"
    alert_mark.visible = true
    alert_timer.start()


func force_shift_to_layer_a(direction: int = 1) -> void:
    if not is_in_layer_b:
        return
    var resolved_dir: int = direction if direction != 0 else facing_direction
    set_enemy_layer_state(false)
    velocity.x = resolved_dir * layer_shift_horizontal_force
    velocity.y = -layer_shift_upward_force
    state = AIState.PATROL
    alert_mark.text = "A"
    alert_mark.visible = true
    alert_timer.start()


func take_damage(amount: int, knockback_dir: float, force: float) -> void:
    health -= amount
    velocity.x = knockback_dir * force
    velocity.y = -180.0
    alert_mark.text = "!"
    alert_mark.visible = true
    alert_timer.start()
    if health <= 0:
        queue_free()
