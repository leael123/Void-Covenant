#res://resoures/cell_data.gd
extends Resource
class_name CellData

@export var texture_path := ""
@export var coordinate := Vector2i()
@export var is_visible := true

# 序列化方法
func serialize() -> Dictionary:
	return {
		"texture_path": texture_path,
		"coordinate": [coordinate.x, coordinate.y],
		"is_visible": is_visible
	}

# 反序列化静态方法
static func deserialize(data: Dictionary) -> CellData:
	var instance = CellData.new()
	instance.texture_path = data.get("texture_path", "")
	instance.coordinate = Vector2i(data.coordinate[0], data.coordinate[1])
	instance.is_visible = data.get("is_visible", true)
	return instance
