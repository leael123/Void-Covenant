#res://resoures/grid_config.gd
extends Resource
class_name GridConfig

### 网格全局配置资源（增强验证版）

# 缩放模式枚举（必须定义在class外部）
enum ScaleMode {
	FIT,    # 保持比例适配单元格
	FILL,   # 保持比例填满单元格
	STRETCH # 拉伸变形
}

# 配置参数
@export var grid_size := Vector2i(100, 100)  # 网格行列数 (列, 行)
@export var cell_size := Vector2(16, 16)     # 每个单元格的像素尺寸（最小3x3）
@export var default_texture: Texture2D       # 默认贴图（可选）
@export var scale_mode: ScaleMode = ScaleMode.FIT  # 纹理缩放模式

# 数据验证（引擎自动调用）
func _validate_properties() -> void:
	# 网格尺寸校验
	assert(grid_size.x > 0 && grid_size.y > 0, 
		"网格尺寸必须大于0 | 当前值: %s" % grid_size)
	
	# 单元格最小尺寸限制
	assert(cell_size.x >= 3 && cell_size.y >= 3, 
		"单元格尺寸过小（最小3x3像素）| 当前值: %s" % cell_size)
	
	# 缩放模式合法性检查
	assert(ScaleMode.values().has(scale_mode),
		"非法的缩放模式 | 当前值: %s" % scale_mode)

	# 附加纹理存在性检查（可选）
	if default_texture:
		assert(FileAccess.file_exists(default_texture.resource_path),
			"默认纹理文件不存在: %s" % default_texture.resource_path)
