extends SceneTree
const Runner = preload("res://addons/dialogue_lite/dialogue_lite_runner.gd")
const Box = preload("res://addons/dialogue_lite/dialogue_lite_box.tscn")
const TEMP = "user://dialogue_lite_test.json"
var checks = 0
var failures = 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + label)
func write(text: String) -> void:
	var f = FileAccess.open(TEMP, FileAccess.WRITE)
	f.store_string(text)
	f.close()
func graph() -> Dictionary:
	return {"format":"godot_dialogue_lite", "version":1, "start":"a", "nodes":{"a":{"type":"line","speaker":"星", "text":"[b]café 😀[/b]", "next":"b"}, "b":{"type":"line","speaker":"", "text":"", "next":null}}}
func load_data(r, data) -> int:
	write(JSON.stringify(data))
	return r.load_json(TEMP)
func reject(r, data, label: String, error: int = ERR_INVALID_DATA) -> void:
	var before = r.get_current()
	check(load_data(r, data) == error and r.get_current() == before, label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var r = Runner.new()
	root.add_child(r)
	check(r.get_current() == {"state":"idle","node_id":"","speaker":"","text":"","choices":[]} and not r.is_running(), "initial snapshot")
	check(r.start() == ERR_UNCONFIGURED, "unloaded start")
	check(r.advance() == ERR_INVALID_PARAMETER and r.choose("x") == ERR_INVALID_PARAMETER, "idle operations")
	check(r.load_json("res://tests/fixtures/linear.json") == OK, "fixture load")
	check(r.start() == OK and r.is_running() and r.get_current().text == "[b]café 😀[/b]" and r.get_current().speaker == "星", "Unicode literal line")
	var before = r.get_current()
	check(r.start() == ERR_BUSY and r.load_json(TEMP) == ERR_BUSY and r.choose("x") == ERR_INVALID_PARAMETER and r.get_current() == before, "running errors preserve state")
	var copy = r.get_current()
	copy.text = "changed"
	check(r.get_current() == before, "line copy isolation")
	check(r.advance() == OK and r.get_current().node_id == "b" and r.get_current().text == "", "linear advance empty text")
	check(r.advance() == OK and r.get_current().state == "ended" and not r.is_running(), "null completion")
	check(r.advance() == ERR_INVALID_PARAMETER and r.choose("x") == ERR_INVALID_PARAMETER, "ended stepping rejected")
	check(r.start() == OK and r.stop() == OK and r.stop() == OK and r.start() == OK, "restart and idempotent stop")
	r.stop()
	check(r.load_json("res://tests/fixtures/choices.json") == OK and r.start() == OK, "choice fixture")
	check(r.get_current().choices == [{"id":"path","text":"Go"},{"id":"loop","text":""},{"id":"leave","text":"Leave"}], "choice order and empty label")
	copy = r.get_current()
	copy.choices[0].text = "changed"
	copy.choices.clear()
	check(r.get_current().choices.size() == 3 and r.get_current().choices[0].text == "Go", "nested copy isolation")
	before = r.get_current()
	check(r.choose("missing") == ERR_INVALID_PARAMETER and r.advance() == ERR_INVALID_PARAMETER and r.get_current() == before, "choice errors atomic")
	check(r.choose("loop") == OK and r.get_current() == before, "interactive self-loop waits")
	check(r.choose("path") == OK and r.get_current().state == "line" and r.advance() == OK and r.get_current().node_id == "second", "branch line and choice-to-choice")
	check(r.choose("back") == OK and r.get_current().node_id == "menu", "choice revisit")
	check(r.choose("leave") == OK and r.get_current().state == "ended", "choice direct null")
	r.stop()
	check(r.load_json("res://tests/fixtures/missing.json") == ERR_FILE_NOT_FOUND, "missing file")
	write("{broken")
	check(r.load_json(TEMP) == ERR_INVALID_DATA, "malformed JSON")
	for data in [[], null, {}, true]: reject(r, data, "invalid root " + str(data))
	for value in [false, "1", null, [], {}]:
		var g = graph(); g.version = value; reject(r, g, "version type " + str(value))
	var g = graph(); g.version = 2; reject(r, g, "future version", ERR_UNAVAILABLE)
	g = graph(); g.format = "paid"; reject(r, g, "wrong format")
	for value in [true, 3, [], {}, null]:
		g = graph(); g.format = value; reject(r, g, "invalid format type " + str(value))
	for key in graph().keys():
		g = graph(); g.erase(key); reject(r, g, "missing root " + key)
	for key in ["variables", "when", "set", "fallback", "event", "extra"]:
		g = graph(); g[key] = {}; reject(r, g, "unknown root " + key)
		g = graph(); g.nodes.a[key] = {}; reject(r, g, "unknown line " + key)
	for key in ["type", "speaker", "text", "next"]:
		g = graph(); g.nodes.a.erase(key); reject(r, g, "missing line " + key)
	for key in ["speaker", "text", "next", "start", "nodes"]:
		for value in [true, 3, [], {}]:
			g = graph()
			if key in ["start", "nodes"]: g[key] = value
			else: g.nodes.a[key] = value
			reject(r, g, "invalid " + key + " " + str(value))
	for id in ["", "1bad", "é", "a-b", "x".repeat(65)]:
		g = graph(); g.nodes[id] = g.nodes.a; reject(r, g, "invalid node ID " + id)
	g = graph(); g.start = "absent"; reject(r, g, "missing start")
	g = graph(); g.nodes.b.next = "absent"; reject(r, g, "dangling unreachable reference")
	g = graph(); g.nodes = {}; reject(r, g, "empty nodes")
	for kind in ["branch", "set", "event", true, null]:
		g = graph(); g.nodes.a.type = kind; reject(r, g, "unsupported node type " + str(kind))
	var c = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/choices.json"))
	for value in [[], {}, null, true]:
		g = c.duplicate(true); g.nodes.menu.choices = value; reject(r, g, "invalid choices " + str(value))
	for key in ["type", "choices"]:
		g = c.duplicate(true); g.nodes.menu.erase(key); reject(r, g, "missing choice node " + key)
	g = c.duplicate(true); g.nodes.menu.fallback = null; reject(r, g, "unknown choice field")
	for key in ["id", "text", "next"]:
		g = c.duplicate(true); g.nodes.menu.choices[0].erase(key); reject(r, g, "missing option " + key)
		for value in [true, 3, [], {}]:
			g = c.duplicate(true); g.nodes.menu.choices[0][key] = value; reject(r, g, "invalid option " + key + " " + str(value))
	for key in ["when", "set", "extra"]:
		g = c.duplicate(true); g.nodes.menu.choices[0][key] = {}; reject(r, g, "unknown option " + key)
	g = c.duplicate(true); g.nodes.menu.choices[1].id = "path"; reject(r, g, "duplicate option ID")
	g = c.duplicate(true); g.nodes.menu.choices[0].next = "absent"; reject(r, g, "dangling option")
	g = graph()
	for i in range(4094): g.nodes["n" + str(i)] = g.nodes.b.duplicate()
	check(load_data(r, g) == OK, "4096 nodes accepted")
	g.nodes.over = g.nodes.b.duplicate(); reject(r, g, "4097 nodes rejected")
	g = c.duplicate(true); g.nodes.menu.choices = []
	for i in range(64): g.nodes.menu.choices.append({"id":"c" + str(i),"text":"","next":null})
	check(load_data(r, g) == OK, "64 options accepted")
	g.nodes.menu.choices.append({"id":"over","text":"","next":null}); reject(r, g, "65 options rejected")
	var text = JSON.stringify(graph())
	write(text + " ".repeat(1048576 - text.to_utf8_buffer().size()))
	check(r.load_json(TEMP) == OK, "exact 1 MiB accepted")
	write(text + " ".repeat(1048577 - text.to_utf8_buffer().size()))
	check(r.load_json(TEMP) == ERR_INVALID_DATA and r.start() == OK and r.get_current().node_id == "a", "one-over bytes atomic old graph runnable")
	r.stop()
	g = graph(); g.nodes.a.text = "z".repeat(10000); g.nodes.a.speaker = "s".repeat(10000)
	check(load_data(r, g) == OK and r.start() == OK and r.get_current().text.length() == 10000, "long strings")
	r.stop()
	write(JSON.stringify(graph()).replace('"version":1', '"version":0,"version":1'))
	check(r.load_json(TEMP) == OK, "built-in duplicate keys last value (not strict rejection)")
	var cfg = ConfigFile.new()
	check(cfg.load("res://addons/dialogue_lite/plugin.cfg") == OK and cfg.get_value("plugin", "version") == "1.0.0", "plugin version 1.0.0")
	check(not ProjectSettings.has_setting("autoload/GDLiteRunner") and ProjectSettings.get_setting("editor_plugins/enabled", []).is_empty(), "no autoload; optional plugin disabled")
	var box = Box.instantiate()
	box.bind_runner(r)
	root.add_child(box)
	await process_frame
	check(not box.visible, "bind before ready idle hidden")
	r.start()
	await process_frame
	check(box.visible and box.get_node("Margin/Rows/Text").text == "[b]café 😀[/b]" and box.get_node("Margin/Rows/Speaker").text == "星", "poll external start literal labels")
	var next = box.get_node("Margin/Rows/Next")
	check(next.visible, "line Next visible")
	next.pressed.emit()
	check(r.get_current().node_id == "b", "Next press advances")
	next.pressed.emit()
	check(not box.visible, "Next completes hides")
	r.load_json("res://tests/fixtures/choices.json"); r.start()
	box.bind_runner(r)
	var options = box.get_node("Margin/Rows/Options")
	check(box.visible and not next.visible and box.get_node("Margin/Rows/Speaker").text == "Choose:" and options.get_child_count() == 3 and options.get_child(0).text == "Go", "bind after ready choice UI")
	options.get_child(0).pressed.emit()
	check(r.get_current().node_id == "path" and options.get_child_count() == 0 and next.visible, "choice press clears stale buttons")
	r.stop(); await process_frame
	check(not box.visible, "external stop hides")
	r.start(); box.bind_runner(null)
	check(not box.visible and options.get_child_count() == 0, "null detach clears")
	var other = Runner.new(); root.add_child(other); load_data(other, graph()); other.start()
	box.bind_runner(other); next.pressed.emit()
	check(other.get_current().node_id == "b" and r.get_current().node_id == "menu", "rebind forwards only new runner")
	other.free(); await process_frame
	check(not box.visible and options.get_child_count() == 0, "freed runner safe hide")
	box.queue_free(); r.queue_free()
	DirAccess.remove_absolute(TEMP)
	print("RESULT %s checks / %s passed / %s failures" % [checks, checks - failures, failures])
	quit(1 if failures else 0)
