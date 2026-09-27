#!/usr/bin/env python3
"""Apply a unit's identifier colour map using its family's theme ramps.
usage: map-colours.py <unit> <in.png> <out.png>
Reads art/units/<unit>.json and art/palettes/<family>.ramps.json."""
import json, subprocess, sys
unit, src, dst = sys.argv[1:4]
u = json.load(open(f"art/units/{unit}.json"))
ramps = json.load(open(f"art/palettes/{u['family']}.ramps.json"))
args = ["magick", src, "-fuzz", "18%"]
for ident in u["identifiers"].values():
    ramp = ramps[ident["ramp"]]
    target = ramp[ident["index"]] if isinstance(ramp, list) else ramp["ramp"][ident["index"]]
    args += ["-fill", target, "-opaque", ident["hex"]]
# outlines and highlights: near-black to the family outline, near-white to highlight
args += ["-fill", ramps["outline"], "-opaque", "#000000", dst]
subprocess.run(args, check=True)
print(f"{unit}: mapped with {u['family']} ramps -> {dst}")
