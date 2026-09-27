// Generates a clod-theme core from an anchor and a few choices, following the
// derivation rule in ~/.claude/library/references/theme-conventions.md.
// usage: bun scripts/dev/make-theme.ts <spec.json> -o .claude/themes/<family>.json
import { hexToOklch, oklchToHex, contrastRatio } from '/Users/jasonwarren/.claude/library/scripts/theme/colour.ts';
import { readFileSync, writeFileSync } from 'node:fs';

type Spec = {
	family: string;
	anchor: { name: string; hex: string };
	harmony_hue: number;          // accent-2 hue in OKLCH degrees
	mood: string; inspiration: string; anchor_reason: string; rule_bent: string;
	rejected: { palette: string; why: string }[];
	seed: string;
	fonts: { display: string; body: string; mono: string };
	shape: { sm: number; md: number; lg: number; blur: number; offset: number; opacity: number };
};

const args = process.argv.slice(2);
const specPath = args[0];
const out = args[args.indexOf('-o') + 1];
const spec: Spec = JSON.parse(readFileSync(specPath, 'utf8'));
const anchor = hexToOklch(spec.anchor.hex);
const hue = anchor.h;
const chroma = Math.max(anchor.c, 0.06);
const mk = (l: number, c: number, h: number) => oklchToHex({ l, c, h });

// Surfaces: near-neutral with a trace of the anchor hue.
const surfaceL = mk(0.97, 0.015, hue);
const surfaceD = mk(0.20, 0.02, hue);
const raisedL = mk(0.94, 0.02, hue);
const raisedD = mk(0.25, 0.022, hue);
const inkL = mk(0.22, 0.02, hue);
const inkD = mk(0.93, 0.015, hue);
const mutedL = mk(0.45, 0.025, hue);
const mutedD = mk(0.72, 0.02, hue);
const lineL = mk(0.85, 0.02, hue);
const lineD = mk(0.32, 0.02, hue);

// Accent: anchor itself on dark; darkened until it clears 4.5:1 on the light surface.
let accentL = spec.anchor.hex;
for (let l = anchor.l; l > 0.2 && contrastRatio(accentL, surfaceL) < 4.6; l -= 0.01) accentL = mk(l, chroma, hue);
let accentD = spec.anchor.hex;
for (let l = anchor.l; l < 0.95 && contrastRatio(accentD, surfaceD) < 4.6; l += 0.01) accentD = mk(l, chroma, hue);
const accentInkL = contrastRatio('#FFFFFF', accentL) >= contrastRatio('#000000', accentL) ? mk(0.98, 0.01, hue) : mk(0.15, 0.02, hue);
const accentInkD = contrastRatio('#FFFFFF', accentD) >= contrastRatio('#000000', accentD) ? mk(0.98, 0.01, hue) : mk(0.15, 0.02, hue);

const h2 = spec.harmony_hue;
let accent2L = mk(0.5, chroma * 0.9, h2);
for (let l = 0.5; l > 0.2 && contrastRatio(accent2L, surfaceL) < 4.6; l -= 0.01) accent2L = mk(l, chroma * 0.9, h2);
let accent2D = mk(0.72, chroma * 0.9, h2);
for (let l = 0.72; l < 0.95 && contrastRatio(accent2D, surfaceD) < 4.6; l += 0.01) accent2D = mk(l, chroma * 0.9, h2);

// Status colours at the theme's chroma, conventional hue regions, cleared to 3:1.
const status = (h: number) => {
	let light = mk(0.55, chroma * 0.8, h);
	for (let l = 0.55; l > 0.2 && contrastRatio(light, surfaceL) < 3.1; l -= 0.01) light = mk(l, chroma * 0.8, h);
	let dark = mk(0.7, chroma * 0.8, h);
	for (let l = 0.7; l < 0.95 && contrastRatio(dark, surfaceD) < 3.1; l += 0.01) dark = mk(l, chroma * 0.8, h);
	return { light, dark };
};
const ok = status(140), warn = status(80), danger = status(25), info = status(250);

// Gradient anchor -> harmony with a mid stop on the short hue path, lightness monotonic.
const mid = (a: number, b: number) => { let d = ((b - a + 540) % 360) - 180; return (a + d / 2 + 360) % 360; };
const gradL = [mk(0.62, chroma, hue), mk(0.70, chroma * 0.9, mid(hue, h2)), mk(0.78, chroma * 0.8, h2)];
const gradD = [mk(0.35, chroma, hue), mk(0.42, chroma * 0.9, mid(hue, h2)), mk(0.50, chroma * 0.8, h2)];

