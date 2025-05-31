#res://scene-scripts/grid_manager.gd
extends Node2D
class_name GridManager

## 网格管理器
## 负责管理游戏世界的网格系统，包括：
## 1. 网格单元格的创建和管理
## 2. 网格类型的定义和存储
## 3. 纹理资源的缓存和管理
## 4. 寻路和可通行性判断

#region 信号
## 当单元格加载完成时发出
signal cell_loaded(cell: GridCell)

## 当单元格被卸载时发出
signal cell_unloaded(cell: GridCell)
#endregion

#region 导出变量
## TileMap节点引用，用于显示网格
@export var tilemap: TileMap

## 网格配置
@export var config: GridConfig

## 单元格场景
@export var cell_scene: PackedScene
#endregion

#region 预加载资源
## 网格初始化器
@onready var grid_initializer = preload("res://resoures/cell_type/floor.gd").new()
#endregion

#region 私有变量
## 当前激活的单元格
var _active_cells := {}

## 单元格类型模板数据
## 存储所有已定义的单元格类型（如草地、山地、水域等）
var cell_types := {}

## 纹理资源缓存
var _texture_cache := {}

## 纹理缓存互斥锁
var _texture_cache_mutex := Mutex.new()
#endregion

#region 生命周期函数
func _ready():
	grid_initializer.setup_grid(self)
#endregion

#region 网格类型管理

## 定义新的网格类型
## 参数：
## - type_name: 类型名称（如"grass"、"mountain"等）
## - info: 类型信息（包含贴图路径、高度值等属性）
func define_cell_type(type_name: String, info: Dictionary) -> void:
	cell_types[type_name] = info

## 放置指定类型的单元格
## 参数：
## - type_name: 单元格类型名称
## - coord: 目标坐标
func place_cell(type_name: String, coord: Vector2i) -> void:
	if not cell_types.has(type_name):
		push_error("未知的单元格类型: " + type_name)
		return

	var info = cell_types[type_name]
	add_cell({
		"coord": coord,
		"texture": info.get("texture", ""),
		"height": info.get("height", 0),
		"tag": type_name
	})

## 添加单元格到网格
## 参数：
## - data: 单元格数据
func add_cell(data: Dictionary) -> void:
	# TODO: 实现实际的单元格添加逻辑
	print("添加单元格：", data)
#endregion

#region 寻路和可通行性

## 检查指定坐标的单元格是否可通行
## 参数：
## - unit_height: 单位的高度值
## - coord: 要检查的坐标
## 返回：如果单位可以通过该单元格则返回true
func is_cell_passable(unit_height: int, coord: Vector2i) -> bool:
	for cell_data in _active_cells.values():
		if cell_data["coord"] == coord:
			return unit_height >= cell_data["height"]
	return false
#endregion

#region 单元格加载管理

## 加载指定类型的单元格到指定坐标
## 参数：
## - coord: 目标坐标
## - cell_type: 单元格类型
func load_cell(coord: Vector2i, cell_type: String) -> void:
	if not cell_types.has(cell_type):
		push_error("未知的单元格类型: %s" % cell_type)
		return

	var cell_info = cell_types[cell_type]
	var texture = _load_texture_safe(cell_info.texture)
	if texture:
		# 在TileMap中设置单元格
		# 参数说明：
		# - layer: 图层索引（0为默认图层）
		# - coords: 目标坐标（Vector2i类型）
		# - source_id: 瓦片集的源ID
		# - atlas_coords: 瓦片在瓦片集中的坐标
		# - alternative_tile: 替代瓦片ID
		tilemap.set_cell(
			0,                  # layer
			coord,             # coordinates
			0,                 # source_id
			Vector2i.ZERO      # atlas_coords
		)

		# 创建并配置单元格实例
		var cell_instance = {
			"coord": coord,
			"type": cell_type,
			"height": cell_info.get("height", 0),
			"texture": texture
		}
		_active_cells[coord] = cell_instance
		
		# 发出单元格加载信号
		emit_signal("cell_loaded", cell_instance)
#endregion

#region 纹理资源管理

## 线程安全地加载纹理
## 参数：
## - path: 纹理文件路径
## 返回：加载的纹理资源，如果加载失败则返回默认纹理
func _load_texture_safe(path: String) -> Texture2D:
	# 处理空路径
	if path.is_empty():
		return _create_default_texture()
	
	# 加锁访问缓存
	_texture_cache_mutex.lock()
	
	# 检查缓存
	if _texture_cache.has(path):
		var cached_texture = _texture_cache[path]
		_texture_cache_mutex.unlock()
		return cached_texture
	
	# 验证文件存在性
	if not ResourceLoader.exists(path):
		push_error("纹理资源不存在: %s" % path)
		_texture_cache_mutex.unlock()
		return _create_default_texture()
	
	# 加载并缓存纹理
	var texture = load(path)
	if texture is Texture2D:
		_texture_cache[path] = texture
		print("已缓存新纹理: ", path)
	else:
		push_error("无效的纹理格式: ", path)
		texture = _create_default_texture()
	
	_texture_cache_mutex.unlock()
	return texture

## 创建默认纹理
## 返回：一个2x2的紫色默认纹理
func _create_default_texture() -> Texture2D:
	var image = Image.new()
	image.create(2, 2, false, Image.FORMAT_RGBA8)
	image.fill(Color(1, 0, 1))  # 紫色表示缺失纹理
	
	var texture = ImageTexture.create_from_image(image)
	return texture
#endregion
