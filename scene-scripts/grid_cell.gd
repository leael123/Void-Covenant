#res://scene-scripts/grid_cell.gd
extends Area2D
class_name GridCell

## 网格单元格组件
## 提供网格中单个单元格的所有基础功能，包括：
## 1. 异步纹理加载和管理
## 2. 用户交互和输入处理
## 3. 自适应缩放和布局
## 4. 视觉反馈效果

#region 信号
## 当单元格被点击时发出
## coordinate: 被点击单元格的网格坐标
signal cell_clicked(coordinate: Vector2i)
#endregion

#region 导出变量
## 网格全局配置，必须在场景中设置
@export var config: GridConfig

## 单元格数据，在运行时动态注入
@export var data: CellData
#endregion

#region 节点引用
## 单元格的精灵节点，用于显示纹理
@onready var _sprite: Sprite2D = $Sprite2D

## 单元格的碰撞形状节点，用于检测输入
@onready var _collision: CollisionShape2D = $CollisionShape2D
#endregion

#region 私有变量
## 异步资源加载队列
var _resource_queue: Array[String] = []
#endregion

#region 生命周期函数
func _ready() -> void:
	_validate_dependencies()
	_initialize_collision()
	_load_initial_texture()
	_setup_input_listener()
#endregion

#region 公共接口

## 异步设置单元格纹理
## 参数：
## - path: 纹理文件的路径
func set_texture_async(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_error("纹理文件不存在: %s" % path)
		return
	_start_async_load(path)

## 重置单元格到初始状态
func reset() -> void:
	_sprite.texture = null
	data.texture_path = ""
	modulate = Color.WHITE
#endregion

#region 初始化辅助方法

## 验证必要的依赖项是否已正确配置
func _validate_dependencies() -> void:
	assert(config != null, "GridConfig 必须配置！")
	assert(data != null, "CellData 必须注入！")

## 初始化单元格的碰撞形状
func _initialize_collision() -> void:
	if _collision.shape == null:
		_collision.shape = RectangleShape2D.new()
	_collision.shape.size = config.cell_size
	_collision.position = config.cell_size / 2  # 中心对齐

## 加载初始纹理
func _load_initial_texture() -> void:
	if data.texture_path.is_empty():
		_apply_texture(config.default_texture)
		return
		
	if ResourceLoader.exists(data.texture_path):
		_apply_texture(load(data.texture_path))
	else:
		push_warning("初始纹理加载失败: %s" % data.texture_path)
		_apply_texture(config.default_texture)
#endregion

#region 纹理处理

## 调整纹理缩放以适应单元格大小
func _adjust_texture_scale() -> void:
	if not _sprite.texture:
		return
		
	var texture_size := _sprite.texture.get_size()
	var target_scale := config.cell_size / texture_size
	
	# 根据配置的缩放模式调整纹理大小
	match config.scale_mode:
		GridConfig.ScaleMode.FIT:
			var fit_scale = min(target_scale.x, target_scale.y)
			_sprite.scale = Vector2(fit_scale, fit_scale)
		GridConfig.ScaleMode.FILL:
			var fill_scale = max(target_scale.x, target_scale.y)
			_sprite.scale = Vector2(fill_scale, fill_scale)
		GridConfig.ScaleMode.STRETCH:
			_sprite.scale = target_scale
			
	# 确保纹理居中显示
	_sprite.position = (config.cell_size - texture_size * _sprite.scale) / 2

## 开始异步加载纹理
## 参数：
## - path: 纹理文件路径
func _start_async_load(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_error("纹理文件不存在: %s" % path)
		return
		
	var loader = ResourceLoader.load_threaded_request(path)
	if loader != OK:
		push_error("启动异步加载失败: %s" % path)
		return
		
	_resource_queue.append(path)
	_monitor_loading_status(path)  # 开始监控加载状态

## 监控纹理加载状态
## 参数：
## - path: 正在加载的纹理路径
func _monitor_loading_status(path: String) -> void:
	var timeout = 5.0  # 最大等待时间（秒）
	var timer = 0.0
	
	while timer < timeout:
		var status = ResourceLoader.load_threaded_get_status(path)
		match status:
			ResourceLoader.THREAD_LOAD_LOADED:
				_on_texture_loaded(path)
				return
			ResourceLoader.THREAD_LOAD_FAILED:
				push_error("异步加载失败: %s" % path)
				return
			_:
				await get_tree().process_frame
				timer += get_process_delta_time()
				
	push_error("加载超时: %s" % path)

## 处理纹理加载完成事件
## 参数：
## - path: 加载完成的纹理路径
func _on_texture_loaded(path: String) -> void:
	var texture = ResourceLoader.load_threaded_get(path)
	if texture is Texture2D:
		_apply_texture(texture)
	else:
		push_error("无效的纹理资源: %s" % path)
		_apply_texture(config.default_texture)

## 应用纹理到精灵节点
## 参数：
## - texture: 要应用的纹理
func _apply_texture(texture: Texture2D) -> void:
	_sprite.texture = texture if texture else config.default_texture
	_adjust_texture_scale()
#endregion

#region 输入处理

## 设置输入事件监听器
func _setup_input_listener() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)

## 处理输入事件
func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton \
		and event.pressed \
		and event.button_index == MOUSE_BUTTON_LEFT:
			emit_signal("cell_clicked", data.coordinate)

## 处理鼠标进入事件
func _on_mouse_entered() -> void:
	create_tween().tween_property(self, "modulate", Color(1.2, 1.2, 1.2), 0.1)

## 处理鼠标离开事件
func _on_mouse_exited() -> void:
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.2)
#endregion
