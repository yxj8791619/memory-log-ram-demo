extends CharacterBody2D

var gravity = 980.0
var health = 100

func _physics_process(delta):
    # 简单的重力和摩擦力（让它被击退后能停下来）
    if not is_on_floor():
        velocity.y += gravity * delta
    else:
        velocity.x = move_toward(velocity.x, 0, 1500 * delta) # 地面摩擦力刹车
        
    move_and_slide()

# 挨揍的核心函数！外界（大锤）会调用这个函数
func take_damage(amount: int, knockback_dir: float, force: float):
    health -= amount
    print("沙包挨揍了！受到伤害: ", amount, " 剩余血量: ", health)
    
    # 极其带感的击退效果：给一个水平方向的巨力，并且稍微挑飞一点点！
    velocity.x = knockback_dir * force
    velocity.y = -200 
    
    # 变白闪烁效果 (Hit Flash)
    modulate = Color(10, 10, 10, 1) # 瞬间过曝变白
    await get_tree().create_timer(0.1).timeout
    modulate = Color(1, 1, 1, 1)    # 恢复红色
    
    if health <= 0:
        print("沙包被锤爆了！")
        queue_free() # 死亡销毁
