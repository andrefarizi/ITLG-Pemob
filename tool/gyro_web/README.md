# Gyro 3D untuk Flutter

`assets/gyro/gyro.html` adalah satu file HTML mandiri berisi three.js + `gyro/mascot.js`
+ `gyro_main.js` (scene, kamera, sentuhan, dan API `window.gyro`). File ini dimuat oleh
`lib/features/gyro/widgets/gyro_mascot_view.dart` lewat `webview_flutter` dengan latar
transparan, jadi tidak butuh internet.

## Membangun ulang (kalau `gyro/mascot.js` atau `gyro_main.js` diubah)
```
cd tool/gyro_web
npm install
npm run build
```

## API yang dipanggil dari Flutter
| JS | Kegunaan |
|---|---|
| `gyro.setState('idle' \| 'hello' \| 'listening' \| 'thinking' \| 'answer' \| 'talking' \| 'happy' ...)` | Ganti animasi (lihat `STATE_TO_CLIP` di mascot.js) |
| `gyro.pulse(kekuatan)` | Anggukan kecil tiap user mengetik |
| `gyro.lookAt(x, y)` | Arah tatapan (-1..1) |
| `gyro.setFraming(kakiX, kakiY, tinggiPx, animasi)` | Posisi kaki & tinggi maskot dalam px layar |
| `gyro.pause()` / `gyro.resume()` | Hentikan / lanjutkan render |

Event ke Flutter (channel `GyroBridge`, JSON): `{type:'ready'}`, `{type:'state', state}`,
`{type:'touch', part:'head'|'body'|'many'|'busy', state}`.
