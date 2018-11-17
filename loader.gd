extends Node

func save_game(fname, steps):
	var file = File.new()
	file.open(fname, file.WRITE)
	if not file.is_open():
		return false
	for i in range(0, steps.size(), 3):
		var s = str(int(i/3)+1)+". "
		s += str(steps[i])
		if steps.size() > i+1:
			s += str(steps[i+1])
		if steps.size() > i+2:
			s += str(steps[i+2])
		s += "\r\n"
		file.store_string(s)
	file.close()
	return true

func load_game(fname):
	"""Turns a filename into a list of steps."""
	var file = File.new()
	file.open(fname, File.READ)
	if not file.is_open():
		return []
	var lines = file.get_as_text().split("\n")
	var idx = 0
	var step_list = []

	for line in lines:
		idx = get_move_number(line)

		while idx < line.length():
			var ret = get_step(line, idx)
			idx = ret[0]
			step_list.append(ret[1])
	return step_list

func peek(line, idx):
	if line.length()-1 >= idx:
		return line[idx]
	return "\n"

func get_move_number(line):
	"""We don't actually care about it."""
	return line.find(" ") + 1

func get_step(line, idx):
	var step = []

	idx = get_char('[', line, idx)

	while peek(line, idx) != ']':
		var ret = get_hex_pos(line, idx)
		idx = ret[0]
		step.append(ret[1])
		if peek(line, idx) == ',':
			idx = get_char(',', line, idx)

	idx = get_char(']', line, idx)

	return [idx, step]

func get_char(c, line, idx):
	"""Consumes the next occurence of `c` in `line`, and also any spaces coming
	after `c`."""
	var idx_found = -1
	for i in range(idx, line.length()):
		if line[i] == c:
			idx_found = i+1
			break
	if idx_found == -1:
		return -1
	while peek(line, idx_found) == " ":
		idx_found += 1
	return idx_found

func get_hex_pos(line, idx):
	var hex_pos = Vector2()

	idx = get_char('(', line, idx)

	hex_pos.x = get_integer(line, idx)
	idx = get_char(',', line, idx)
	hex_pos.y = get_integer(line, idx)

	idx = get_char(')', line, idx)

	return [idx, hex_pos]

func get_integer(line, idx):
	var num_str = ""

	for i in range(idx, line.length()):
		if line[i] == '-' or line[i].is_valid_integer():
			num_str += line[i]
		elif not num_str.empty():
			return int(num_str)
		else:
			return 42