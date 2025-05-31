#res://scene-scripts/building_manager.gd
extends Node2D
class_name BuildingManager

## 建筑管理器
## 负责管理游戏中所有建筑的实例，处理建筑的放置、生产和资源管理
##
## 主要功能：
## 1. 建筑实例管理：创建、放置和删除建筑
## 2. 生产系统：处理建筑的资源消耗和产出
## 3. 资源管理：处理建筑的资源存储和传输

# 预加载建筑配置脚本
@onready var building_initializer = preload("res://resoures/cell_type/building.gd").new()

# 存储所有已定义的建筑类型
var building_types := {}

# 存储所有已放置的建筑实例
var buildings := {}

#region 信号定义

## 当建筑完成一次生产时发出
## building_id: 建筑的唯一标识符
## outputs: 生产出的资源及其数量
signal production_completed(building_id: String, outputs: Dictionary)

## 当建筑消耗资源时发出
## building_id: 建筑的唯一标识符
## inputs: 消耗的资源及其数量
signal resource_consumed(building_id: String, inputs: Dictionary)

## 当建筑的存储状态更新时发出
## building_id: 建筑的唯一标识符
## storage_type: 存储类型（"input"或"output"）
## resources: 更新后的资源存储状态
signal storage_updated(building_id: String, storage_type: String, resources: Dictionary)

#endregion

#region 生命周期函数

func _ready():
	# 初始化建筑类型
	building_initializer.setup_grid(self)

func _process(delta):
	# 更新所有建筑的生产进度
	for building_id in buildings:
		update_building_production(building_id, delta)

#endregion

#region 建筑类型管理

## 定义新的建筑类型
## 参数：
## - type_name: 建筑类型的唯一标识符
## - info: 建筑类型的配置信息
func define_building_type(type_name: String, info: Dictionary) -> void:
	building_types[type_name] = info

#endregion

#region 建筑实例管理

## 在指定位置放置建筑
## 参数：
## - type_name: 要放置的建筑类型名称
## - coord: 建筑放置的起始坐标（左上角）
## 返回：建筑的唯一标识符，如果放置失败则返回空字符串
func place_building(type_name: String, coord: Vector2i) -> String:
	# 检查建筑类型是否存在
	if not building_types.has(type_name):
		push_error("Unknown building type: " + type_name)
		return ""

	# 获取建筑配置并生成唯一ID
	var info = building_types[type_name]
	var building_id = _generate_building_id()
	
	# 创建建筑实例
	var building_instance = {
		"id": building_id,
		"type": type_name,
		"coord": coord,
		"config": info.duplicate(true),
		"current_health": info.get("health", 100),
		"production_progress": 0.0,
		"input_storage": {},
		"output_storage": {},
		"is_working": false
	}

	# 初始化存储空间
	if info.has("production"):
		for resource in info.production.get("inputs", {}):
			building_instance.input_storage[resource] = 0
		for resource in info.production.get("outputs", {}):
			building_instance.output_storage[resource] = 0

	# 保存建筑实例
	buildings[building_id] = building_instance
	
	# 在网格中填充建筑区域
	var size = info.get("size", Vector2(1, 1))
	for x in range(size.x):
		for y in range(size.y):
			var cell_coord = coord + Vector2i(x, y)
			_add_building_to_grid(cell_coord, building_id, info)
	
	return building_id

## 获取建筑信息
## 参数：
## - building_id: 建筑的唯一标识符
## 返回：建筑的完整信息，如果建筑不存在则返回空字典
func get_building_info(building_id: String) -> Dictionary:
	return buildings.get(building_id, {})

#endregion

#region 生产系统

## 更新建筑的生产状态
## 参数：
## - building_id: 建筑的唯一标识符
## - delta: 距离上次更新的时间间隔（秒）
func update_building_production(building_id: String, delta: float) -> void:
	var building = buildings.get(building_id)
	if not building or not building.config.has("production"):
		return

	# 检查是否可以进行生产
	if not can_produce(building_id):
		building.is_working = false
		return

	# 更新生产进度
	building.is_working = true
	building.production_progress += delta
	
	# 检查是否完成一个生产周期
	if building.production_progress >= building.config.production.time:
		building.production_progress = 0
		_consume_inputs(building_id)
		_produce_outputs(building_id)

