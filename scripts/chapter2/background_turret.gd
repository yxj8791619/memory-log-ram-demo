extends Node2D

@export var is_in_layer_b: bool = true
@export var max_health: int = 70
@export var fire_interval: float = 1.1
@export var projectile_speed: float = 250.0
@export var projectile_damage: int = 12
@export var projectile_lifetime: float = 1.8
@export var layer_shift_upward_force: float = 180.0
@export var layer_shift_horizontal_force: float = 120.0

var health: int = 70
var player_ref: Node = null
var is_active: bool = false

@onready var core_visual: ColorRect = $VisualRoot/Core
@onready var shell_visual: ColorRect = $VisualRoot/Shell
@onready var visual_root: Node2D = $VisualRoot
@onready var hurtbox: Area2D = $Hurtbox
@onready var alert_mark: Label = $AlertMark
@onready var fire_timer: Timer = $FireTimer
@onready var alert_timer: Timer = $AlertTimer
@onready var screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

func _ready() -> void:
    health = max_health
    add_to_group("kick_targets")
    if not fire_timer.timeout.is_connected(_on_fire_timer_timeout):
        fire_timer.timeout.connect(_on_fire_timer_timeout)
    if not alert_timer.timeout.is_connected(_on_alert_timer_timeout):
        alert_timer.timeout.connect(_on_alert_timer_timeout)
    if not screen_notifier.screen_entered.is_connected(_on_screen_entered):
        screen_notifier.screen_entered.connect(_on_screen_entered)
    if not screen_notifier.screen_exited.is_connected(_on_screen_exited):
        screen_notifier.screen_exited.connect(_on_screen_exited)
    _refresh_player_ref()
    _apply_layer_visual_state()
    _refresh_layer_interaction_state()
    alert_mark.visible = false
    fire_timer.wait_time = fire_interval


func _physics_process(_delta: float) -> void:
    _refresh_player_ref()
    _refresh_layer_interaction_state()
    if not is_active:
        return
    if fire_timer.is_stopped() and _should_fire():
        fire_timer.start()


func _refresh_player_ref() -> void:
    if player_ref and is_instance_valid(player_ref):
        return
    var current_scene: Node = get_tree().current_scene
    if current_scene:
        player_ref = current_scene.find_child("Player_G", true, false)


func _refresh_layer_interaction_state() -> void:
    if player_ref and is_instance_valid(player_ref):
        hurtbox.monitorable = bool(player_ref.get("is_in_layer_b")) == is_in_layer_b
    else:
        hurtbox.monitorable = true


func _should_fire() -> bool:
    if not player_ref or not is_instance_valid(player_ref):
        return false
    if player_ref is not Node2D:
        return false
    return not bool(player_ref.get("is_in_layer_b"))


func _on_fire_timer_timeout() -> void:
    if not _should_fire():
        return
    _spawn_projectile()
    alert_mark.text = "!"
    alert_mark.visible = true
    alert_timer.start()


func _spawn_projectile() -> void:
    if not player_ref or not is_instance_valid(player_ref):
        return
    if player_ref is not Node2D:
        return

    var shot_marker := Line2D.new()
    shot_marker.name = "TurretShot"
    shot_marker.default_color = Color(1.0, 0.56, 0.24, 0.92)
    shot_marker.width = 5.0
    shot_marker.points = PackedVector2Array([
        global_position + Vector2(0.0, -10.0),
        (player_ref as Node2D).global_position
    ])
    get_tree().current_scene.add_child(shot_marker)

    if player_ref.has_method("take_damage"):
        player_ref.take_damage(projectile_damage)

    var life_timer := Timer.new()
    life_timer.one_shot = true
    life_timer.wait_time = 0.16
    shot_marker.add_child(life_timer)
    life_timer.timeout.connect(func() -> void:
        if is_instance_valid(shot_marker):
            shot_marker.queue_free()
    )
    life_timer.start()


func _on_screen_entered() -> void:
    is_active = true


func _on_screen_exited() -> void:
    is_active = false
    alert_mark.visible = false


func _on_alert_timer_timeout() -> void:
    if is_instance_valid(alert_mark):
        alert_mark.visible = false


func _apply_layer_visual_state() -> void:
    if is_in_layer_b:
        core_visual.color = Color(1.0, 0.58, 0.28, 0.98)
        shell_visual.color = Color(0.5, 0.82, 1.0, 0.88)
    else:
        core_visual.color = Color(1.0, 0.68, 0.38, 0.82)
        shell_visual.color = Color(0.72, 0.82, 0.92, 0.92)


func set_enemy_layer_state(in_b_layer: bool) -> void:
    is_in_layer_b = in_b_layer
    _apply_layer_visual_state()
    _refresh_layer_interaction_state()


func force_shift_to_layer_b(direction: int = 1) -> void:
    if is_in_layer_b:
        return
    var resolved_dir: int = direction if direction != 0 else 1
    set_enemy_layer_state(true)
    visual_root.position += Vector2(resolved_dir * layer_shift_horizontal_force, -layer_shift_upward_force)
    alert_mark.text = "B"
    alert_mark.visible = true
    alert_timer.start()


func force_shift_to_layer_a(direction: int = 1) -> void:
    if not is_in_layer_b:
        return
    var resolved_dir: int = direction if direction != 0 else 1
    set_enemy_layer_state(false)
    visual_root.position += Vector2(resolved_dir * layer_shift_horizontal_force, -layer_shift_upward_force)
    alert_mark.text = "A"
    alert_mark.visible = true
    alert_timer.start()


func take_damage(amount: int, _knockback_dir: float = 0.0, _force: float = 0.0) -> void:
    health -= amount
    core_visual.color = Color(1.0, 1.0, 1.0, 1.0)
    await get_tree().create_timer(0.08).timeout
    if is_instance_valid(core_visual):
        _apply_layer_visual_state()
    if health <= 0:
        queue_free()
