#!/usr/bin/env node
/** Wrapper — runs the Chrome headless generator. */
import { spawnSync } from 'child_process';
import path from 'path';
import { fileURLToPath } from 'url';

const script = path.join(path.dirname(fileURLToPath(import.meta.url)), 'generate-website-images.sh');
const result = spawnSync(script, { stdio: 'inherit', shell: true });
process.exit(result.status ?? 1);
