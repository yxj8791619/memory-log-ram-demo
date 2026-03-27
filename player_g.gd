extends CharacterBody2D

signal layer_switched(is_in_b_layer: bool)

var is_in_layer_b: bool = false
@export var bullet_scene: PackedScene
@export var can_switch_layer: bool = false
@export var can_use_hammer: bool = false
@export var can_kick_to_b: bool = false
@export var max_health: int = 100
@export var is_invincible: bool = false
var current_health: int = 100
var is_wind_buffed: bool = false
var wind_buff_active: bool = false
var wind_buff_timer: Timer
var wind_speed_multiplier: float = 1.0
var wind_foot_fx: GPUParticles2D
var facing_direction: int = 1
var is_dropping_through: bool = false
var drop_through_time_left: float = 0.0
var drop_start_y: float = 0.0
var drop_neutral_world_x: float = 0.0
var drop_squeeze_time_left: float = 0.0
var saved_floor_snap_length: float = 0.0
@export var drop_through_duration: float = 0.22
@export var drop_through_distance: float = 32.0
@export var drop_nudge_pixels: float = 6.0
@export var drop_initial_speed: float = 260.0
@export var drop_post_squeeze_duration: float = 0.18
@export var debug_drop_probe: bool = false
var debug_drop_left_from: Vector2 = Vector2.ZERO
var debug_drop_left_to: Vector2 = Vector2.ZERO
var debug_drop_right_from: Vector2 = Vector2.ZERO
var debug_drop_right_to: Vector2 = Vector2.ZERO
var debug_drop_mid_from: Vector2 = Vector2.ZERO
var debug_drop_mid_to: Vector2 = Vector2.ZERO
var debug_drop_left_hit: bool = false
var debug_drop_right_hit: bool = false
var debug_drop_mid_hit: bool = false
var debug_drop_allowed: bool = false
var debug_drop_box_center: Vector2 = Vector2.ZERO
var debug_drop_box_size: Vector2 = Vector2.ZERO

@onready var anim_tree: AnimationTree = $AnimationTree
@onready var state_machine = anim_tree.get("parameters/playback")
@onready var sprite: Sprite2D = $DirectionPivot/Sprite2D
@onready var muzzle: Marker2D = $DirectionPivot/Muzzle
@onready var hammer_hitbox: Area2D = $DirectionPivot/HammerHitbox
@onready var kick_hitbox: Area2D = $DirectionPivot/KickHitbox
@onready var kick_collision: CollisionShape2D = $DirectionPivot/KickHitbox/CollisionShape2D
@onready var invincibility_timer: Timer = $InvincibilityTimer
@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var screen_switch_flash: ColorRect = $Camera2D/ScreenSwitchFlash
@onready var screen_switch_band: ColorRect = $Camera2D/ScreenSwitchBand
@onready var screen_switch_edge: ColorRect = $Camera2D/ScreenSwitchEdge
@onready var combo_rule_hint: Label = $Camera2D/ComboRuleHint
var screen_flash_tween: Tween
var screen_band_tween: Tween
var combo_rule_hint_tween: Tween

# ================= 1. A层 (活跃内存) 物理参数 =================
@export_category("Layer A (活跃内存)")
@export var a_run_speed: float = 380.0  
@export var a_acceleration: float = 3000.0  
@export var a_friction: float = 3500.0      
@export var a_jump_height: float = 85.0         
@export var a_time_to_peak: float = 0.28   
@export var a_time_to_descent: float = 0.22 
@onready var direction_pivot: Marker2D = $DirectionPivot

# ================= 2. B层 (虚拟内存) 物理参数 =================
@export_category("Layer B (虚拟内存)")
@export var b_run_speed: float = 250.0      
@export var b_acceleration: float = 800.0   
@export var b_friction: float = 600.0       
@export var b_jump_height: float = 120.0    
@export var b_time_to_peak: float = 0.6     
@export var b_time_to_descent: float = 0.5 

