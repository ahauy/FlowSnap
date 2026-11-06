/**
 * design-tokens.test.mjs: guard that web/DESIGN.md describes the tokens that
 * actually ship, and that status colours only reach raw hex inside surfaces
 * that stay dark in either page theme.
 *
 * The drift this catches is real: DESIGN.md once carried a light
 * `text-tertiary` that no stylesheet defined, listed `danger: #ff453a` and
 * `warning: #ffd60a` which appear nowhere in the build, and a single
 * liquid-glass value for two different per-theme values.
 */
import { readFileSync, readdirSync } from 'node:fs';
import { resolve, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import assert from 'node:assert/strict';

const root = resolve(fileURLToPath(new URL('.', import.meta.url)), '..');
const doc = readFileSync(join(root, 'DESIGN.md'), 'utf8');
const tokensCss = readFileSync(join(root, 'src/styles/design-tokens.css'), 'utf8');

const norm = (v) =>
  v
    .trim()
    .replace(/^["']|["']$/g, '')
    .replace(/,\s*/g, ',')
    .toLowerCase();

/** Parse the `colors:` block of the frontmatter into { group: { key: value } }. */
function parseDocColors(text) {
  const fm = text.split(/^---$/m)[1];
  const lines = fm.split('\n');
  const out = {};
  let group = null;
  for (const line of lines) {
    if (/^colors:/.test(line)) { group = null; continue; }
    if (/^[a-z]+:/.test(line)) { group = null; continue; }
    const g = line.match(/^  ([a-z-]+):$/);
    if (g) { group = g[1]; out[group] = {}; continue; }
    const kv = line.match(/^    ([a-z-]+): (.+)$/);
    if (kv && group && kv[1] !== 'note') out[group][kv[1]] = norm(kv[2]);
  }
  return out;
}

/** Return the declarations of one CSS block, keyed by custom property name. */
function cssBlock(text, selector) {
  const at = text.indexOf(selector);
  assert.notEqual(at, -1, `block ${selector} not found in design-tokens.css`);
  const open = text.indexOf('{', at);
  let depth = 0;
  for (let i = open; i < text.length; i++) {
    if (text[i] === '{') depth++;
    else if (text[i] === '}') {
      depth--;
      if (depth === 0) {
        const body = text.slice(open + 1, i);
        const decls = {};
        for (const m of body.matchAll(/(--[\w-]+):\s*([^;]+);/g)) decls[m[1]] = norm(m[2]);
        return decls;
      }
    }
  }
  throw new Error(`unbalanced braces after ${selector}`);
}

const docColors = parseDocColors(doc);
const lightBlock = cssBlock(tokensCss, ':root {');
const darkAttr = cssBlock(tokensCss, '[data-theme="dark"] {');
const darkMedia = cssBlock(tokensCss, ':root:not([data-theme="light"]) {');

// doc key -> css custom property
const ROLE_VAR = {
  background: '--bg-color',
  surface: '--surface-color',
  'surface-elevated': '--surface-elevated',
  border: '--border-color',
  'border-subtle': '--border-subtle',
  'border-focus': '--border-focus',
  'text-primary': '--text-primary',
  'text-secondary': '--text-secondary',
  'text-tertiary': '--text-tertiary',
  'accent-text': '--brand-apple-blue-vibrant',
  'success-text': '--color-success-text',
  'warning-text': '--color-warning-text',
  'liquid-glass-tint': '--liquid-glass-bg',
  'liquid-glass-border': '--liquid-glass-border',
};

console.log('Checking TC-TOKEN-001: every documented theme colour equals the shipped token...');
for (const [theme, block] of [['dark', darkAttr], ['light', lightBlock]]) {
  const entries = docColors[theme];
  assert.ok(entries && Object.keys(entries).length > 6, `colors.${theme} missing from DESIGN.md`);
  for (const [key, value] of Object.entries(entries)) {
    const varName = ROLE_VAR[key];
    assert.ok(varName, `DESIGN.md lists colors.${theme}.${key} with no known token role`);
    assert.ok(block[varName] !== undefined, `${varName} is not declared in the ${theme} block`);
    assert.equal(block[varName], value, `colors.${theme}.${key}: DESIGN.md says ${value}, ${varName} ships ${block[varName]}`);
  }
}
console.log('✅ TC-TOKEN-001 Passed!\n');

console.log('Checking TC-TOKEN-002: the dark palette is declared in both dark blocks...');
for (const [key, value] of Object.entries(docColors.dark)) {
  assert.equal(darkMedia[ROLE_VAR[key]], value, `colors.dark.${key} matches [data-theme="dark"] but not the prefers-color-scheme block`);
}
console.log('✅ TC-TOKEN-002 Passed!\n');

console.log('Checking TC-TOKEN-003: brand and semantic values exist, and nothing documented is fictional...');
const brandVars = { 'apple-blue': '--accent-blue', 'apple-blue-vibrant': '--accent-blue-vibrant', 'swift-orange': '--accent-swift' };
for (const [key, value] of Object.entries(docColors.brand)) {
  const varName = brandVars[key];
  assert.ok(varName, `colors.brand.${key} has no known token`);
  assert.equal(lightBlock[varName], value, `colors.brand.${key}: DESIGN.md ${value} vs ${varName} ${lightBlock[varName]}`);
}
const semanticVars = { success: '--color-success', warning: '--color-warning' };
for (const [key, value] of Object.entries(docColors.semantic)) {
  const varName = semanticVars[key];
  assert.ok(varName, `colors.semantic.${key} is documented but no token role exists for it`);
  assert.ok(lightBlock[varName] !== undefined, `colors.semantic.${key} claims ${varName}, which design-tokens.css never declares`);
  assert.equal(lightBlock[varName], value, `colors.semantic.${key}: DESIGN.md ${value} vs ${varName} ${lightBlock[varName]}`);
}
console.log('✅ TC-TOKEN-003 Passed!\n');

console.log('Checking TC-TOKEN-004: raw status hexes stay inside the always-dark chrome...');
const CHROME = new Set([
  'desktop-simulator.css|.terminal-mini-icon',
  'desktop-simulator.css|.t-prompt',
  'desktop-simulator.css|.t-green',
  'desktop-simulator.css|.t-cursor',
  'unified-installer.css|.terminal-prompt',
  'unified-installer.css|.terminal-copy-btn.copied',
]);
const STATUS_HEX = /#(?:30d158|34c759|ff9f0a|ffd60a|ff453a|10b981)\b/i;
const cssFiles = readdirSync(join(root, 'src/styles')).filter((f) => f.endsWith('.css'));
const offenders = [];
for (const file of cssFiles) {
  const text = readFileSync(join(root, 'src/styles', file), 'utf8');
  for (const m of text.matchAll(/([^{}]+)\{([^{}]*)\}/g)) {
    const selector = m[1].split('\n').pop().trim().replace(/\s+/g, ' ');
    if (/color:\s*[^;]*#/.test(m[2]) === false) continue;
    for (const decl of m[2].match(/color:\s*[^;]+/g) || []) {
      if (STATUS_HEX.test(decl)) offenders.push(`${file}|${selector}`);
    }
  }
}
for (const o of offenders) {
  assert.ok(CHROME.has(o), `${o} paints a status colour straight onto a theme-aware surface; use var(--color-success-text) or var(--color-warning-text)`);
}
assert.ok(offenders.length >= 4, `the chrome allow-list matched only ${offenders.length} rules; the scan itself broke`);
console.log(`   ${offenders.length} raw status colours, all inside the always-dark chrome`);
console.log('✅ TC-TOKEN-004 Passed!\n');

console.log('Checking TC-TOKEN-005: every documented chrome literal really renders somewhere...');
const src = [
  ...cssFiles.map((f) => readFileSync(join(root, 'src/styles', f), 'utf8')),
  ...readdirSync(join(root, 'src/components'))
    .filter((f) => f.endsWith('.astro'))
    .map((f) => readFileSync(join(root, 'src/components', f), 'utf8')),
].join('\n');
for (const [key, value] of Object.entries(docColors.chrome)) {
  assert.ok(src.toLowerCase().includes(value), `colors.chrome.${key} documents ${value}, which no source file uses`);
}
console.log('✅ TC-TOKEN-005 Passed!\n');

console.log('🎉 All design-token consistency tests passed! (5/5 Test Cases)');
