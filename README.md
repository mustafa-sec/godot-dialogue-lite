# GodotDialogue Lite 1.0.0

[Free GodotDialogue Lite](https://mustafa-sec.itch.io/godotdialogue-lite)  
[Paid GodotDialogue](https://mustafa-sec.itch.io/godotdialogue-godot-4-json-branching-dialogue)  

Free MIT Godot 4 addon for JSON dialogue lines and ordered, unconditional choices. Original small implementation; no dependencies, autoload or editor plugin activation required.

## Run and install

Open `project.godot` in Godot 4 and run the project. Next advances a line; choices select a path; Restart resets the demo. To install elsewhere, copy `addons/dialogue_lite/` into your project, retaining its LICENSE. Instantiate `dialogue_lite_box.tscn` or build your own UI around the runner.

```gdscript
var runner = GDLiteRunner.new()
add_child(runner)
$DialogueBox.bind_runner(runner)
if runner.load_json("res://demo/sample.json") == OK:
    runner.start()
```

## API

`GDLiteRunner` extends Node. Methods return Godot Error codes: `load_json(path)`, `start()`, `advance()`, `choose(choice_id)`, `stop()`. `is_running()` returns bool; `get_current()` returns an isolated deep-copy Dictionary. No runtime signals: poll it on the main thread.

Snapshot always has `state`, `node_id`, `speaker`, `text`, `choices`. States are `idle`, `line`, `choice`, `ended`. Choices contain ordered `{id,text}` entries; choose by ID, not index. Null next ends. Stop is idempotent and retains the graph; completion/stop permits restart. Failed operations preserve state and failed loads preserve the previous graph. Load/start during running return ERR_BUSY; start unloaded returns ERR_UNCONFIGURED; invalid stepping/choice returns ERR_INVALID_PARAMETER. Missing file returns ERR_FILE_NOT_FOUND, other open failures return FileAccess's error. Invalid/oversized JSON returns ERR_INVALID_DATA; recognized format with unsupported numeric version returns ERR_UNAVAILABLE.

`GDLiteBox.bind_runner(runner)` accepts null to detach. The scene polls snapshots, uses literal Labels and buttons, and hides at idle/end. Godot Theme customization is available.

## Schema

See `demo/sample.json` for a complete story. Root has exactly `format` (`godot_dialogue_lite`), numeric `version` (1), `start`, `nodes`. Nodes are an object keyed by ASCII IDs matching `[A-Za-z_][A-Za-z0-9_]{0,63}`.

- Line: exactly `type: "line"`, string `speaker`, string `text`, `next`.
- Choice: exactly `type: "choice"`, nonempty `choices` array.
- Option: exactly string `id`, string `text`, `next`; IDs unique within each choice.
- Next: null or an existing node ID. All nodes/references are validated, including unreachable nodes. Empty text is allowed. Interactive cycles wait for input.

Limits: 1 MiB per file, 4096 nodes, 64 options per choice. Unknown fields/types are rejected. Built-in JSON duplicate-key behavior applies; there is no strict duplicate-key guarantee. JSON is data, not executed code. Paths are caller-supplied local paths.

## Scope and upgrade

No variables, conditions, assignments, automatic branch/set nodes, signals or paid-format compatibility. No localization, progress saving, event callbacks, visual editor, portraits, audio, typewriter, BBCode, interpolation or networking in either edition. See [comparison](FEATURES-COMPARISON.md) for the inspected full feature set; no seamless migration promise.

Full GodotDialogue: https://mustafa-sec.itch.io/godotdialogue-godot-4-json-branching-dialogue

Support: hello@mail.programkiln.com

## Verification and disclosure

Build smoke checked with Godot 4.7.2 stable, headless macOS: import and demo startup. This is not GUI, export or cross-platform verification. Independent `tests/run.gd` acceptance harness: 138/138 headless checks passed with 0 failures on Godot 4.7.2 stable macOS.

AI assisted — Code + Text. See `AI-DISCLOSURE.txt`. Icons are original procedural code-rendered artwork. MIT notice and warranty disclaimer are in `LICENSE`.
