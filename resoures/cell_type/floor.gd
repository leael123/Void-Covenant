#res://resoures/cell_type.gd
extends Node2D

## --- 定义格子（地面_例子） ---
#	grid_manager.define_cell_type("平原地面_1", {				名称
#		"texture": "res://textures/floor/floor1.png",		贴图路径
#		"height": 0											高度
#	})

func setup_grid(grid_manager):

	
	
	
	grid_manager.define_cell_type("平原地面_1", {
		"texture": "res://textures/floor/floor1.png",
		"height": 0
	})

	grid_manager.define_cell_type("平原地面_2", {
		"texture": "res://textures/floor/floor2.png",
		"height": 0
	})

	grid_manager.define_cell_type("平原地面_3", {
		"texture": "res://textures/floor/floor3.png",
		"height": 0
	})

	grid_manager.define_cell_type("平原地面_4", {
		"texture": "res://textures/floor/floo4.png",
		"height": 0
	})

	grid_manager.define_cell_type("平原地面_5", {
		"texture": "res://textures/floor/floor5.png",
		
	})

	grid_manager.define_cell_type("平原地面_6", {
		"texture": "res://textures/floor/floor6.png",
		"height": 0
	})
