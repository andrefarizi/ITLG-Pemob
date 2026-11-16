// Bundel ulang maskot Gyro: node build.mjs (jalankan dari folder tool/gyro_web)
import { build } from 'esbuild';
import { copyFileSync, readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(here, '../..');

// mascot.js asli ada di folder gyro/ — disalin agar import 'three' terbaca dari node_modules di sini
copyFileSync(resolve(root, 'gyro/mascot.js'), resolve(here, 'mascot.js'));

const out = await build({
  entryPoints: [resolve(here, 'gyro_main.js')],
  bundle: true,
  format: 'iife',
  minify: true,
  target: 'es2019',
  legalComments: 'none',
  write: false,
});
const js = out.outputFiles[0].text;
if (js.toLowerCase().includes('</script')) throw new Error('bundle mengandung </script>');
const html = readFileSync(resolve(here, 'template.html'), 'utf8').replace('/*GYRO_JS*/', () => js);
mkdirSync(resolve(root, 'assets/gyro'), { recursive: true });
writeFileSync(resolve(root, 'assets/gyro/gyro.html'), html);
console.log(`assets/gyro/gyro.html ditulis (${(html.length / 1024).toFixed(0)} KB)`);