func _ready():
    current_health = max_health
    if not invincibility_timer.timeout.is_connected(_on_invincibility_timeout):
        invincibility_timer.timeout.connect(_on_invincibility_timeout)
    wind_buff_timer = Timer.new()
    wind_buff_timer.name = "WindBuffTimer"
    wind_buff_timer.one_shot = true
    wind_buff_timer.wait_time = 2.0
    add_child(wind_buff_timer)
    if not wind_buff_timer.timeout.is_connected(_on_wind_buff_timeout):
        wind_buff_timer.timeout.connect(_on_wind_buff_timeout)
    _setup_wind_foot_fx()
    _update_collision_masks()
    if screen_switch_flash:
        screen_switch_flash.visible = false
    if screen_switch_band:
        screen_switch_band.visible = false
    if screen_switch_edge:
        screen_switch_edge.visible = false
    if combo_rule_hint:
        combo_rule_hint.visible = false

func _physics_process(delta: float) -> void:
    _update_wind_buff_state()
    _update_drop_through_state(delta)
    if drop_squeeze_time_left > 0.0:
        drop_squeeze_time_left -= delta
    if debug_drop_probe:
        queue_redraw()

    # 0. 提前获取当前动画状态
    var current_anim = state_machine.get_current_node()

    var wants_switch_layer: bool = Input.is_action_just_pressed("switch_layer")
    var wants_attack: bool = Input.is_action_just_pressed("attack")
    var switch_layer_held: bool = Input.is_action_pressed("switch_layer")

    # 2. 动态获取当前的物理参数
    var current_speed = b_run_speed if is_in_layer_b else a_run_speed
    current_speed *= wind_speed_multiplier
    var current_accel = b_acceleration if is_in_layer_b else a_acceleration
    var current_frict = b_friction if is_in_layer_b else a_friction
    
    var current_jump_peak = b_time_to_peak if is_in_layer_b else a_time_to_peak
    var current_jump_desc = b_time_to_descent if is_in_layer_b else a_time_to_descent
    var current_jump_height = b_jump_height if is_in_layer_b else a_jump_height
    
    var base_jump_velocity = -((2.0 * current_jump_height) / current_jump_peak)
    var jump_gravity = (2.0 * current_jump_height) / (current_jump_peak * current_jump_peak)
    var fall_gravity = (2.0 * current_jump_height) / (current_jump_desc * current_jump_desc)

    # 3. 动作硬直与惩罚机制 (Attack Commitment)
    var speed_multiplier = 1.0
    var jump_multiplier = 1.0
    
    if current_anim == "b_hammer":
        speed_multiplier = 0.1  # 抡锤时几乎走不动
        jump_multiplier = 0.5   # 抡锤时跳不高
    elif current_anim == "a_shoot":
        speed_multiplier = 0.8  # 射击时轻微减速
        
    var final_speed = current_speed * speed_multiplier
    var final_jump_velocity = base_jump_velocity * jump_multiplier

    # 4. 处理重力
    if not is_on_floor():
        velocity.y += (fall_gravity if velocity.y > 0 else jump_gravity) * delta

    # 5. 处理跳跃
    if Input.is_action_just_pressed("jump") and is_on_floor():
        if _is_pressing_down():
            _start_drop_through()
        else:
            velocity.y = final_jump_velocity

    # 6. 处理移动（下跳/刚恢复碰撞的短窗口内：不按左右时抵消物理横向挤出；按了键则正常偏移）
    var direction: float = Input.get_axis("move_left", "move_right")
    if direction != 0:
        velocity.x = move_toward(velocity.x, direction * final_speed, current_accel * delta)
    else:
        velocity.x = move_toward(velocity.x, 0, current_frict * delta)

    move_and_slide()
    var anti_drift_window: bool = is_dropping_through or drop_squeeze_time_left > 0.0
    if anti_drift_window:
        if absf(direction) > 0.01:
            drop_neutral_world_x = global_position.x
        else:
            global_position.x = drop_neutral_world_x
            velocity.x = 0.0
    _update_wind_foot_fx()

    # ================= 动画与面朝向控制 =================
    

    # 7. 朝向由鼠标位置决定（支持边退边打）
    if is_in_layer_b:
        if direction > 0.01:
            facing_direction = 1
        elif direction < -0.01:
            facing_direction = -1
        direction_pivot.scale.x = facing_direction
    elif current_anim != "b_hammer":
        var mouse_x: float = get_global_mouse_position().x
        if mouse_x > global_position.x:
            facing_direction = 1
        elif mouse_x < global_position.x:
            facing_direction = -1
        direction_pivot.scale.x = facing_direction
            
    # 8. 触发攻击 / 组合输入
    _handle_combat_input(
        wants_attack,
        wants_switch_layer,
        switch_layer_held,
        Input.is_action_just_pressed("kick_to_b")
    )
            
    # 9. 状态恢复 (不在攻击时，才切换跑和待机)
    if current_anim != "a_shoot" and current_anim != "b_hammer":
        if is_on_floor():
            if direction != 0:
                state_machine.travel("run")
            else:
                state_machine.travel("idle")

