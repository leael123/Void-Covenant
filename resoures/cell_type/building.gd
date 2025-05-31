#res://resoures/cell_type/building.gd
extends Node2D

## 建筑系统配置文件
## 本文件用于定义建筑类型和基础配置，实际的执行逻辑在 building_manager.gd 中实现
##
## 建筑配置示例：
## grid_manager.define_building_type("building_name", {
##     # 1. 基础属性 - 建筑的基本信息
##     "texture": "",              # 建筑的贴图路径
##     "height": 3,               # 建筑的高度值，用于通行判定
##     "size": Vector2(3, 3),     # 建筑占用的网格大小
##     "health": 100,             # 建筑的生命值
##     
##     # 2. 生产配置 - 建筑的生产相关参数
##     "production": {
##         "inputs": {            # 生产所需的输入资源
##             "copper_ore": 1,   # 资源ID: 数量
##             "power": 10        # 例如：需要1个铜矿和10点电力
##         },
##         "outputs": {           # 生产产出的资源
##             "copper_ingot": 1  # 例如：产出1个铜锭
##         },
##         "time": 10,           # 生产周期（秒）
##         "power_required": 10,  # 持续运行所需的电力
##     },
##     
##     # 3. 建筑特性 - 建筑的功能特性
##     "building_type": "factory",    # 建筑类型（工厂/存储/发电等）
##     "storage_capacity": {          # 存储容量配置
##         "input_buffer": 10,        # 输入资源缓冲区大小
##         "output_buffer": 10        # 输出资源缓冲区大小
##     }
## })

## 资源类型枚举
## 用于定义游戏中所有可用的资源类型
enum ResourceType {
	COPPER_ORE,    # 铜矿石
	IRON_ORE,      # 铁矿石
	COPPER_INGOT,  # 铜锭
	IRON_INGOT,    # 铁锭
	POWER          # 电力
}

## 建筑类型枚举
## 用于定义不同类型的建筑及其基本功能
enum BuildingType {
	FACTORY,     # 工厂类建筑 - 用于加工资源
	STORAGE,     # 存储类建筑 - 用于存储资源
	POWER_PLANT, # 发电类建筑 - 用于生产电力
	MINER        # 采矿类建筑 - 用于开采原始资源
}

## 初始化函数，用于设置建筑类型
## 参数 grid_manager: 网格管理器实例，用于注册建筑类型
func setup_grid(grid_manager):
	# 示例：铜矿熔炉配置
	# 这是一个将铜矿石转换为铜锭的基础工厂建筑
	grid_manager.define_building_type("copper_smelter", {
		# 基础属性
		"texture": "res://textures/buildings/copper_smelter.png",
		"height": 3,
		"size": Vector2(3, 3),
		"health": 100,
		
		# 建筑类型
		"building_type": "factory",
		
		# 生产配置
		"production": {
			"inputs": {
				"copper_ore": 1,  # 消耗1个铜矿石
				"power": 10       # 消耗10点电力
			},
			"outputs": {
				"copper_ingot": 1 # 产出1个铜锭
			},
			"time": 10,          # 生产周期10秒
			"power_required": 10  # 需要持续供电10点
		},
		
		# 存储配置
		"storage_capacity": {
			"input_buffer": 10,   # 最多存储10个单位的输入资源
			"output_buffer": 10   # 最多存储10个单位的输出资源
		}
	})
	
	# 在这里可以继续添加更多建筑类型的定义
	# 例如：铁矿熔炉、发电厂、采矿机等
