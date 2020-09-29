extends Sprite

var Piece = preload("res://piece.tscn")
var Hexagon = preload("res://hexagon.tscn")

const Invalid = Vector2(42, 42)

var current_selection = Invalid # currently selected position, or Invalid
var step = 0 # 0 -> White to move, ..., 2 -> Black, ..., n -> colors[n%3]
var step_list = [] # note that a step is a third of a move

var escape_time = false
var liberation_move = [Invalid, Invalid] # from, to

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

	print("Shortcuts:")
	print(" - 'S' saves the game to a file")
	print(" - 'L' loads the saved game `replay.trx` (if it exists)")
	print(" - 'U' takes back the last move")
	print(" - 'R' resets the board")

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.scancode == KEY_S:
			var date = OS.get_datetime()
			var fname = str(date["day"])+"-"
			fname += str(date["month"])+"-"
			fname += str(date["year"])+"-"
			fname += str(date["minute"])+".trx"
			if Loader.save_game(fname, step_list):
				print("Game saved to file `%s`." % fname)
			else:
				print("Failed to save the game to `%s`.", fname)
		if event.scancode == KEY_R:
			print("New game.")
			reset()
		if event.scancode == KEY_U:
			print("Undoing step ", step, " (move ", int(step/3)+1, ")")
			undo_step()
		if event.scancode == KEY_L:
			var steps = Loader.load_game("replay.trx")
			if not steps.empty():
				print("Loading `replay.trx`.")
				replay(steps)
			else:
				print("Failed to load `replay.trx`.")

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

	for p in get_tree().get_nodes_in_group("pieces"):
		p.queue_free()
	for p in get_tree().get_nodes_in_group("jailed_pieces"):
		p.queue_free()

	current_selection = Invalid
	step = 0
	step_list = []
	escape_time = false
	liberation_move = [Invalid, Invalid]
	# TODO: reset highlighting

	for rot in [0, 120, 240]:
		for i in range(3):
			var color = [piece.White, piece.Grey, piece.Black][rot / 120]
			var types = types_by_line[i]
			var start = Moves.rotate(start_hexs[i], rot)
			var dir = Moves.rotate(Moves.axial_direction(Moves.Lines.E), rot)
			var line = Moves.line_from(start, dir, types.size())
			for j in range(types.size()):
				add_piece_at(line[j], types[j], color)

func replay(step_sequence):
	reset()
	yield(get_tree(), "idle_frame") # wait for the new generation of pawns
	for move in step_sequence:
		piece_move(move[0], move[1])
		if escape_time:
			liberate_piece(move[2])

func undo_step():
	if step_list.empty():
		return
	step_list.pop_back()
	replay(step_list)

func color_to_move():
	return [White, Grey, Black][step % 3]

func piece_move(h1, h2):
	"""Moves piece at h1 to h2, eating an enemy piece if necessary.
	This functions also handles jailing eaten pieces and recording moves."""
	var jails = [ # the index is the color
		[Vector2(7, 2), Moves.axial_direction(Moves.Lines.SSW)],
		[Vector2(9, -7), Moves.axial_direction(Moves.Lines.SSE)],
		[Vector2(-9, 0), Moves.axial_direction(Moves.Lines.NNE)] ]
	var liberating_lines = [
		Moves.line_from(Vector2(0, -7), Moves.axial_direction(Moves.Lines.E)),
		Moves.line_from(Vector2(-7, 0), Moves.axial_direction(Moves.Lines.SSE)),
		Moves.line_from(Vector2(0, 7), Moves.axial_direction(Moves.Lines.NNE)),
	]
	var eater = piece_at(h1)
	var eaten = piece_at(h2)

	if eaten:
		var jail_name = "jail"+str(eaten.color)
		var place_in_jail = get_tree().get_nodes_in_group(jail_name).size()
		var h = jails[eaten.color][0] + place_in_jail*jails[eaten.color][1]
		var hexagon = Hexagon.instance()

		hexagon.place(h)
		hexagon.add_to_group("jail_hexagons")
		hexagon.connect("hexagon_clicked", self, "on_jailed_clicked", [hexagon])
		add_child(hexagon)
		eaten.add_to_group(jail_name)
		eaten.add_to_group("jailed_pieces")
		eaten.remove_from_group("pieces")
		eaten.move(h)

	eater.move(h2)

	# check for possible liberation: needs at least one non-pawn jailed piece
	if eater.type == eater.Pawn and eater.hex_pos in liberating_lines[eater.color]:
		for jailed in get_tree().get_nodes_in_group("jailed_pieces"):
			if jailed.color == color_to_move() and jailed.type != jailed.Pawn:
				escape_time = true
				liberation_move[0] = h1
				liberation_move[1] = h2
				return
	step += 1
	step_list.append([h1, h2])

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

func is_in_checkmate(color):
	# `color` is in checkmate if no piece can move to save their attacked king
	if not is_in_check(color):
		return false
	for piece in get_tree().get_nodes_in_group("pieces"):
		if piece.color == color and not piece.possible_moves().empty():
			return false
	return true

func on_hexagon_clicked(hex_pos):
	if escape_time:
		return

	var piece = piece_at(hex_pos)
	var previous = piece_at(current_selection)
	var playing_color = color_to_move()

	# warning: organigram strongly recommanded before modifying
	# warning: order of operations (highlighting, moves) matters here
	# TODO: simplify the (highlighting, selected) coupling
	if piece:
		if piece.color != color_to_move():
			if previous != null:
				if previous.can_move(piece.hex_pos):
					highlight_possible_moves(previous.hex_pos, false)
					current_selection = Invalid
					piece_move(previous.hex_pos, piece.hex_pos)
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
				piece_move(previous.hex_pos, hex_pos)

	var possibly_checked = [White, Grey, Black]
	possibly_checked.erase(playing_color)
	for color in possibly_checked:
		if is_in_checkmate(color):
			print("Color ", color, " has lost. Winner is ", playing_color)

func on_jailed_clicked(hexagon):
	if not escape_time:
		return
	liberate_piece(hexagon.hex_pos)
	hexagon.remove_from_group("jail_hexagons")
	hexagon.queue_free()

func liberate_piece(h):
	for piece in get_tree().get_nodes_in_group("jailed_pieces"):
		if piece.hex_pos == h and piece.color == color_to_move():
			if piece.type == piece.Pawn:
				return
			step += 1
			step_list.append([liberation_move[0], liberation_move[1], h])
			piece_at(liberation_move[1]).queue_free()
			piece.remove_from_group("jailed_pieces")
			piece.remove_from_group("jail"+str(piece.color))
			piece.add_to_group("pieces")
			piece.move(liberation_move[1])
			escape_time = false
			liberation_move = [Invalid, Invalid]
			return
