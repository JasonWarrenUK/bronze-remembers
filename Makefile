GODOT ?= /Applications/Godot.app/Contents/MacOS/Godot
ASEPRITE ?= /Applications/Aseprite.app/Contents/MacOS/aseprite

.PHONY: import test run shot dump art

## Import assets headless (needed after adding files, before test/run headless)
import:
	$(GODOT) --headless --path . --import

## Run the GUT suite headless. Exit code 1 on any failure.
test: import
	mkdir -p tests/results
	$(GODOT) --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig.json -gexit

## Run a named scene with a window: make run SCENE=battle_smoke
run:
	$(GODOT) --path . -- --scene=$(SCENE)

## Screenshot a named scene after a few frames: make shot SCENE=battle_smoke OUT=docs/shots/battle.png
shot:
	mkdir -p $(dir $(OUT))
	$(GODOT) --path . -- --scene=$(SCENE) --shot=$(OUT)

## Dump debug state of a scene headless: make dump SCENE=battle_smoke OUT=/tmp/debug.json
dump:
	$(GODOT) --headless --path . -- --scene=$(SCENE) --debug-dump=$(OUT)

## Art pipeline for one unit: make art UNIT=spear
art:
	zsh scripts/art/export.zsh $(UNIT)
