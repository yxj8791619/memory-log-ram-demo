extends CharacterBody2D

signal layer_switched(is_in_b_layer: bool)

var is_in_layer_b: bool = false

@onready var anim_tree: AnimationTree = $AnimationTree
@onready var state_machine = anim_tree.get("parameters/playback")
@onready var sprite: Sprite2D = $DirectionPivot/Sprite2D

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
    set_collision_mask_value(2, true)  # 开启与 A层 的碰撞
    set_collision_mask_value(3, false) # 关闭与 B层 的碰撞

func _physics_process(delta: float) -> void:
    # 0. 提前获取当前动画状态
    var current_anim = state_machine.get_current_node()

    # 1. 检测 TAB 键切换
    if Input.is_action_just_pressed("switch_layer"):
        toggle_dimension()

    # 2. 动态获取当前的物理参数
    var current_speed = b_run_speed if is_in_layer_b else a_run_speed
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
        velocity.y = final_jump_velocity

    # 6. 处理移动
    var direction := Input.get_axis("move_left", "move_right")
    if direction != 0:
        velocity.x = move_toward(velocity.x, direction * final_speed, current_accel * delta)
    else:
        velocity.x = move_toward(velocity.x, 0, current_frict * delta)

    move_and_slide()

    # ================= 动画与面朝向控制 =================
    

    # 7. 只有不在抡锤状态下，才允许角色转身
    if current_anim != "b_hammer":
        if direction < 0:
            direction_pivot.scale.x = -1 # 整个枢纽向左翻转
        elif direction > 0:
            direction_pivot.scale.x = 1  # 整个枢纽向右
            
    # 8. 触发攻击
    if Input.is_action_just_pressed("attack"):
        if is_in_layer_b:
            state_machine.travel("b_hammer")
        else:
            state_machine.travel("a_shoot")
            
    # 9. 状态恢复 (不在攻击时，才切换跑和待机)
    elif current_anim != "a_shoot" and current_anim != "b_hammer":
        if is_on_floor():
            if direction != 0:
                state_machine.travel("run")
            else:
                state_machine.travel("idle")

# --- 切换维度的具体逻辑 ---
func toggle_dimension():
    is_in_layer_b = !is_in_layer_b
    set_collision_mask_value(2, !is_in_layer_b)
    set_collision_mask_value(3, is_in_layer_b)
    layer_switched.emit(is_in_layer_b)