# --- 切换维度的具体逻辑 ---
func toggle_dimension(effect_kind: String = "switch"):
    is_in_layer_b = !is_in_layer_b
    _update_collision_masks()
    layer_switched.emit(is_in_layer_b)
    get_tree().call_group("cross_layer_objects", "on_dimension_switched", is_in_layer_b)
    _play_layer_switch_screen_fx(effect_kind)


func shoot() -> void:
    if bullet_scene == null:
        return

    var bullet = bullet_scene.instantiate()
    get_tree().current_scene.add_child(bullet)
    bullet.global_position = muzzle.global_position
    bullet.direction = facing_direction


func perform_kick_to_b() -> bool:
    if is_in_layer_b or not can_kick_to_b:
        return false

    var kicked_any: bool = false
    for enemy in get_tree().get_nodes_in_group("kick_targets"):
        if enemy == null or not is_instance_valid(enemy):
            continue
        if not enemy.has_method("force_shift_to_layer_b"):
            continue
        if bool(enemy.get("is_in_layer_b")):
            continue
        if not _is_enemy_in_kick_range(enemy as Node2D):
            continue

        var dir: int = signi(enemy.global_position.x - global_position.x)
        if dir == 0:
            dir = facing_direction

        enemy.force_shift_to_layer_b(dir)
        kicked_any = true

    if kicked_any:
        print("A层踢怪成功：目标已被送往 B 层。")
    return kicked_any


func perform_basic_hammer_attack() -> void:
    if not is_in_layer_b or not can_use_hammer:
        return
    state_machine.travel("b_hammer")
    _show_combo_rule_hint("普通锤击：留在 B 层稳杀", Color(0.72, 0.95, 1.0, 0.95))
    if hammer_hitbox and hammer_hitbox.has_method("perform_basic_swing"):
        hammer_hitbox.perform_basic_swing()


func perform_return_cut() -> void:
    if not is_in_layer_b or not can_use_hammer:
        return
    state_machine.travel("b_hammer_return")
    _show_combo_rule_hint("锤攻击 + 切层键：命中后带怪回 A 层", Color(1.0, 0.9, 0.58, 0.98))
    if hammer_hitbox and hammer_hitbox.has_method("perform_return_cut"):
        hammer_hitbox.perform_return_cut()


func _should_trigger_return_cut(switch_layer_pressed: bool) -> bool:
    return is_in_layer_b and can_use_hammer and can_switch_layer and switch_layer_pressed


