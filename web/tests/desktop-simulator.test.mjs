/**
 * Test Suite: Desktop Simulator Component & Build Output Verification
 * Traces to: .specify/features/web-desktop-sandbox/test-plan.md (TC-001 through TC-007)
 * Extended with: Multi-Window (ASM-WEB-007), Popover (ASM-WEB-008), 70/30 Precision (ASM-WEB-009)
 */

import { readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import assert from 'node:assert';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const distPath = resolve(__dirname, '../dist/index.html');
const html = readFileSync(distPath, 'utf8');

console.log('🧪 Starting Desktop Simulator Test Suite...\n');

// TC-001: Frame, MenuBar, Dock, Multi-Window (Code & Terminal)
console.log('Checking TC-001: Desktop frame & multi-window geometry...');
assert.ok(html.includes('id="desktop-simulator-root"'), 'Simulator root must be rendered');
assert.ok(html.includes('id="mac-desktop-frame"'), 'macOS desktop frame must be present');
assert.ok(html.includes('class="mac-menubar"'), 'macOS Menu Bar must be present');
assert.ok(html.includes('class="mac-dock"'), 'macOS Dock must be present');
assert.ok(html.includes('id="mock-window-code"'), 'Mock window VS Code must be present');
assert.ok(html.includes('id="mock-window-terminal"'), 'Mock window Terminal must be present');
assert.ok(html.includes('SnapEngine.swift'), 'File title SnapEngine.swift must be displayed');
assert.ok(html.includes('flowsnap status'), 'Terminal command flowsnap status must be present');
assert.ok(html.includes('SnapEngine'), 'Swift code snippet must be displayed in editor');
console.log('✅ TC-001 Passed!\n');

// TC-002: Top-Edge Snap Picker markup & 70/30 proportional layout
console.log('Checking TC-002: Top-Edge Snap Picker & 70/30 Proportional Precision...');
assert.ok(html.includes('id="snap-picker"'), 'Snap Picker container must be present');
assert.ok(html.includes('FlowSnap Smart Layouts'), 'Picker title must be present');
assert.ok(html.includes('preview-70-30'), '70/30 template preview must be present');
assert.ok(html.includes('zone-70'), 'zone-70 class must be present for proportional width');
assert.ok(html.includes('zone-30'), 'zone-30 class must be present for proportional width');
assert.ok(html.includes('preview-25-50-25'), '3-column preview class must be present');
console.log('✅ TC-002 Passed!\n');

// TC-003: Translucent Liquid Glass HUD Snap Preview
console.log('Checking TC-003: Liquid Glass HUD Snap Preview...');
assert.ok(html.includes('id="hud-snap-preview"'), 'HUD Snap Preview element must be present');
assert.ok(html.includes('id="hud-preview-badge"'), 'HUD Preview Badge element must be present');
console.log('✅ TC-003 Passed!\n');

// TC-004: FlowSnap Native Menu Bar Popover
console.log('Checking TC-004: FlowSnap Native Menu Bar Popover Dropdown...');
assert.ok(html.includes('id="fs-menubar-trigger"'), 'FlowSnap status icon trigger must be present');
assert.ok(html.includes('id="fs-menubar-popover"'), 'FlowSnap Menu Bar popover dropdown must be present');
assert.ok(html.includes('data-popover-snap="left-70"'), 'Popover 70% snap button must be present');
assert.ok(html.includes('data-popover-preset="coding"'), 'Coding dual preset button must be present');
console.log('✅ TC-004 Passed!\n');

// TC-005: 3D Perspective Stage & Glare
console.log('Checking TC-005: 3D Perspective Stage & Bezel Glare...');
assert.ok(html.includes('id="perspective-stage"'), '3D perspective stage must be present');
assert.ok(html.includes('id="bezel-glare"'), 'Specular glare element must be present');
console.log('✅ TC-005 Passed!\n');

// TC-006: Reset button & Traffic lights
console.log('Checking TC-006: Reset Sandbox Button & Dock App Launchers...');
assert.ok(html.includes('id="simulator-reset-btn"'), 'Reset Sandbox button must be present');
assert.ok(html.includes('id="dock-vscode"'), 'Dock VS Code launcher must be present');
assert.ok(html.includes('id="dock-terminal"'), 'Dock Terminal launcher must be present');
assert.ok(html.includes('id="dock-flowsnap"'), 'Dock FlowSnap launcher must be present');
console.log('✅ TC-006 Passed!\n');

// TC-007: Mobile Quick-Snap Toolbar Presets
console.log('Checking TC-007: Quick-Snap Toolbar Presets...');
assert.ok(html.includes('data-snap-action="split-50"'), 'Quick chip Balanced Split 50/50 must be present');
assert.ok(html.includes('data-snap-action="left-50"'), 'Quick chip Left 50% must be present');
assert.ok(html.includes('data-snap-action="right-50"'), 'Quick chip Right 50% must be present');
assert.ok(html.includes('data-snap-action="left-70"'), 'Quick chip Left 70% must be present');
assert.ok(html.includes('data-snap-action="coding-preset"'), 'Quick chip Coding Preset must be present');
console.log('✅ TC-007 Passed!\n');

// TC-008: Interactive Adaptive Collinear Split Divider Bar (EPIC 08)
console.log('Checking TC-008: Adaptive Collinear Split Divider Bar (EPIC 08)...');
assert.ok(html.includes('id="desktop-split-divider"'), 'Split divider container element must be present');
assert.ok(html.includes('class="divider-line"'), 'Divider hairline bar element must be present');
assert.ok(html.includes('class="divider-handle"'), 'Divider draggable handle pill must be present');
assert.ok(html.includes('aria-hidden="true"'), 'Divider must have aria-hidden initially set');
console.log('✅ TC-008 Passed!\n');

console.log('🎉 All Desktop Simulator Tests Passed Successfully!');

