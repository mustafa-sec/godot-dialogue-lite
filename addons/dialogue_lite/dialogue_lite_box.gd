class_name GDLiteBox
extends PanelContainer

var _runner: GDLiteRunner
var _snapshot: Dictionary = {}
@onready var _speaker: Label = $Margin/Rows/Speaker
@onready var _text: Label = $Margin/Rows/Text
@onready var _options: VBoxContainer = $Margin/Rows/Options
@onready var _next: Button = $Margin/Rows/Next

func _ready() -> void:
	_next.pressed.connect(_advance)
	_refresh()

func bind_runner(runner: GDLiteRunner) -> void:
	_runner = runner
	_snapshot = {}
	if is_node_ready():
		_refresh()

func _process(_delta: float) -> void:
	_refresh()

func _refresh() -> void:
	var current: Dictionary = _runner.get_current() if is_instance_valid(_runner) else {}
	if current == _snapshot and not _snapshot.is_empty():
		return
	_snapshot = current
	for child in _options.get_children():
		_options.remove_child(child)
		child.queue_free()
	_speaker.text = ""
	_text.text = ""
	_next.hide()
	visible = current.get("state", "idle") in ["line", "choice"]
	if not visible:
		return
	if current.state == "line":
		_speaker.text = current.speaker
		_text.text = current.text
		_next.show()
	else:
		_speaker.text = "Choose:"
		for option in current.choices:
			var button = Button.new()
			button.text = option.text
			button.pressed.connect(_choose.bind(option.id))
			_options.add_child(button)

func _advance() -> void:
	if is_instance_valid(_runner):
		_runner.advance()
	_refresh()

func _choose(id: String) -> void:
	if is_instance_valid(_runner):
		_runner.choose(id)
	_refresh()