func _handle_combat_input(
    wants_attack: bool,
    wants_switch_layer: bool,
    switch_layer_pressed: bool,
    wants_kick_to_b: bool
) -> void:
    if wants_attack and _should_trigger_return_cut(switch_layer_pressed):
        perform_return_cut()
    elif wants_switch_layer and can_switch_layer:
        if is_in_layer_b:
            _show_combo_rule_hint("TAB / 右键：只切自己，不带怪", Color(0.8, 0.98, 1.0, 0.95))
        toggle_dimension()
    elif wants_kick_to_b and can_kick_to_b and not is_in_layer_b:
        perform_kick_to_b()
    elif wants_attack:
        if is_in_layer_b and can_use_hammer:
            perform_basic_hammer_attack()
        else:
            state_machine.travel("a_shoot")
            shoot()


func _is_enemy_in_kick_range(enemy: Node2D) -> bool:
    if enemy == null:
        return false

    var local_delta: Vector2 = enemy.global_position - global_position
    var vertical_ok: bool = absf(local_delta.y) <= 48.0
    if not vertical_ok:
        return false

    if facing_direction >= 0:
        return local_delta.x >= -6.0 and local_delta.x <= 72.0
    return local_delta.x <= 6.0 and local_delta.x >= -72.0


func take_damage(amount: int) -> void:
    if is_invincible:
        return

    current_health -= amount
    is_invincible = true
    invincibility_timer.start()
    print("玩家受到伤害: ", amount, " 当前血量: ", current_health)

    sprite.modulate = Color(1, 0.2, 0.2, 1)
    await get_tree().create_timer(0.12).timeout
    if is_instance_valid(sprite):
        sprite.modulate = Color(1, 1, 1, 0.5)

    if current_health <= 0:
        die()


func die() -> void:
    print("玩家死亡，重新加载当前关卡。")
    get_tree().reload_current_scene()


func _on_invincibility_timeout() -> void:
    is_invincible = false
    sprite.modulate = Color(1, 1, 1, 1)


func apply_wind_buff(is_entering: bool) -> void:
    if is_entering:
        is_wind_buffed = true
        wind_buff_active = true
        wind_speed_multiplier = 1.5
        if wind_buff_timer and not wind_buff_timer.is_stopped():
            wind_buff_timer.stop()
    else:
        is_wind_buffed = false
        wind_buff_active = true
        if wind_buff_timer:
            wind_buff_timer.start()


func _on_wind_buff_timeout() -> void:
    wind_buff_active = false
    wind_speed_multiplier = 1.0


func _update_wind_buff_state() -> void:
    if is_wind_buffed:
        wind_buff_active = true
        wind_speed_multiplier = 1.5
        return

    if wind_buff_timer and not wind_buff_timer.is_stopped():
        var ratio: float = wind_buff_timer.time_left / wind_buff_timer.wait_time
        wind_speed_multiplier = 1.0 + (0.5 * ratio)
        wind_buff_active = true
    else:
        wind_speed_multiplier = 1.0
        wind_buff_active = false


func _setup_wind_foot_fx() -> void:
    wind_foot_fx = GPUParticles2D.new()
    wind_foot_fx.name = "WindFootFx"
    wind_foot_fx.amount = 45
    wind_foot_fx.lifetime = 0.42
    wind_foot_fx.one_shot = false
    wind_foot_fx.emitting = false
    wind_foot_fx.position = Vector2(0, 18)
    wind_foot_fx.local_coords = true
    wind_foot_fx.z_index = 20
    wind_foot_fx.texture = _create_wind_particle_texture()

    var process: ParticleProcessMaterial = ParticleProcessMaterial.new()
    process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
    process.emission_box_extents = Vector3(14.0, 3.0, 0.0)
    process.direction = Vector3(0.0, -1.0, 0.0)
    process.spread = 45.0
    process.gravity = Vector3(0.0, 20.0, 0.0)
    process.initial_velocity_min = 45.0
    process.initial_velocity_max = 85.0
    process.scale_min = 0.55
    process.scale_max = 0.95

    var gradient: Gradient = Gradient.new()
    gradient.colors = PackedColorArray([
        Color(0.65, 0.92, 1.0, 0.45),
        Color(0.75, 0.96, 1.0, 0.22),
        Color(0.8, 0.97, 1.0, 0.0)
    ])
    gradient.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
    var gradient_texture: GradientTexture1D = GradientTexture1D.new()
    gradient_texture.gradient = gradient
    process.color_ramp = gradient_texture

    wind_foot_fx.process_material = process
    add_child(wind_foot_fx)


