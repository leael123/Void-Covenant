#res://scene-scripts/grid_manager.gd
extends Node2D
class_name GridManager

signal cell_loaded(cell: GridCell)  # 单元格加载完成时触发
signal cell_unloaded(cell: GridCell)  # 单元格卸载时触发

@onready var grid_initializer = preload("res://resoures/cell_type/floor.gd").new()

@export var tilemap: TileMap
@export var config: GridConfig
@export var cell_scene: PackedScene
var _active_cells := {}

# 存储所有格子类型的模板数据，例如草地、山地、水域等
var cell_types := {}

func _ready():
	grid_initializer.setup_grid(self)

# 定义新格子类型（只需写一次）
# name：类型名称，例如 "grass"
# info：包含贴图路径、高度值等
func define_cell_type(type_name: String, info: Dictionary) -> void:
	cell_types[type_name] = info

# 放置单元格
# type_name: 格子类型名称
# coord: 坐标
func place_cell(type_name: String, coord: Vector2i):
	if not cell_types.has(type_name):
		push_error("Unknown cell type: " + type_name)
		return

	var info = cell_types[type_name]

	add_cell({
		"coord": coord,
		"texture": info.get("texture", ""),
		"height": info.get("height", 0),  # 获取高度值
		"tag": type_name
	})

func add_cell(data: Dictionary):
	# 示例：输出数据以验证添加逻辑
	print("添加格子：", data)

# 判断某单元格是否可通行（根据高度值）
# unit_height: 单位的高度值
# coord: 检查的单元格坐标
func is_cell_passable(unit_height: int, coord: Vector2i) -> bool:
	for cell_data in _active_cells.values():
		if cell_data["coord"] == coord:
			return unit_height >= cell_data["height"]  # 单位高度是否足够通过
	return false

# 示例：在 GridManager 的单元格加载方法中
func load_cell(coord: Vector2i, cell_type: String) -> void:
	if not cell_types.has(cell_type):
		push_error("未知的格子类型: %s" % cell_type)
		return

	var texture = _texture_cache.get(cell_type, null)
	if not texture:
		texture = ResourceLoader.load(cell_types[cell_type].texture)
		_texture_cache[cell_type] = texture

	tilemap.set_cellv(coord, texture)  # 修复第 70 行错误：使用 set_cellv 而非 set_cell

# ---- 新增纹理缓存系统 ----
var _texture_cache := {}              # 纹理资源缓存 {路径: Texture2D}
var _texture_cache_mutex := Mutex.new() # 线程安全锁

#----------------------------------------
# 线程安全的纹理加载方法
#----------------------------------------
func _load_texture_safe(path: String) -> Texture2D:
	# 空路径直接返回默认纹理
	if path.is_empty():
		return _create_default_texture()  # 修复第 82 行和第 97 行错误：替换为 _create_default_texture
	
	# 加锁访问缓存
	_texture_cache_mutex.lock()
	
	# 缓存命中检测
	if _texture_cache.has(path):
		var cached_texture = _texture_cache[path]
		_texture_cache_mutex.unlock()
		return cached_texture
	
	# 文件存在性验证
	if not ResourceLoader.exists(path):
		push_error("纹理资源不存在: %s" % path)
		_texture_cache_mutex.unlock()
		return _create_default_texture()  # 替换为 _create_default_texture
	
	# 执行加载并缓存
	var texture = load(path)
	if texture is Texture2D:
		_texture_cache[path] = texture
		print("缓存新纹理: ", path)
	else:
		push_error("无效的纹理格式: ", path)

	return texture

# 创建默认纹理（替代 _get_default_texture）
func _create_default_texture() -> Texture2D:
	var image = Image.new()
	image.create(2, 2, false, Image.FORMAT_RGBA8)  # 修复调用静态函数 create 的问题
	image.fill(Color(1, 0, 1))  # 填充为紫色，表示默认纹理
	var texture = ImageTexture.new()
	ImageTexture.create_from_image(image)  # 修复静态函数调用：直接从 ImageTexture 类型调用
	return texture
