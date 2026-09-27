# Bronze Remembers

Turn-based tactics RPG with a legacy spine. Godot 4.7, GDScript. Design in `docs/design.md`, plan in `PLAN.md`, open items in `docs/open-questions.md`.

## Layers

`sim/` is pure GDScript (`RefCounted`, no nodes, deterministic, seeded through `SimRng`). `presentation/` consumes sim events and plays them. `meta/` owns campaign, Register and saves. Dependencies flow downward only; nothing in `sim/` imports from the other two.

## Commands

| Task | Command |
|---|---|
| Import assets headless | `make import` |
| Run tests (GUT, exit 1 on failure) | `make test` |
| Run a scene windowed | `make run SCENE=<name>` |
| Screenshot a scene | `make shot SCENE=<name> OUT=<png>` |
| Dump debug state headless | `make dump SCENE=<name> OUT=<json>` |
| Art pipeline for a unit | `make art UNIT=<name>` |

Scenes live at `scenes/<name>/<name>.tscn`. The launcher takes `-- --scene=<name>`; `DebugApi` takes `--debug-dump[=path]`; `Screenshot` takes `--shot=<path>` and needs a window.

## Conventions

- Tabs for indentation in GDScript, JSON and Makefiles.
- British spelling in comments, docs and UI text.
- Tests: `tests/unit/test_<module>.gd` for sim units, `tests/journey/` for scripted playthroughs through the sim layer. Every phase ends with one journey test.
- No inline hex in scenes or scripts: colours come from `.claude/themes/` through the art pipeline's colour maps.
- Commit messages: Conventional Commits, no attribution lines.

## Art pipeline

Local models only (mflux, FLUX.2 klein base 4B plus the svntax sprite-sheet LoRA; Z-Image Turbo for tiles and props). Spec per unit in `docs/sprite-spec-slice.md`. Bodies are generated with identifier colours and empty hands; weapons, shields, grafts, ink, scars and heraldry are Aseprite overlay layers; a per-unit colour map swaps identifiers to the theme palette.
