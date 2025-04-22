#res://scene-scripts/grid_cell.gd
extends Area2D
class_name GridCell

### 增强版网格单元格组件（带异步加载和输入反馈）
signal cell_clicked(coordinate: Vector2i)  # 点击事件信号

# 配置参数
@export var config: GridConfig            # 网格全局配置（必须注入）
@export var data: CellData                # 单元格数据（运行时注入）

# 节点引用
@onready var _sprite: Sprite2D = $Sprite2D
@onready var _collision: CollisionShape2D = $CollisionShape2D

# 生命周期管理
func _ready() -> void:
	_validate_dependencies()
	_initialize_collision()
	_load_initial_texture()
	_setup_input_listener()

### 公共接口
func set_texture_async(path: String) -> void:
	"""线程安全的异步纹理加载"""
	if not FileAccess.file_exists(path):
		push_error("纹理文件不存在: %s" % path)
		return
	
	# 启动异步加载队列
	_start_async_load(path)

func reset() -> void:
	"""重置单元格到初始状态"""
	_sprite.texture = null
	data.texture_path = ""
	modulate = Color.WHITE

### 私有实现
func _validate_dependencies() -> void:
	"""依赖项完整性检查"""
	assert(config != null, "GridConfig 必须配置！")
	assert(data != null, "CellData 必须注入！")

func _initialize_collision() -> void:
	"""动态创建碰撞形状"""
	if _collision.shape == null:
		_collision.shape = RectangleShape2D.new()
	_collision.shape.size = config.cell_size
	_collision.position = config.cell_size / 2  # 中心对齐

func _load_initial_texture() -> void:
	"""初始化时加载持久化纹理"""
	if data.texture_path.is_empty(): 
		_apply_texture(config.default_texture)  # 直接使用默认纹理
		return
	
	if ResourceLoader.exists(data.texture_path):
		_apply_texture(load(data.texture_path))
	else:
		push_warning("初始纹理加载失败: %s" % data.texture_path)
		_apply_texture(config.default_texture)  # 失败时回退

func _adjust_texture_scale() -> void:
	if not _sprite.texture:
		return
	
	var texture_size := _sprite.texture.get_size()
	var target_scale := config.cell_size / texture_size
	
	match config.scale_mode:
		GridConfig.ScaleMode.FIT:
			var fit_scale = min(target_scale.x, target_scale.y)  # 重命名为 fit_scale
			_sprite.scale = Vector2(fit_scale, fit_scale)
		GridConfig.ScaleMode.FILL:
			var fill_scale = max(target_scale.x, target_scale.y)  # 重命名为 fill_scale
			_sprite.scale = Vector2(fill_scale, fill_scale)
		GridConfig.ScaleMode.STRETCH:
			_sprite.scale = target_scale
	
	# 自动居中
	_sprite.position = (config.cell_size - texture_size * _sprite.scale) / 2

# 添加资源队列
var _resource_queue := []
func _start_async_load(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_error("纹理文件不存在: %s" % path)
		return

	var loader = ResourceLoader.load_threaded_request(path)
	if loader != OK:
		push_error("启动异步加载失败: %s" % path)
		return	
	# 添加到加载队列
	_resource_queue.append(path)
	
func _monitor_loading_status(path: String) -> void:
	"""加载状态轮询（带超时机制）"""
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

func _on_texture_loaded(path: String) -> void:
	"""加载完成回调"""
	var texture = ResourceLoader.load_threaded_get(path)
	if texture is Texture2D:
		_apply_texture(texture)
	else:
		push_error("无效的纹理资源: %s" % path)
		_apply_texture(config.default_texture)  # 错误时使用默认

func _apply_texture(texture: Texture2D) -> void:
	"""安全应用纹理（新增默认回退）"""
	if texture:
		_sprite.texture = texture
	else:
		_sprite.texture = config.default_texture
	_adjust_texture_scale()

### 输入系统增强
func _setup_input_listener() -> void:
	"""初始化输入响应"""
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	"""智能点击检测"""
	if event is InputEventMouseButton \
		and event.pressed \
		and event.button_index == MOUSE_BUTTON_LEFT:
			emit_signal("cell_clicked", data.coordinate)

func _on_mouse_entered() -> void:
	"""悬停反馈动画"""
	create_tween().tween_property(self, "modulate", Color(1.2, 1.2, 1.2), 0.1)

func _on_mouse_exited() -> void:
	"""离开恢复动画"""
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.2)