func _create_wind_particle_texture() -> ImageTexture:
    var image: Image = Image.create(24, 24, false, Image.FORMAT_RGBA8)
    var center: Vector2 = Vector2(12.0, 12.0)
    var max_distance: float = 12.0

    for y in range(24):
        for x in range(24):
            var point: Vector2 = Vector2(float(x), float(y))
            var distance_ratio: float = point.distance_to(center) / max_distance
            var alpha: float = clampf(1.0 - distance_ratio, 0.0, 1.0)
            image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))

    return ImageTexture.create_from_image(image)


func _update_wind_foot_fx() -> void:
    if wind_foot_fx == null:
        return

    var should_emit: bool = wind_buff_active and absf(velocity.x) > 5.0 and is_on_floor()
    wind_foot_fx.emitting = should_emit
    var facing: float = float(facing_direction)
    var trailing_offset_x: float = -facing * 14.0
    wind_foot_fx.position = Vector2(trailing_offset_x, 18)


func _play_layer_switch_screen_fx(effect_kind: String) -> void:
    if screen_switch_flash == null or screen_switch_band == null or screen_switch_edge == null:
        return
    if screen_flash_tween:
        screen_flash_tween.kill()
    if screen_band_tween:
        screen_band_tween.kill()

    var flash_color: Color = Color(0.62, 0.9, 1.0, 0.0)
    var peak_alpha: float = 0.16
    var band_color: Color = Color(0.75, 0.97, 1.0, 0.0)
    var edge_color: Color = Color(0.33, 0.72, 1.0, 0.0)
    var band_scale: Vector2 = Vector2(0.18, 1.0)
    if effect_kind == "return_cut":
        flash_color = Color(1.0, 0.84, 0.45, 0.0)
        peak_alpha = 0.24
        band_color = Color(1.0, 0.9, 0.56, 0.0)
        edge_color = Color(0.98, 0.7, 0.22, 0.0)
        band_scale = Vector2(0.24, 1.0)

    screen_switch_flash.visible = true
    screen_switch_flash.color = flash_color
    screen_switch_band.visible = true
    screen_switch_band.color = band_color
    screen_switch_band.scale = band_scale
    screen_switch_edge.visible = true
    screen_switch_edge.color = edge_color
    screen_switch_edge.scale = Vector2(1.0, 0.2)

    screen_flash_tween = create_tween()
    screen_flash_tween.tween_property(screen_switch_flash, "color:a", peak_alpha, 0.08)
    screen_flash_tween.tween_property(screen_switch_flash, "color:a", 0.0, 0.18)
    screen_flash_tween.finished.connect(func() -> void:
        if is_instance_valid(screen_switch_flash):
            screen_switch_flash.visible = false
    )

    screen_band_tween = create_tween()
    screen_band_tween.set_parallel(true)
    screen_band_tween.tween_property(screen_switch_band, "color:a", 0.32, 0.06)
    screen_band_tween.tween_property(screen_switch_band, "scale:x", 1.18, 0.18)
    screen_band_tween.tween_property(screen_switch_band, "color:a", 0.0, 0.16).set_delay(0.08)
    screen_band_tween.tween_property(screen_switch_edge, "color:a", 0.5, 0.04)
    screen_band_tween.tween_property(screen_switch_edge, "scale:y", 1.15, 0.12)
    screen_band_tween.tween_property(screen_switch_edge, "color:a", 0.0, 0.12).set_delay(0.1)
    screen_band_tween.finished.connect(func() -> void:
        if is_instance_valid(screen_switch_band):
            screen_switch_band.visible = false
        if is_instance_valid(screen_switch_edge):
            screen_switch_edge.visible = false
    )


