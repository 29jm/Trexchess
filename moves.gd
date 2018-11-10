extends Node

# Bible: https://www.redblobgames.com/grids/hexagons/

const board_radius = 7
const hex_size = 35
var QVec = Vector2(hex_size*1.473, 0)
var RVec = Vector2(hex_size*1.47/2, hex_size*1.29)

enum Lines {
	E = 0, NNE = 1, NNW = 2, W = 3, SSW = 4, SSE = 5
}

enum Diagonals {
	NE = 6, N = 7, NW = 8, SW = 9, S = 10, SE = 11
}

func axial_to_cube(h):
	return Vector3(h.x, -h.x-h.y, h.y)

func cube_to_axial(c):
	return Vector2(c.x, c.z)

func axial_to_px(h):
	return 1/$"/root/trexchess/board".scale.x * (h.x*QVec + h.y*RVec)

func axial_direction(direction):
	"""Returns the unit vector of the specified direction, described by
	integers in the Lines and Diagonals enums."""
	var directions = [
		# lines: in trig order starting from the East
		Vector2(+1, 0), Vector2(+1, -1), Vector2(0, -1),
		Vector2(-1, 0), Vector2(-1, +1), Vector2(0, +1),
		# diagonals: in trig order from the North-East diagonal
		Vector2(+2, -1), Vector2(+1, -2), Vector2(-1, -1),
		Vector2(-2, +1), Vector2(-1, +2), Vector2(+1, +1)
	]

	return directions[direction]

func cube_distance(h1, h2):
    return (abs(h1.x - h2.x) + abs(h1.y - h2.y) + abs(h1.z - h2.z)) / 2

func distance(h1, h2):
	h1 = axial_to_cube(h1)
	h2 = axial_to_cube(h2)
	return cube_distance(h1, h2)

func line_from(hex_pos, direction, n=-1):
	"""Returns the n-th positions from hex_pos in the specified direction, and
	the positions till the edge of the edge of the board if n is omitted.
	`direction` is a Vector2. Use the `axial_direction` function.
	If n is specified and the line goes outside the board, it is truncated."""
	var line = [hex_pos]
	n = n if n != -1 else 2*board_radius # max distance on the board

	for i in range(n - 1):
		hex_pos += direction
		if distance(Vector2(), hex_pos) > board_radius:
			return line
		line.append(hex_pos)
	return line

func ring(center, radius):
	var hexs = []
	var cube = axial_to_cube(center) + radius * axial_to_cube(axial_direction(Lines.SSW))
	for i in range(6): # directions (lines only, so the first 6)
		for j in range(radius): # edge hexagons
			hexs.append(cube_to_axial(cube))
			cube = cube + axial_to_cube(axial_direction(i))
	return hexs

func disk(center, radius):
	var hexs = [center]
	for i in range(1, radius+1):
		hexs += ring(center, i)
	return hexs

func rotate(h, angle=120, center=Vector2()):
	if angle < 0:
		angle = round(fposmod(angle, 360))
	center = axial_to_cube(center)
	var cube = axial_to_cube(h)
	var vec = cube - center
	for i in range(int(angle/60)):
		vec = Vector3(-vec.y, -vec.z, -vec.x)
	return cube_to_axial(center+vec)

# Do not implement piece moves here