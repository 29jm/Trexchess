extends Sprite

enum {
	Pawn, Canon, Lanceman, Knight, Bishop, Rook, Queen, King
}

enum {
	White = 0, Grey = 1, Black = 2
}

var hex_pos = Vector2(0, 0)
var type = Pawn
var color = White

signal selected

var type_to_sprite_str = {
	Pawn: "res://sources/pawn.png",
	Canon: "res://sources/canon.png",
	Lanceman: "res://sources/lanceman.png",
	Knight: "res://sources/knight.png",
	Bishop: "res://sources/bishop.png",
	Rook: "res://sources/rook.png",
	Queen: "res://sources/queen.png",
	King: "res://sources/king.png",
}

var color_to_color = { # tmtc
	White: ColorN("white"),
	Grey: ColorN("gray"),
	Black: ColorN("black")
}

func place(h, t, c):
	hex_pos = h
	type = t
	color = c
	position = Moves.axial_to_px(h)
	texture = load(type_to_sprite_str[t])
	modulate = color_to_color[c]

func move(h):
	hex_pos = h
	position = Moves.axial_to_px(h)

func can_move(h):
	return h in possible_moves()

func line_till_piece(start_h, dir):
	"""Returns the positions of cells from `start_h` in direction `dir`,
	excluding `start_h`, until either a piece or the edge of
	the board is reached. If an enemy piece is reached, it is included."""
	var line = Moves.line_from(start_h, dir)
	line.pop_front() # remove `hex_pos`
	var pieces = get_tree().get_nodes_in_group("pieces")
	for i in range(line.size()):
		for piece in pieces:
			if piece.hex_pos == line[i]:
				if piece.color == color:
					line.resize(i)
				else:
					line.resize(i+1)
				return line
	return line

func possible_moves():
	var moves = [] # friendly-fire measures taken at the end

	if type == Pawn:
		var rot = color * 120 # yeaahhhh... about that...
		var dir1 = Moves.rotate(Moves.axial_direction(Moves.Lines.NNE), rot)
		var dir2 = Moves.rotate(Moves.axial_direction(Moves.Lines.NNW), rot)
		moves = [hex_pos + dir1, hex_pos + dir2]
	elif type == Canon:
		moves += Moves.ring(hex_pos, 1)
	elif type == Lanceman:
		moves += Moves.ring(hex_pos, 1)
	elif type == Knight:
		for rot in range(0, 360, 60):
			moves.append(Moves.rotate(hex_pos+Vector2(3, -1), rot, hex_pos))
			moves.append(Moves.rotate(hex_pos+Vector2(2, 1), rot, hex_pos))
	elif type == Bishop:
		for dir_idx in range(Moves.Diagonals.NE, Moves.Diagonals.SE+1):
			moves += line_till_piece(hex_pos, Moves.axial_direction(dir_idx))
	elif type == Rook:
		for dir_idx in range(Moves.Lines.SSE+1):
			moves += line_till_piece(hex_pos, Moves.axial_direction(dir_idx))
	elif type == Queen:
		for dir_idx in range(Moves.Lines.E, Moves.Diagonals.SE+1):
			moves += line_till_piece(hex_pos, Moves.axial_direction(dir_idx))
	elif type == King:
		moves += Moves.ring(hex_pos, 1)

	for piece in get_tree().get_nodes_in_group("pieces"):
		if piece.color == color:
			var idx = moves.find(piece.hex_pos)
			if idx != -1:
				moves.remove(idx)

	# TODO: remove moves that would check `color`'s king (req: check detection)

	return moves