// Derives sprite colour ramps (with skin) from a theme core, so sprites and UI
// share one source. usage: bun scripts/dev/make-ramps.ts <family> [<family>...]
// Writes art/palettes/<family>.ramps.json and art/palettes/<family>.hex
import { hexToOklch, oklchToHex } from '/Users/jasonwarren/.claude/library/scripts/theme/colour.ts';
import { readFileSync, writeFileSync } from 'node:fs';

// Skin ramps are setting decisions, not derived from the anchor: each family
// names who its people are. Three tones: shadow, base, light.
const SKIN: Record<string, { name: string; ramp: string[] }> = {
	bronze: { name: 'sun-browned', ramp: ['#5A3A24', '#8B5A3C', '#B77D5A'] },
	tide:   { name: 'drowned bone', ramp: ['#8C918A', '#B9BDB2', '#DCDDD3'] },
	ash:    { name: 'sallow', ramp: ['#5C4A3E', '#8A705E', '#A98D77'] },
	hearth: { name: 'hearth-warmed', ramp: ['#6B4430', '#9C6A4A', '#C48E6A'] },
	reed:   { name: 'river-dark', ramp: ['#3E2A1E', '#6B4A34', '#93684A'] },
};

const ramp = (hex: string, steps: number[]) => {
	const c = hexToOklch(hex);
	return steps.map((dl) => oklchToHex({ l: Math.min(0.97, Math.max(0.12, c.l + dl)), c: c.c, h: c.h }));
};

for (const family of process.argv.slice(2)) {
	const core = JSON.parse(readFileSync(`.claude/themes/${family}.json`, 'utf8'));
	const p = core.palette;
	const skin = SKIN[family];
	if (!skin) throw new Error(`no skin defined for ${family}`);
	const ramps = {
		family,
		extends: `${family}.json`,
		note: 'Sprite ramps derived from the theme core. Skin is a setting decision per family. Outline is ink (dark variant surface), highlight is ink (dark variant).',
		skin: { name: skin.name, ramp: skin.ramp },
		cloth: ramp(p['surface'].light, [-0.35, -0.2, -0.06]),          // linen: shadow, base, light
		cloth_dyed: ramp(p['accent-2'].dark, [-0.25, -0.1, 0.05]),      // the family's dye
		metal: ramp(p['accent'].dark, [-0.25, -0.08, 0.1]),             // bronze or corroded bronze
		leather: ramp(p['ink-muted'].light, [-0.15, 0.0, 0.15]),
		outline: p['surface'].dark,
		highlight: p['ink'].dark,
		blood: p['danger'].dark,
	};
	writeFileSync(`art/palettes/${family}.ramps.json`, JSON.stringify(ramps, null, '\t') + '\n');
	const all = [...skin.ramp, ...ramps.cloth, ...ramps.cloth_dyed, ...ramps.metal, ...ramps.leather, ramps.outline, ramps.highlight, ramps.blood];
	writeFileSync(`art/palettes/${family}.hex`, all.map((h) => h.slice(1).toLowerCase()).join('\n') + '\n');
	console.log(`${family}: ${all.length} colours -> art/palettes/${family}.hex`);
}

// UI palette for the battle scene, from the bronze core's dark variant plus the tide core.
{
	const bronze = JSON.parse(readFileSync('.claude/themes/bronze.json', 'utf8')).palette;
	const tide = JSON.parse(readFileSync('.claude/themes/tide.json', 'utf8')).palette;
	const ash = JSON.parse(readFileSync('.claude/themes/ash.json', 'utf8')).palette;
	const ui = {
		note: 'Emitted by scripts/dev/make-ramps.ts from the theme cores. Do not edit by hand.',
		surface: bronze.surface.dark, surface_raised: bronze['surface-raised'].dark, line: bronze.line.dark,
		ink: bronze.ink.dark, ink_muted: bronze['ink-muted'].dark,
		accent: bronze.accent.dark, accent_ink: bronze['accent-ink'].dark, accent_2: bronze['accent-2'].dark,
		ok: bronze.ok.dark, warn: bronze.warn.dark, danger: bronze.danger.dark, info: bronze.info.dark,
		hero_ring: bronze.accent.dark, enemy_ring: ash.accent.dark,
		hero_hp: bronze.ok.dark, enemy_hp: bronze.danger.dark, bar_back: bronze.line.dark,
		move_highlight: bronze.info.dark, attack_highlight: bronze.danger.dark, hold_highlight: bronze.warn.dark,
		flash_hit: bronze.ink.dark, flash_sea: tide.accent.dark,
		sea_accent: tide.accent.dark, sea_ink: tide.ink.dark,
	};
	writeFileSync('data/palette.json', JSON.stringify(ui, null, '\t') + '\n');
	console.log('data/palette.json written');
}
