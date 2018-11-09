extends Sprite

var Piece = preload("res://piece.tscn")
var Hexagon = preload("res://hexagon.tscn")

var current_selection = Vector2(0, 0) # axial coordinates of a selected piece, (0, 0) if none

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
	var starting_hexs = [Vector2(-5, 5), Vector2(-6, 6), Vector2(-7, 7)]
	var types_by_line = [
		[
			piece.Type.Pawn, piece.Type.Pawn, piece.Type.Pawn,
			piece.Type.Pawn, piece.Type.Pawn, piece.Type.Pawn],
		[
			piece.Type.Pawn, piece.Type.Bishop, piece.Type.Lanceman,
			piece.Type.Bishop, piece.Type.Lanceman, piece.Type.Bishop,
			piece.Type.Pawn
		],
		[
			piece.Type.Canon, piece.Type.Rook, piece.Type.Knight,
			piece.Type.King, piece.Type.Queen, piece.Type.Knight,
			piece.Type.Rook, piece.Type.Canon
		]
	]

	for i in range(3):
		var types = types_by_line[i]
		var line = Moves.line_from(starting_hexs[i], Moves.Lines.E, types.size())
		for j in range(types.size()):
			add_piece_at(line[j], types[j])

func add_piece_at(h, type):
	var piece = Piece.instance()
	piece.place(h, type)
	piece.add_to_group("pieces")
	add_child(piece)

func piece_at(h):
	for piece in get_tree().get_nodes_in_group("pieces"):
		if piece.hex_pos == h:
			return piece
	return null

func move_piece(h1, h2):
	var piece = piece_at(h1)
	piece.place(h2, piece.type)

func highlight_possible_moves(h):
	# TODO: if none possible, reset current_selection = Vector2()
	pass

func on_hexagon_clicked(hex_pos):
	print("hexagon clicked at ", hex_pos)
	var piece = piece_at(hex_pos)
	if piece:
		print("a piece is there")
		current_selection = hex_pos
	elif current_selection != Vector2():
		move_piece(current_selection, hex_pos)
		current_selection = Vector2()