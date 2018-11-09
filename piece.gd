extends Sprite

enum Type {
	Pawn, Canon, Lanceman, Knight, Bishop, Rook, Queen, King
}

enum {
	White, Grey, Black
}

export var hex_pos = Vector2(0, 0)
export var type = Type.Pawn
export var color = White

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