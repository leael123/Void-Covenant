#res://resoures/cell_type.gd
extends Node2D

func setup_grid(grid_manager):
	# --- 定义格子（地面） ---
	#名称
	#贴图路径
	#可否通行		true/false
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
