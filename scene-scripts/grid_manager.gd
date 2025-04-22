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
var _cell_pool := []
# 存储所有格子类型的模板数据，比如草地、山地、水域等
var cell_types := {}

func _ready():
	grid_initializer.setup_grid(self)

func place_cell(type_name: String, coord: Vector2i):
	if not cell_types.has(type_name):
		push_error("Unknown cell type: " + type_name)
		return

	var info = cell_types[type_name]

	add_cell({
		"coord": coord,
		"texture": info.get("texture", ""),
		"passable": info.get("passable", true),
		"tag": type_name
	})

func add_cell(data: Dictionary):
	# 示例：输出数据以验证添加逻辑
	print("添加格子：", data)

# 注册一种新的格子类型（只需写一次）
# name：类型名称，如 "grass"
# info：包含贴图路径、是否可通行等
func define_cell_type(type_name: String, info: Dictionary) -> void:
	cell_types[type_name] = info

# 示例：在 GridManager 的单元格加载方法中
func load_cell(coord: Vector2i, cell_type: String) -> void:
	if not cell_types.has(cell_type):
		push_error("未知的格子类型: %s" % cell_type)
		return

	var texture = _texture_cache.get(cell_type, null)
	if not texture:
		texture = ResourceLoader.load(cell_types[cell_type].texture)
		_texture_cache[cell_type] = texture

	tilemap.set_cell(coord.x, coord.y, texture)

# ---- 新增纹理缓存系统 ----
var _texture_cache := {}              # 纹理资源缓存 {路径: Texture2D}
var _texture_cache_mutex := Mutex.new() # 线程安全锁

#----------------------------------------
# 线程安全的纹理加载方法
#----------------------------------------
func _load_texture_safe(path: String) -> Texture2D:
	# 空路径直接返回默认纹理
	if path.is_empty():
		return _get_default_texture()
	
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
		return _get_default_texture()
	
	# 执行加载并缓存
	var texture = load(path)
	if texture is Texture2D:
		_texture_cache[path] = texture
		print("缓存新纹理: ", path)
	else:
		push_error("无效的纹理格式: ", path)
		texture = _get_default_texture()
	
	_texture_cache_mutex.unlock()
	return texture

#----------------------------------------
# 获取默认纹理（带自动生成）
#----------------------------------------
func _get_default_texture() -> Texture2D:
	if config.default_texture != null:
		return config.default_texture
	
	# 动态生成棋盘格纹理
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.8, 0.8, 0.8))
	
	# 绘制棋盘格
	for x in 8:
		for y in 8:
			var color = Color(0.6, 0.6, 0.6) if (x + y) % 2 == 0 else Color.WHITE
			img.set_pixel(x, y, color)
			img.set_pixel(x+8, y, color)
			img.set_pixel(x, y+8, color)
			img.set_pixel(x+8, y+8, color)
	
	config.default_texture = ImageTexture.create_from_image(img)
	return config.default_texture

#----------------------------------------
# 卸载单元格时的资源检查
#----------------------------------------
func _unload_cell(coord: Vector2i) -> void:
	var cell = _active_cells.get(coord)
	if not cell:
		return
	
	# 触发卸载信号
	emit_signal("cell_unloaded", cell)
	
	# 记录纹理路径
	var texture_path = cell.data.texture_path
	
	remove_child(cell)
	_cell_pool.append(cell)
	_active_cells.erase(coord)
	# 检查纹理引用
	_check_texture_reference(texture_path)

#----------------------------------------
# 纹理引用计数检查
#----------------------------------------
func _check_texture_reference(path: String) -> void:
	if path.is_empty():
		return
	
	_texture_cache_mutex.lock()
	
	# 统计当前引用
	var ref_count := 0
	for cell in _active_cells.values():
		if cell and cell.data.texture_path == path:
			ref_count += 1
	
	# 无引用时释放
	if ref_count == 0 and _texture_cache.has(path):
		_texture_cache.erase(path)
		print("释放纹理: ", path)
	
	_texture_cache_mutex.unlock()
