extends Area2D

signal hexagon_clicked

var hex_pos = Vector2(0, 0)

func place(h):
	hex_pos = h
	position = Moves.axial_to_px(h)

func on_input(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		emit_signal("hexagon_clicked")

func set_highlight(enable):
	if enable:
		$draw_shape.color.a = 1
	else:
		$draw_shape.color.a = 0