#!/usr/bin/env zsh
# Art pipeline for one unit: generate (unless --no-generate), grid-recover, colour-map, review PNG.
# usage: zsh scripts/art/export.zsh <unit> [--no-generate]
# Reads art/units/<unit>.json (family, identifiers, prompt, seed).
set -euo pipefail
unit=$1; shift || true
gen=1; [[ "${1:-}" == "--no-generate" ]] && gen=0
spec=art/units/$unit.json
[[ -f $spec ]] || { echo "no unit spec at $spec" >&2; exit 2 }
mkdir -p art/raw art/sheets art/review
if (( gen )); then
	prompt=$(python3 -c "import json;print(json.load(open('$spec'))['prompt'])")
	seed=$(python3 -c "import json;print(json.load(open('$spec'))['seed'])")
	lora=$(echo ~/.cache/huggingface/hub/models--svntax-dev--pixel_spritesheet_4walk_small_lora_v1/snapshots/*/pixel_4walk_small_flux2_klein_base_4b_v1.safetensors)
	tail_text="The spritesheet is a 4 by 4 grid of four rows of frames - first row is 3 walking frames facing down and 1 frame both arms raised, second row is 3 walking frames facing left and 1 frame jumping left, third row is 3 walking frames facing right and 1 frame jumping right, fourth row is 3 walking frames back view facing up and 1 frame lying on floor. Plain flat white background."
	~/.local/bin/mflux-generate-flux2 --model AITRADER/FLUX2-klein-base-4B-mlx-4bit --base-model flux2-klein-base-4b \
		--lora-paths "$lora" --lora-scales 1.0 \
		--prompt "A pixel art spritesheet of $prompt. $tail_text" \
		--width 512 --height 512 --steps 50 --guidance 4.0 --seed "$seed" --low-ram --metadata \
		--output art/raw/$unit.png
fi
uvx --from unfake unfake art/raw/$unit.png -o art/sheets/$unit-128.png -s 4 --transparent-background --background-tolerance 40 -m dominant -c 16
python3 scripts/art/map-colours.py "$unit" art/sheets/$unit-128.png art/sheets/$unit-mapped.png
magick art/sheets/$unit-mapped.png -filter point -resize 800% art/review/$unit.png
echo "review: art/review/$unit.png"
