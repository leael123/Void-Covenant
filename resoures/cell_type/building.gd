#res://resoures/cell_type/building.gd
extends Node2D

## --- 定义建筑（例子） ---
#	grid_manager.define_cell_type("", {		
#		"texture": "",						
#		"height": 3,						
#		"size": Vector2(3, 3)				
#	})										

func setup_grid(grid_manager):
	
	# 名称
	# 贴图路径
	# 高度值，用于通行逻辑
	grid_manager.define_cell_type("", {
		"texture": "",
		"height": 3,
		"size": Vector2(3, 3)
	})
