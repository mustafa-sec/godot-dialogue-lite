class_name GDLiteRunner
extends Node

const MAX_BYTES = 1048576
var _graph: Dictionary = {}
var _current: Dictionary = _empty("idle")

static func _empty(state: String) -> Dictionary:
	return {"state": state, "node_id": "", "speaker": "", "text": "", "choices": []}

func is_running() -> bool:
	return _current.state == "line" or _current.state == "choice"

func get_current() -> Dictionary:
	return _current.duplicate(true)

func load_json(path: String) -> Error:
	if is_running():
		return ERR_BUSY
	if not FileAccess.file_exists(path):
		return ERR_FILE_NOT_FOUND
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return FileAccess.get_open_error()
	if file.get_length() > MAX_BYTES:
		return ERR_INVALID_DATA
	var parser = JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return ERR_INVALID_DATA
	var data: Variant = parser.data
	var result = _validate(data)
	if result != OK:
		return result
	_graph = data.duplicate(true)
	_current = _empty("idle")
	return OK

func start() -> Error:
	if is_running():
		return ERR_BUSY
	if _graph.is_empty():
		return ERR_UNCONFIGURED
	_enter(_graph.start)
	return OK

func advance() -> Error:
	if _current.state != "line":
		return ERR_INVALID_PARAMETER
	_enter(_graph.nodes[_current.node_id].next)
	return OK

func choose(choice_id: String) -> Error:
	if _current.state != "choice":
		return ERR_INVALID_PARAMETER
	for option in _graph.nodes[_current.node_id].choices:
		if option.id == choice_id:
			_enter(option.next)
			return OK
	return ERR_INVALID_PARAMETER

func stop() -> Error:
	_current = _empty("idle")
	return OK

func _enter(target: Variant) -> void:
	if target == null:
		_current = _empty("ended")
		return
	var node: Dictionary = _graph.nodes[target]
	_current = _empty(node.type)
	_current.node_id = target
	if node.type == "line":
		_current.speaker = node.speaker
		_current.text = node.text
	else:
		for option in node.choices:
			_current.choices.append({"id": option.id, "text": option.text})

static func _keys(value: Variant, expected: Array) -> bool:
	if not value is Dictionary or value.size() != expected.size():
		return false
	for key in expected:
		if not value.has(key):
			return false
	return true

static func _id(value: Variant) -> bool:
	if not value is String:
		return false
	var regex = RegEx.new()
	regex.compile("^[A-Za-z_][A-Za-z0-9_]{0,63}$")
	return regex.search(value) != null

static func _target(value: Variant, nodes: Dictionary) -> bool:
	return value == null or (_id(value) and nodes.has(value))

static func _validate(data: Variant) -> Error:
	if not _keys(data, ["format", "version", "start", "nodes"]):
		return ERR_INVALID_DATA
	if not data.format is String or data.format != "godot_dialogue_lite" or not (data.version is float or data.version is int):
		return ERR_INVALID_DATA
	if data.version != 1:
		return ERR_UNAVAILABLE
	if not data.nodes is Dictionary or data.nodes.is_empty() or data.nodes.size() > 4096:
		return ERR_INVALID_DATA
	var nodes: Dictionary = data.nodes
	if not _id(data.start) or not nodes.has(data.start):
		return ERR_INVALID_DATA
	for id in nodes:
		var node: Variant = nodes[id]
		if not _id(id) or not node is Dictionary or not node.has("type") or not node.type is String:
			return ERR_INVALID_DATA
		if node.type == "line":
			if not _keys(node, ["type", "speaker", "text", "next"]):
				return ERR_INVALID_DATA
			if not node.speaker is String or not node.text is String or not _target(node.next, nodes):
				return ERR_INVALID_DATA
		elif node.type == "choice":
			if not _keys(node, ["type", "choices"]):
				return ERR_INVALID_DATA
			if not node.choices is Array or node.choices.is_empty() or node.choices.size() > 64:
				return ERR_INVALID_DATA
			var seen: Dictionary = {}
			for option in node.choices:
				if not _keys(option, ["id", "text", "next"]):
					return ERR_INVALID_DATA
				if not _id(option.id) or seen.has(option.id) or not option.text is String or not _target(option.next, nodes):
					return ERR_INVALID_DATA
				seen[option.id] = true
		else:
			return ERR_INVALID_DATA
	return OK