func _show_combo_rule_hint(text: String, color: Color) -> void:
    if combo_rule_hint == null:
        return
    if combo_rule_hint_tween:
        combo_rule_hint_tween.kill()
    combo_rule_hint.visible = true
    combo_rule_hint.text = text
    combo_rule_hint.modulate = color
    combo_rule_hint.position = Vector2(-150.0, -138.0)

    combo_rule_hint_tween = create_tween()
    combo_rule_hint_tween.set_parallel(true)
    combo_rule_hint_tween.tween_property(combo_rule_hint, "modulate:a", color.a, 0.01)
    combo_rule_hint_tween.tween_property(combo_rule_hint, "position:y", -154.0, 0.22)
    combo_rule_hint_tween.tween_property(combo_rule_hint, "modulate:a", 0.0, 0.3).set_delay(0.75)
    combo_rule_hint_tween.finished.connect(func() -> void:
        if is_instance_valid(combo_rule_hint):
            combo_rule_hint.visible = false
    )


func _is_pressing_down() -> bool:
    var pressing_down: bool = Input.is_action_pressed("ui_down")
    if InputMap.has_action("move_down") and Input.is_action_pressed("move_down"):
        pressing_down = true
    if Input.is_key_pressed(KEY_S):
        pressing_down = true
    return pressing_down


func _start_drop_through() -> void:
    if not _has_drop_space(drop_through_distance):
        return

    var initial_down_speed: float = maxf(velocity.y, drop_initial_speed)
    var gravity_for_estimate: float = _get_current_fall_gravity()
    var estimated_time: float = _estimate_fall_time(drop_through_distance, initial_down_speed, gravity_for_estimate)

    is_dropping_through = true
    drop_neutral_world_x = global_position.x
    drop_start_y = global_position.y
    saved_floor_snap_length = floor_snap_length
    floor_snap_length = 0.0
    drop_through_time_left = maxf(drop_through_duration, estimated_time + 0.03)
    _update_collision_masks()
    position.y += drop_nudge_pixels
    velocity.y = initial_down_speed


func _update_drop_through_state(delta: float) -> void:
    if not is_dropping_through:
        return
    drop_through_time_left -= delta
    var traveled_down: float = global_position.y - drop_start_y
    if drop_through_time_left <= 0.0 or traveled_down >= drop_through_distance:
        is_dropping_through = false
        floor_snap_length = saved_floor_snap_length
        _update_collision_masks()
        drop_squeeze_time_left = drop_post_squeeze_duration


func _update_collision_masks() -> void:
    var a_layer_enabled: bool = not is_in_layer_b
    var b_layer_enabled: bool = is_in_layer_b

    if is_dropping_through:
        if is_in_layer_b:
            b_layer_enabled = false
        else:
            a_layer_enabled = false

    set_collision_mask_value(2, a_layer_enabled)
    set_collision_mask_value(3, b_layer_enabled)
    set_collision_mask_value(1, not is_dropping_through)


func _get_current_fall_gravity() -> float:
    var current_jump_height: float = b_jump_height if is_in_layer_b else a_jump_height
    var current_jump_desc: float = b_time_to_descent if is_in_layer_b else a_time_to_descent
    return (2.0 * current_jump_height) / (current_jump_desc * current_jump_desc)


func _estimate_fall_time(distance: float, initial_speed: float, gravity_value: float) -> float:
    if gravity_value <= 0.0:
        return 0.0
    var discriminant: float = (initial_speed * initial_speed) + (2.0 * gravity_value * distance)
    return maxf(0.0, (-initial_speed + sqrt(discriminant)) / gravity_value)


