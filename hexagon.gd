extends Area2D

signal hexagon_clicked

var hex_pos = Vector2(0, 0)

func place(h):
	position = Moves.axial_to_px(h)

func on_input(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		emit_signal("hexagon_clicked")