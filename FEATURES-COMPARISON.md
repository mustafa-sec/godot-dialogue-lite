# Lite vs full GodotDialogue

Lite is a smaller functional subset with an original implementation, not copied paid-addon code. This table describes inspected full-addon implementation files, not a verification of storefront contents. **Lite is MIT-licensed; full GodotDialogue is under the single-developer commercial licence.** See Lite `LICENSE` and the full version's supplied terms before use. Payment does not change Lite's MIT licence.

Full-source citations are provenance references from the offline inspection, not public repository links. Paths below are relative to `GodotDialogue_v1.0.1/` in the inspected archive.

| Feature | Lite | Full version | Full-source evidence |
| --- | --- | --- | --- |
| JSON lines and choices | Distinct Lite v1 schema; unconditional options | Versioned graph with richer branching | `addons/godot_dialogue/dialogue_runner.gd`, load_json/start/choose |
| Variables and defaults | None | Scalar defaults, overrides, read/write APIs | Same runner, start/set_variable/get_variables |
| Conditions | None | eq/ne/lt/le/gt/ge, hidden choices and fallback | Same runner, _matches/_walk |
| Automatic nodes | None | Branch and set nodes, choice assignments, transition budget | Same runner, _walk; `dialogue_graph.gd`, validate |
| Lifecycle notifications | Polling, no signals | Synchronous line/choices/ended/failed signals and callback guard | Same runner, signal declarations/_busy |
| Validation | Exact basic schema, file/node/option caps; built-in duplicate-key behavior | Duplicate escaped-key lexical rejection and depth checks | `addons/godot_dialogue/dialogue_graph.gd`, scan/validate |
| Display | Minimal literal Labels and buttons; polling | Themeable box bound to runner signals | `addons/godot_dialogue/dialogue_box.gd`, bind_runner |
| Licence | MIT | Single-developer commercial licence | Lite `LICENSE`; full supplied terms |

Neither inspected edition supplies localization, progress saving, authored event tooling, a visual editor, portraits, audio, typewriter effects, BBCode, interpolation or networking. Theme customization is ordinary Godot Theme use. Lite is not format-compatible with the full version and does not promise automatic migration. Full tests are not inherited by Lite.

Full paid addon: https://mustafa-sec.itch.io/godotdialogue-godot-4-json-branching-dialogue
