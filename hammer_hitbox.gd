extends Area2D

@export var damage: int = 50       
@export var knockback_force: float = 600.0 

func _on_area_entered(area: Area2D) -> void:
    # 只要有任何 Area2D 碰到大锤，都会先打印这句话！
    print("【测试】大锤判定框开启，碰到了东西：", area.name) 
    
    if area.name == "Hurtbox":
        # 稳妥起见，直接用 get_parent() 获取沙包根节点
        var enemy = area.get_parent() 
        
        if enemy.has_method("take_damage"):
            print("【测试】确认目标是沙包，准备执行击退！")
            
            # 简化方向判断：沙包的X坐标 减去 大锤的X坐标
            var dir = sign(enemy.global_position.x - global_position.x)
            if dir == 0: dir = 1
            
            enemy.take_damage(damage, dir, knockback_force)
        else:
            print("【测试】错误：碰到了Hurtbox，但它的父节点没有 take_damage 函数！")
            
            
func _physics_process(delta: float) -> void:
    # 如果碰撞框没有被禁用（也就是砸在地上的那一瞬间）
    if not $CollisionShape2D.disabled:
        # 主动获取当前与大锤重叠的所有 Area2D
        var areas = get_overlapping_areas()
        print("【强制扫描】大锤开启！当前重叠的区域数量: ", areas.size())
        
        for a in areas:
            print(" ---- 重叠的区域名字是: ", a.name)
