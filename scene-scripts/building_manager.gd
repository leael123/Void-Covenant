#res://scene-scripts/building_manager.gd
extends Node2D
class_name BuildingManager

@onready var building_initializer = preload("res://resoures/cell_type/building.gd").new()

# 存储所有建筑类型
var building_types := {}

func _ready():
	# 初始化建筑类型
	building_initializer.setup_grid(self)

# 定义新建筑类型
# type_name: 建筑类型名称
# info: 包含贴图路径、高度、大小等信息
func define_building_type(type_name: String, info: Dictionary) -> void:
	building_types[type_name] = info

# 放置建筑
# type_name: 建筑类型名称
# coord: 起始坐标（左上角）
func place_building(type_name: String, coord: Vector2i):
	if not building_types.has(type_name):
		push_error("Unknown building type: " + type_name)
		return

	var info = building_types[type_name]
	var size = info.get("size", Vector2(1, 1))  # 默认大小为 1x1
	var texture = info.get("texture", "")
	var height = info.get("height", 0)

	# 填充建筑区域
	for x in range(size.x):
		for y in range(size.y):
			var cell_coord = coord + Vector2i(x, y)
			_add_building({
				"coord": cell_coord,
				"texture": texture,
				"height": height,
				"tag": type_name
			})

# 内部方法，添加建筑到地图
func _add_building(data: Dictionary):
	# 示例：输出数据以验证添加逻辑
	print("添加建筑：", data)
