extends Area2D

@export var speed: float = 900.0
@export var damage: int = 100
@export var knockback_force: float = 280.0
var direction: float = 1.0
var is_wind_path: bool = false
var life_timer: Timer
var wind_current_length: float = 0.0

const WIND_MAX_LENGTH: float = 160.0
const WIND_HEIGHT: float = 64.0
const WIND_GROW_SPEED: float = 520.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

func _ready() -> void:
    add_to_group("cross_layer_objects")
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)
    area_entered.connect(_on_area_entered)
    if not screen_notifier.screen_exited.is_connected(_on_screen_exited):
        screen_notifier.screen_exited.connect(_on_screen_exited)
    life_timer = Timer.new()
    life_timer.one_shot = true
    life_timer.wait_time = 2.0
    add_child(life_timer)
    life_timer.timeout.connect(_on_life_timeout)
    life_timer.start()


func _physics_process(delta: float) -> void:
    if is_wind_path:
        wind_current_length = move_toward(wind_current_length, WIND_MAX_LENGTH, WIND_GROW_SPEED * delta)
        _update_wind_geometry()
        return

    global_position.x += direction * speed * delta


func _on_life_timeout() -> void:
    queue_free()


func _on_screen_exited() -> void:
    queue_free()


func _on_body_entered(body: Node) -> void:
    if is_wind_path:
        if body.has_method("apply_wind_buff"):
            body.apply_wind_buff(true)
        return
    queue_free()


func _on_body_exited(body: Node) -> void:
    if is_wind_path and body.has_method("apply_wind_buff"):
        body.apply_wind_buff(false)


func _on_area_entered(area: Area2D) -> void:
    if is_wind_path:
        return

    if area.name == "Hurtbox":
        var target: Node = area.get_parent()
        if target and target.has_method("take_damage"):
            var args: Array = [damage, direction, knockback_force]
            var expected_arg_count: int = 1

            for method_info in target.get_method_list():
                if method_info.name == "take_damage":
                    expected_arg_count = method_info.args.size()
                    break

            target.callv("take_damage", args.slice(0, expected_arg_count))
        queue_free()


func on_dimension_switched(in_b_layer: bool) -> void:
    if in_b_layer and not is_wind_path:
        is_wind_path = true
        speed = 0.0
        damage = 0

        set_collision_mask_value(1, true)
        set_collision_mask_value(4, false)

        # 风道视觉初始化：淡青色 + 流动感材质
        sprite.modulate = Color(0.76, 0.99, 1.0, 0.08)
        sprite.material = _create_wind_material()
        sprite.flip_h = direction < 0
        wind_current_length = 12.0
        _update_wind_geometry()

        if life_timer:
            life_timer.stop()
            life_timer.wait_time = 5.0
            life_timer.start()


func _update_wind_geometry() -> void:
    if sprite.texture == null:
        return

    var texture_size: Vector2 = sprite.texture.get_size()
    if texture_size.x <= 0.0 or texture_size.y <= 0.0:
        return

    sprite.scale.x = wind_current_length / texture_size.x
    sprite.scale.y = WIND_HEIGHT / texture_size.y
    sprite.position.x = direction * (wind_current_length * 0.5)

    var wind_shape: RectangleShape2D = RectangleShape2D.new()
    wind_shape.size = Vector2(wind_current_length, WIND_HEIGHT)
    collision_shape.shape = wind_shape
    collision_shape.position.x = direction * (wind_current_length * 0.5)
    collision_shape.position.y = 0.0


func _create_wind_material() -> ShaderMaterial:
    var shader: Shader = Shader.new()
    shader.code = "shader_type canvas_item;\n" \
        + "render_mode blend_mix, unshaded;\n" \
        + "uniform vec4 tint_color : source_color = vec4(0.60, 0.90, 1.0, 1.0);\n" \
        + "uniform float flow_speed = 1.9;\n" \
        + "uniform float jitter_strength = 0.016;\n" \
        + "float hash21(vec2 p) {\n" \
        + "    p = fract(p * vec2(123.34, 345.45));\n" \
        + "    p += dot(p, p + 34.345);\n" \
        + "    return fract(p.x * p.y);\n" \
        + "}\n" \
        + "void fragment() {\n" \
        + "    vec2 uv = UV;\n" \
        + "    float jitter_a = sin((uv.y * 20.0) + (TIME * 2.4));\n" \
        + "    float jitter_b = sin((uv.y * 47.0) - (TIME * 3.1));\n" \
        + "    uv.x += (jitter_a + jitter_b) * jitter_strength;\n" \
        + "    vec2 p = (uv - vec2(0.5)) * vec2(2.0, 2.0);\n" \
        + "    float body_mask = 1.0 - smoothstep(0.42, 0.98, abs(p.y));\n" \
        + "    float head_fade = smoothstep(-1.0, -0.78, p.x) * smoothstep(1.0, 0.72, p.x);\n" \
        + "    float edge_noise = hash21(vec2(floor(uv.x * 32.0), floor(uv.y * 14.0) + floor(TIME * 8.0)));\n" \
        + "    float noisy_cut = smoothstep(0.06, 0.96, body_mask - ((edge_noise - 0.5) * 0.22));\n" \
        + "    float mask = head_fade * noisy_cut;\n" \
        + "    float stream_a = sin((uv.x * 18.0) - (TIME * 7.5 * flow_speed) + (uv.y * 8.0));\n" \
        + "    float stream_b = sin((uv.x * 33.0) + (TIME * 5.4 * flow_speed) - (uv.y * 14.0));\n" \
        + "    float stream_c = sin((uv.x * 9.0) - (TIME * 4.2) + (uv.y * 26.0));\n" \
        + "    float flow = (stream_a * 0.45) + (stream_b * 0.35) + (stream_c * 0.20);\n" \
        + "    float alpha = (0.018 + (flow * 0.014)) * mask;\n" \
        + "    alpha = clamp(alpha, 0.0, 0.038);\n" \
        + "    if (alpha < 0.003) {\n" \
        + "        discard;\n" \
        + "    }\n" \
        + "    COLOR = vec4(tint_color.rgb, alpha);\n" \
        + "}\n"
    var material: ShaderMaterial = ShaderMaterial.new()
    material.shader = shader
    return material