## 检查建筑是否可以进行生产
## 参数：
## - building_id: 建筑的唯一标识符
## 返回：如果可以生产则返回true，否则返回false
func can_produce(building_id: String) -> bool:
	var building = buildings.get(building_id)
	if not building or not building.config.has("production"):
		return false

	# 检查输入资源是否足够
	var inputs = building.config.production.inputs
	for resource in inputs:
		if building.input_storage.get(resource, 0) < inputs[resource]:
			return false
			
	# 检查输出缓冲区是否有足够空间
	var outputs = building.config.production.outputs
	var storage_capacity = building.config.storage_capacity.output_buffer
	for resource in outputs:
		if building.output_storage.get(resource, 0) + outputs[resource] > storage_capacity:
			return false
			
	return true

#endregion

#region 资源管理

## 向建筑的输入存储添加资源
## 参数：
## - building_id: 建筑的唯一标识符
## - resource: 资源类型
## - amount: 要添加的资源数量
## 返回：实际添加的资源数量
func add_input_resource(building_id: String, resource: String, amount: int) -> int:
	var building = buildings.get(building_id)
	if not building:
		return 0

	# 计算可以添加的资源数量
	var storage_capacity = building.config.storage_capacity.input_buffer
	var current_amount = building.input_storage.get(resource, 0)
	var space_available = storage_capacity - current_amount
	var amount_to_add = min(amount, space_available)

	# 更新存储状态
	if amount_to_add > 0:
		building.input_storage[resource] = current_amount + amount_to_add
		emit_signal("storage_updated", building_id, "input", building.input_storage)

	return amount_to_add

## 从建筑的输出存储移除资源
## 参数：
## - building_id: 建筑的唯一标识符
## - resource: 资源类型
## - amount: 要移除的资源数量
## 返回：实际移除的资源数量
func remove_output_resource(building_id: String, resource: String, amount: int) -> int:
	var building = buildings.get(building_id)
	if not building:
		return 0

	# 计算可以移除的资源数量
	var current_amount = building.output_storage.get(resource, 0)
	var amount_to_remove = min(amount, current_amount)

	# 更新存储状态
	if amount_to_remove > 0:
		building.output_storage[resource] = current_amount - amount_to_remove
		emit_signal("storage_updated", building_id, "output", building.output_storage)

	return amount_to_remove

#endregion

#region 内部辅助方法

## 生成唯一的建筑ID
func _generate_building_id() -> String:
	return str(randi()) + "_" + str(Time.get_ticks_msec())

## 将建筑添加到网格系统
func _add_building_to_grid(coord: Vector2i, building_id: String, info: Dictionary) -> void:
	# TODO: 实现具体的网格系统集成
	print("添加建筑到网格：", coord, building_id)

## 消耗建筑的输入资源
func _consume_inputs(building_id: String) -> void:
	var building = buildings.get(building_id)
	if not building:
		return

	# 消耗配置中指定的输入资源
	var inputs = building.config.production.inputs
	for resource in inputs:
		building.input_storage[resource] -= inputs[resource]
	
	# 发出资源消耗信号
	emit_signal("resource_consumed", building_id, inputs)
	emit_signal("storage_updated", building_id, "input", building.input_storage)

## 生产建筑的输出资源
func _produce_outputs(building_id: String) -> void:
	var building = buildings.get(building_id)
	if not building:
		return

	# 生产配置中指定的输出资源
	var outputs = building.config.production.outputs
	for resource in outputs:
		building.output_storage[resource] = min(
			building.output_storage.get(resource, 0) + outputs[resource],
			building.config.storage_capacity.output_buffer
		)
	
	# 发出生产完成信号
	emit_signal("production_completed", building_id, outputs)
	emit_signal("storage_updated", building_id, "output", building.output_storage)

#endregion
