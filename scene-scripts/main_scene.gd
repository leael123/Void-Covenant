#res://scene-scripts/main_scene.gd
extends Node2D
class_name MainScene

### 主场景控制器 - 负责网格系统初始化与全局协调

# 配置参数
@export var grid_config: GridConfig :            # 必须注入配置资源
	set(value):
		assert(value is GridConfig, "必须使用GridConfig类型资源")
		grid_config = value

@export var cell_scene: PackedScene :            # 单元格预制体
	set(value):
		assert(value != null, "必须指定单元格场景")
		cell_scene = value

# 节点引用
@onready var _grid_manager: GridManager = $GridManager
@onready var _camera: Camera2D = $Camera2D

# 运行时状态
var _is_grid_ready := false

### 生命周期
func _ready() -> void:
	_validate_dependencies()
	_initialize_grid_system()
	_setup_camera_limits()
	_is_grid_ready = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_MASK_LEFT:
		_camera.position -= event.relative * _camera.zoom

### 初始化流程
func _validate_dependencies() -> void:
	"""依赖项完整性检查"""
	assert(grid_config != null, "必须配置GridConfig资源")
	assert(cell_scene != null, "必须指定单元格预制体场景")

func _initialize_grid_system() -> void:
	"""网格系统初始化"""
	_grid_manager.config = grid_config
	_grid_manager.cell_scene = cell_scene
	
	# 连接核心信号
	_grid_manager.cell_loaded.connect(_on_cell_loaded)
	_grid_manager.cell_unloaded.connect(_on_cell_unloaded)
	
	print("网格系统已初始化 (规模: %dx%d)" % [grid_config.grid_size.x, grid_config.grid_size.y])

func _setup_camera_limits() -> void:
	var world_size := Vector2(
		grid_config.grid_size.x * grid_config.cell_size.x,
		grid_config.grid_size.y * grid_config.cell_size.y
	)
	
	_camera.limit_left = 0
	_camera.limit_top = 0
	# 显式转换为整数（根据需求选择取整方式）
	_camera.limit_right = int(round(world_size.x))    # 四舍五入
	_camera.limit_bottom = int(round(world_size.y))   # 四舍五入
	_camera.reset_smoothing()

### 信号处理
func _on_cell_loaded(cell: GridCell) -> void:
	"""单元格加载完成回调"""
	if _is_grid_ready:
		cell.cell_clicked.connect(_on_cell_clicked)
		_apply_initial_texture(cell)

func _on_cell_unloaded(cell: GridCell) -> void:
	"""单元格卸载回调"""
	if cell.cell_clicked.is_connected(_on_cell_clicked):
		cell.cell_clicked.disconnect(_on_cell_clicked)

func _on_cell_clicked(coord: Vector2i) -> void:
	"""单元格点击事件处理"""
	print("交互 > 点击坐标: ", coord)
	# 在此处添加业务逻辑

### 工具方法
func _apply_initial_texture(cell: GridCell) -> void:
	"""应用持久化纹理（示例）"""
	if cell.data.texture_path.is_empty():
		cell.set_texture_async("res://textures/default.png")
	
	# 添加随机纹理演示（实际项目应替换为业务逻辑）
	if randf() < 0.2:  # 20%概率加载特殊纹理
		cell.set_texture_async("res://textures/special_%d.png" % randi() % 4)

### 调试命令
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R:  # 重置相机位置
				_camera.position = Vector2.ZERO
				_camera.zoom = Vector2.ONE
			KEY_F:  # 适配窗口尺寸
				_camera.zoom = _calculate_optimal_zoom()

func _calculate_optimal_zoom() -> Vector2:
	"""计算适配当前窗口的最佳缩放比例"""
	var viewport_size := get_viewport_rect().size
	var required_zoom := Vector2(
		viewport_size.x / (grid_config.grid_size.x * grid_config.cell_size.x),
		viewport_size.y / (grid_config.grid_size.y * grid_config.cell_size.y)
	)
	return Vector2(min(required_zoom.x, required_zoom.y))
