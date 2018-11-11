extends Sprite

var Piece = preload("res://piece.tscn")
var Hexagon = preload("res://hexagon.tscn")

const Invalid = Vector2(42, 42)

var current_selection = Invalid # currently selected position, or Invalid
var step = 0 # 0 -> White to move, ..., 2 -> Black, ..., n -> colors[n%3]

# TODO: build singleton "Chess" holding colors and pawn types
enum {
	White = 0, Grey = 1, Black = 2
}

func _ready():
	# setup clickable hexagons
	var board_hexagons = Moves.disk(Vector2(), 7)
	for h in board_hexagons:
		var hex = Hexagon.instance()
		hex.place(h)
		hex.connect("hexagon_clicked", self, "on_hexagon_clicked", [h])
		hex.add_to_group("hexagons")
		add_child(hex)

	reset() # setup pieces

func reset():
	var piece = Piece.instance() # used only to access piece types
	var start_hexs = [Vector2(-5, 5), Vector2(-6, 6), Vector2(-7, 7)]
	var types_by_line = [
		[ piece.Pawn, piece.Pawn, piece.Pawn,
			piece.Pawn, piece.Pawn, piece.Pawn ],
		[ piece.Pawn, piece.Bishop, piece.Lanceman, piece.Bishop,
			piece.Lanceman, piece.Bishop, piece.Pawn ],
		[ piece.Canon, piece.Rook, piece.Knight, piece.King,
			piece.Queen, piece.Knight, piece.Rook, piece.Canon ]
	]

	for piece in get_tree().get_nodes_in_group("pieces"):
		piece.queue_free()
	for piece in get_tree().get_nodes_in_group("jailed_pieces"):
		piece.queue_free()

	step = 0
	# TODO: undo map rotation, ...

	for rot in [0, 120, 240]:
		for i in range(3):
			var color = [piece.White, piece.Grey, piece.Black][rot / 120]
			var types = types_by_line[i]
			var start = Moves.rotate(start_hexs[i], rot)
			var dir = Moves.rotate(Moves.axial_direction(Moves.Lines.E), rot)
			var line = Moves.line_from(start, dir, types.size())
			for j in range(types.size()):
				add_piece_at(line[j], types[j], color)

func color_to_move():
	return [White, Grey, Black][step % 3]

func piece_eat(h1, h2):
	var jails = [ # the index is the color
		[Vector2(7, 2), Moves.axial_direction(Moves.Lines.E)],
		[Vector2(9, -7), Moves.axial_direction(Moves.Lines.SSE)],
		[Vector2(-9, 0), Moves.axial_direction(Moves.Lines.NNE)] ]
	var eater = piece_at(h1)
	var eaten = piece_at(h2)
	var jail_name = "jail"+str(eater.color)
	var place_in_jail = get_tree().get_nodes_in_group(jail_name).size()

	eaten.add_to_group(jail_name)
	eaten.add_to_group("jailed_pieces") # for ease of deletion only
	eaten.remove_from_group("pieces")
	eaten.move(jails[eater.color][0] + place_in_jail*jails[eater.color][1])
	eater.move(h2)

func add_piece_at(h, type, color):
	var piece = Piece.instance()
	piece.place(h, type, color)
	piece.add_to_group("pieces")
	add_child(piece)

func piece_at(h):
	for piece in get_tree().get_nodes_in_group("pieces"):
		if piece.hex_pos == h:
			return piece
	return null

func highlight_hexagon(h, enable):
	for hex in get_tree().get_nodes_in_group("hexagons"):
		if hex.hex_pos == h:
			hex.set_highlight(enable)
			return

func highlight_possible_moves(h, enable=true):
	var piece = piece_at(h)
	if not piece:
		return
	var possible_moves = piece.possible_moves()
	for move in possible_moves:
		highlight_hexagon(move, enable)

func is_in_check(color):
	var king_h = Vector2()
	for piece in get_tree().get_nodes_in_group("pieces"):
		if piece.type == piece.King and piece.color == color:
			king_h = piece.hex_pos
	for piece in get_tree().get_nodes_in_group("pieces"):
		if piece.color != color and king_h in piece.possible_moves(false):
			return true
	return false

func move_checks_color(h1, h2, color):
	"""Returns whether the h1->h2 move would put `color` in check."""
	var moving_piece = piece_at(h1)
	var other_piece = piece_at(h2)
	moving_piece.move(h2)
	if other_piece:
		other_piece.remove_from_group("pieces")
	var res = is_in_check(color)
	moving_piece.move(h1)
	if other_piece:
		other_piece.add_to_group("pieces")
	return res

func on_hexagon_clicked(hex_pos):
	var piece = piece_at(hex_pos)
	var previous = piece_at(current_selection)

	# warning: organigram strongly recommanded before modifying
	# warning: order of operations (highlighting, moves) matters here
	# TODO: simplify the (highlighting, selected) coupling
	if piece:
		if piece.color != color_to_move():
			if previous != null:
				if previous.can_move(piece.hex_pos):
					highlight_possible_moves(previous.hex_pos, false)
					current_selection = Invalid
					piece_eat(previous.hex_pos, piece.hex_pos)
					step += 1
				highlight_possible_moves(previous.hex_pos, false)
				current_selection = Invalid
		else:
			if previous != null:
				if previous.hex_pos == piece.hex_pos:
					highlight_possible_moves(previous.hex_pos, false)
					current_selection = Invalid
				else:
					highlight_possible_moves(previous.hex_pos, false)
					highlight_possible_moves(piece.hex_pos)
					current_selection = piece.hex_pos
			else:
				highlight_possible_moves(piece.hex_pos)
				current_selection = piece.hex_pos
	else: # empty hexagon clicked
		if previous != null:
			# remove highlight _before_ losing old position
			highlight_possible_moves(previous.hex_pos, false)
			current_selection = Invalid
			if previous.can_move(hex_pos):
				previous.move(hex_pos)
				step += 1