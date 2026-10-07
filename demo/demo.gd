extends Control

@onready var runner: GDLiteRunner = $Runner

func _ready() -> void:
	$Center/Rows/DialogueBox.bind_runner(runner)
	$Center/Rows/Restart.pressed.connect(_restart)
	var result = runner.load_json("res://demo/sample.json")
	if result == OK:
		runner.start()
	else:
		push_error("Demo load failed: %s" % result)

func _restart() -> void:
	runner.stop()
	runner.start()