const today = new Date().toISOString().slice(0, 10);
const core = {
	$schema: 'clod-theme/core@1',
	family: spec.family,
	version: 1,
	rationale: { mood: spec.mood, inspiration: spec.inspiration, anchor_reason: spec.anchor_reason, rule_bent: spec.rule_bent, rejected: spec.rejected },
	anchor: { name: spec.anchor.name, hex: spec.anchor.hex, oklch: [Number(anchor.l.toFixed(3)), Number(anchor.c.toFixed(3)), Number(anchor.h.toFixed(1))] },
	palette: {
		'ink': { light: inkL, dark: inkD, role: 'primary text' },
		'ink-muted': { light: mutedL, dark: mutedD, role: 'secondary text, captions, meta' },
		'surface': { light: surfaceL, dark: surfaceD, role: 'page background' },
		'surface-raised': { light: raisedL, dark: raisedD, role: 'cards, panels, code blocks' },
		'line': { light: lineL, dark: lineD, role: 'borders, rules, dividers' },
		'accent': { light: accentL, dark: accentD, role: 'links, primary actions, highlights' },
		'accent-ink': { light: accentInkL, dark: accentInkD, role: 'text placed on accent' },
		'accent-2': { light: accent2L, dark: accent2D, role: 'secondary emphasis, gradient partner' },
		'ok': { ...ok, role: 'success, done, passing' },
		'warn': { ...warn, role: 'caution, pending, stale' },
		'danger': { ...danger, role: 'error, blocked, destructive' },
		'info': { ...info, role: 'neutral notice, in progress' },
	},
	gradient: { light: gradL, dark: gradD },
	typography: {
		display: { family: spec.fonts.display, fallback: 'system-ui, sans-serif', weight: 700 },
		body: { family: spec.fonts.body, fallback: 'system-ui, sans-serif', weight: 400 },
		mono: { family: spec.fonts.mono, fallback: 'ui-monospace, monospace', weight: 400 },
		scale: { base_px: 16, ratio: 1.25, line_height: 1.5 },
	},
	shape: { radius_px: { sm: spec.shape.sm, md: spec.shape.md, lg: spec.shape.lg }, shadow: { blur_px: spec.shape.blur, offset_y_px: spec.shape.offset, opacity: spec.shape.opacity }, space_px: { unit: 8 } },
	contrast: {
		light: [
			{ fg: 'ink', bg: 'surface', level: 'AA', ratio: null }, { fg: 'ink', bg: 'surface-raised', level: 'AA', ratio: null },
			{ fg: 'ink-muted', bg: 'surface', level: 'AA', ratio: null }, { fg: 'accent', bg: 'surface', level: 'AA', ratio: null },
			{ fg: 'accent-ink', bg: 'accent', level: 'AA', ratio: null }, { fg: 'ok', bg: 'surface', level: 'AA-large', ratio: null },
			{ fg: 'warn', bg: 'surface', level: 'AA-large', ratio: null }, { fg: 'danger', bg: 'surface', level: 'AA-large', ratio: null },
			{ fg: 'info', bg: 'surface', level: 'AA-large', ratio: null },
		],
		dark: [
			{ fg: 'ink', bg: 'surface', level: 'AA', ratio: null }, { fg: 'ink', bg: 'surface-raised', level: 'AA', ratio: null },
			{ fg: 'ink-muted', bg: 'surface', level: 'AA', ratio: null }, { fg: 'accent', bg: 'surface', level: 'AA', ratio: null },
			{ fg: 'accent-ink', bg: 'accent', level: 'AA', ratio: null }, { fg: 'ok', bg: 'surface', level: 'AA-large', ratio: null },
			{ fg: 'warn', bg: 'surface', level: 'AA-large', ratio: null }, { fg: 'danger', bg: 'surface', level: 'AA-large', ratio: null },
			{ fg: 'info', bg: 'surface', level: 'AA-large', ratio: null },
		],
	},
	provenance: { seed: spec.seed, derived_from: null, created: today, updated: today, tool: 'theme-factory@1' },
};
writeFileSync(out, JSON.stringify(core, null, '\t') + '\n');
console.log(`wrote ${out}`);