func _has_drop_space(distance: float) -> bool:
    var half_extents: Vector2 = _get_body_half_extents()
    var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
    # 下跳可行性只检测“当前维度的实心地形”，不把 one-way 平台层当阻挡
    var mask: int = 0
    if is_in_layer_b:
        mask |= (1 << 2) # Layer 3
    else:
        mask |= (1 << 1) # Layer 2

    # 脚底在世界坐标中的 Y（碰撞体中心 + 半身高），避免射线起点落在脚下同一块 32px 砖内部导致误红
    var feet_y: float = body_collision.global_position.y + half_extents.y
    var gap_y: float = feet_y + distance + 2.0
    var left_x: float = global_position.x - (half_extents.x * 0.6)
    var mid_x: float = global_position.x
    var right_x: float = global_position.x + (half_extents.x * 0.6)

    debug_drop_left_hit = _is_solid_at_point(space_state, Vector2(left_x, gap_y), mask)
    debug_drop_mid_hit = _is_solid_at_point(space_state, Vector2(mid_x, gap_y), mask)
    debug_drop_right_hit = _is_solid_at_point(space_state, Vector2(right_x, gap_y), mask)

    var from_left: Vector2 = Vector2(left_x, gap_y)
    var to_left: Vector2 = Vector2(left_x, gap_y + distance)
    debug_drop_left_from = to_local(from_left)
    debug_drop_left_to = to_local(to_left)

    var from_mid: Vector2 = Vector2(mid_x, gap_y)
    var to_mid: Vector2 = Vector2(mid_x, gap_y + distance)
    debug_drop_mid_from = to_local(from_mid)
    debug_drop_mid_to = to_local(to_mid)

    var from_right: Vector2 = Vector2(right_x, gap_y)
    var to_right: Vector2 = Vector2(right_x, gap_y + distance)
    debug_drop_right_from = to_local(from_right)
    debug_drop_right_to = to_local(to_right)

    # 薄台：gap_y 已在第一块砖下方空隙，三点都空 -> 可下跳。厚砖：gap_y 仍在实心内 -> 至少一点有碰撞 -> 不可下跳
    debug_drop_allowed = not debug_drop_left_hit and not debug_drop_mid_hit and not debug_drop_right_hit
    debug_drop_box_center = to_local(Vector2(mid_x, gap_y))
    debug_drop_box_size = Vector2((right_x - left_x) * 1.1, 4.0)
    return debug_drop_allowed


func _is_solid_at_point(space_state: PhysicsDirectSpaceState2D, world_point: Vector2, mask: int) -> bool:
    var pqp: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
    pqp.position = world_point
    pqp.collision_mask = mask
    pqp.collide_with_areas = false
    pqp.collide_with_bodies = true
    pqp.exclude = [self.get_rid()]
    var hits: Array = space_state.intersect_point(pqp, 32)
    return not hits.is_empty()


func _get_body_half_extents() -> Vector2:
    if body_collision and body_collision.shape and body_collision.shape is RectangleShape2D:
        var rect: RectangleShape2D = body_collision.shape as RectangleShape2D
        return rect.size * 0.5
    return Vector2(16.0, 16.0)


func _draw() -> void:
    if not debug_drop_probe:
        return

    var probe_color: Color = Color(0.2, 1.0, 0.4, 0.95) if debug_drop_allowed else Color(1.0, 0.2, 0.2, 0.95)

    if debug_drop_left_from != Vector2.ZERO or debug_drop_left_to != Vector2.ZERO:
        draw_line(debug_drop_left_from, debug_drop_left_to, probe_color, 2.0)

    if debug_drop_right_from != Vector2.ZERO or debug_drop_right_to != Vector2.ZERO:
        draw_line(debug_drop_right_from, debug_drop_right_to, probe_color, 2.0)

    if debug_drop_mid_from != Vector2.ZERO or debug_drop_mid_to != Vector2.ZERO:
        draw_line(debug_drop_mid_from, debug_drop_mid_to, probe_color, 2.0)

    if debug_drop_box_size != Vector2.ZERO:
        var rect_position: Vector2 = debug_drop_box_center - (debug_drop_box_size * 0.5)
        draw_rect(Rect2(rect_position, debug_drop_box_size), Color(probe_color.r, probe_color.g, probe_color.b, 0.15), true)
        draw_rect(Rect2(rect_position, debug_drop_box_size), probe_color, false, 1.0)
