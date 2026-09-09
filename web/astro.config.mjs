// @ts-check
import { defineConfig } from 'astro/config';

// https://astro.build/config
export default defineConfig({
  site: 'https://ahauy.github.io',
  base: process.env.BASE_PATH ?? '/FlowSnap',
});
