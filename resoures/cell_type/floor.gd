#res://resoures/cell_type/floor.gd
extends Node2D

## 地面类型定义
## 本文件用于定义游戏中所有的地面类型，包括：
## 1. 不同类型的平原地面
## 2. 地形高度设置
## 3. 地面纹理配置
##
## 地面配置示例：
## grid_manager.define_cell_type("plain_1", {
##     "texture": "res://textures/floor/floor1.png",  # 地面纹理路径
##     "height": 0                                    # 地形高度
## })

#region 地面类型枚举
## 用于定义所有可用的地面类型
enum FloorType {
	PLAIN_1,    # 平原地面1
	PLAIN_2,    # 平原地面2
	PLAIN_3,    # 平原地面3
	PLAIN_4,    # 平原地面4
	PLAIN_5,    # 平原地面5
	PLAIN_6     # 平原地面6
}
#endregion

## 初始化地面类型
## 参数：
## - grid_manager: 网格管理器实例
func setup_grid(grid_manager: GridManager) -> void:
	# 平原地面1
	grid_manager.define_cell_type("plain_1", {
		"texture": "res://textures/floor/floor1.png",
		"height": 0,
		"type": FloorType.PLAIN_1,
		"passable": true,
		"description": "基础平原地形"
	})

	# 平原地面2
	grid_manager.define_cell_type("plain_2", {
		"texture": "res://textures/floor/floor2.png",
		"height": 0,
		"type": FloorType.PLAIN_2,
		"passable": true,
		"description": "草地平原地形"
	})

	# 平原地面3
	grid_manager.define_cell_type("plain_3", {
		"texture": "res://textures/floor/floor3.png",
		"height": 0,
		"type": FloorType.PLAIN_3,
		"passable": true,
		"description": "沙质平原地形"
	})

	# 平原地面4
	grid_manager.define_cell_type("plain_4", {
		"texture": "res://textures/floor/floor4.png",
		"height": 0,
		"type": FloorType.PLAIN_4,
		"passable": true,
		"description": "岩石平原地形"
	})

	# 平原地面5
	grid_manager.define_cell_type("plain_5", {
		"texture": "res://textures/floor/floor5.png",
		"height": 0,
		"type": FloorType.PLAIN_5,
		"passable": true,
		"description": "雪地平原地形"
	})

	# 平原地面6
	grid_manager.define_cell_type("plain_6", {
		"texture": "res://textures/floor/floor6.png",
		"height": 0,
		"type": FloorType.PLAIN_6,
		"passable": true,
		"description": "荒漠平原地形"
	})
