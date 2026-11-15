# Maskot AI 3D — Panduan Integrasi

## Isi paket
| File | Fungsi |
|---|---|
| `maskot_ai.glb` | Model 3D + rig + 13 klip animasi (glTF 2.0, lolos glTF-Validator: 0 error) |
| `mascot.js` | Kode sumber model, klip, dan `MascotController` (three.js), bisa dipakai langsung di web / React Native (R3F) |

## Klip animasi di dalam GLB
| Nama klip | Durasi | Loop? | Kapan dipakai |
|---|---|---|---|
| `Idle` | 8.0 dtk | ya | Diam santai: bernapas, berat badan berpindah, melirik, lengan berayun, berkedip |
| `IdleLook` | 2.9 dtk | sekali | Selingan idle: celingak-celinguk kiri-kanan |
| `IdleTilt` | 2.3 dtk | sekali | Selingan idle: kepala miring penasaran |
| `IdleBounce` | 1.8 dtk | sekali | Selingan idle: dua lompatan kecil riang. Dipakai juga untuk "senang" (mis. user bilang terima kasih) |
| `IdleStretch` | 3.0 dtk | sekali | Selingan idle: meregangkan badan lalu geleng-geleng |
| `Wave` | 3.2 dtk | sekali | Menyapa "Halo!": loncat kecil, kepala miring, melambai berirama |
| `Listen` | 3.2 dtk | ya | User sedang mengetik / bicara: tangan memegang headphone, mengangguk-angguk |
| `Think` | 3.6 dtk | ya | Menunggu respons AI: tangan di dagu, mata melirik, titik-titik pikiran |
| `Eureka` | 2.6 dtk | sekali | Jawaban AI masuk: kaget "aha", jongkok ancang-ancang, lompat tinggi (lengan terangkat menyusul, satu kaki menendang ke depan dan satu ke belakang), mendarat empuk, memantul sekali lagi sambil bersorak. Tanpa putaran |
| `Talk` | 2.4 dtk | ya | Jawaban sedang ditampilkan/dibacakan: mengangguk, kedua tangan menjelaskan |
| `Poke` | 1.1 dtk | sekali | Badan disentuh: terlonjak kaget |
| `Giggle` | 1.6 dtk | sekali | Badan disentuh: geli, badan bergetar, mata menyipit |
| `Pat` | 1.7 dtk | sekali | Kepala dielus: merunduk senang, mata terpejam, antena bergoyang |

Setiap klip menulis pose lengkap (semua tulang), jadi aman diputar di engine apa pun tanpa sisa pose dari klip sebelumnya. Semua klip "sekali" berawal dan berakhir di pose berdiri netral.

## Event aplikasi → animasi
Maskot tidak digerakkan tombol, tetapi oleh event di fitur AI:

```
app dibuka / layar chat tampil  → Wave  → Idle
sedang Idle, tiap 3–6,5 dtk     → satu selingan acak (IdleLook / IdleTilt / IdleBounce / IdleStretch) → Idle
user mulai mengetik (teks ≠ "") → Listen   (+ anggukan kecil tiap ketukan, lihat pulse())
input dikosongkan / blur        → Idle
user menekan kirim (request AI) → Think
respons AI diterima             → Eureka → Talk
streaming jawaban selesai       → Idle   (atau IdleBounce → Idle bila user berterima kasih)
kepala maskot disentuh          → Pat → Idle
badan maskot disentuh           → Giggle / Poke / Wave (acak) → Idle
disentuh 3x berturut-turut      → IdleBounce → Idle
tidak ada interaksi ± 25 dtk    → Wave → Idle
```
Klip "sekali": putar sekali, lalu setelah durasinya habis pindah ke state berikutnya. Pakai crossfade ±0.3–0.4 dtk antar klip (0.12 dtk untuk reaksi sentuhan supaya terasa cepat).

**Selingan idle** adalah kunci supaya maskot terasa hidup. Aturannya: jangan memutar selingan yang sama dua kali berturut-turut, dan hentikan selingan begitu ada event lain (mengetik, kirim, sentuh). Di `mascot.js` ini sudah otomatis lewat `MascotController` (lihat `IDLE_FIDGETS` dan `playFidget()`).

## Contoh: React Native (Expo + @react-three/fiber/native)
```jsx
import { useGLTF, useAnimations } from '@react-three/drei/native';
import * as THREE from 'three';

const ONCE = { Wave: 'Idle', Eureka: 'Talk', Poke: 'Idle', Giggle: 'Idle', Pat: 'Idle',
               IdleLook: 'Idle', IdleTilt: 'Idle', IdleBounce: 'Idle', IdleStretch: 'Idle' };
const FIDGETS = ['IdleLook', 'IdleTilt', 'IdleBounce', 'IdleStretch'];

function Maskot({ state }) {            // state: 'Idle' | 'Listen' | 'Think' | 'Eureka' | ...
  const { scene, animations } = useGLTF(require('./maskot_ai.glb'));
  const { actions, mixer } = useAnimations(animations, scene);
  const [clip, setClip] = React.useState(state);
  React.useEffect(() => setClip(state), [state]);

  React.useEffect(() => {
    const a = actions[clip];
    a.reset().fadeIn(0.3).play();
    if (ONCE[clip]) {
      a.setLoop(THREE.LoopOnce, 1); a.clampWhenFinished = true;
      const done = (e) => e.action === a && setClip(ONCE[clip]);
      mixer.addEventListener('finished', done);
      return () => { a.fadeOut(0.3); mixer.removeEventListener('finished', done); };
    }
    return () => a.fadeOut(0.3);
  }, [clip]);
  return <primitive object={scene} />;
}
```
Di layar chat: `setMascot('Listen')` di `onChangeText`, `setMascot('Think')` sebelum `fetch` ke AI, `setMascot('Eureka')` saat respons tiba, `setMascot('Idle')` saat streaming selesai.

Untuk selingan idle, pasang timer selama state `Idle`:
```jsx
React.useEffect(() => {
  if (clip !== 'Idle') return;
  const t = setTimeout(() => setClip(FIDGETS[Math.floor(Math.random() * FIDGETS.length)]), 3000 + Math.random() * 3500);
  return () => clearTimeout(t);
}, [clip]);
```

## Contoh: Flutter
Paket penampil glTF seperti `model_viewer_plus` menerima nama klip (`animationName`) dan `autoPlay`. Simpan nama klip di state lalu bangun ulang widget saat event AI terjadi; untuk klip "sekali", pakai `Timer(Duration(milliseconds: durasiKlip), () => setState(() => clip = 'Idle'))`.

## Detail tambahan (opsional, di kode)
`MascotController` di `mascot.js` menambahkan efek runtime di atas klip:
- mata dan kepala mengikuti jari/kursor, lewat node khusus `HeadLook` dan `EyesLook` yang **di-set langsung** (bukan dikalikan) setiap frame, maksimal ±12°,
- kedipan acak lewat node `EyeLBlink`/`EyeRBlink`,
- lampu antena: berkedip saat `Think`, menyala terang saat `Eureka` (emissive material `M_AntennaTip`),
- `pulse()`: anggukan kecil berpegas pada `HeadLook`, dipanggil tiap user mengetik satu huruf,
- penjadwal selingan idle (`playFidget()`), aktif otomatis saat state `idle`.

Di demo, kamera juga ikut naik sedikit mengikuti `Root.position.y` saat maskot melompat. Kalau maskot Anda ditaruh di area sempit, sisakan ruang kosong di atas kepala ±20% tinggi maskot untuk lompatan `Eureka` (tinggi lompatan 0,8 unit; tinggi maskot ±4,3 unit). Masuk ke `Eureka` pakai crossfade pendek (±0,16 dtk) supaya gerakan ancang-ancangnya tidak hilang.

**Penting supaya gerakan selalu sama:** klip sekali-jalan yang diputar dengan `clampWhenFinished = true` akan diam di pose akhir dengan bobot penuh setelah selesai. Kalau tidak di-`fadeOut()`/`stop()` saat pindah klip, pose-pose lama ikut tercampur dan gerakan (terutama lompatan) makin lama makin pendek dan berbeda. Saat berpindah klip, lepas **semua** klip lain yang bobotnya masih > 0, bukan hanya yang sedang berjalan. `MascotController._play()` sudah melakukan ini, begitu juga contoh React Native di atas (fadeOut di cleanup).

Kalau engine Anda lain, tiru efek ini dengan men-set rotasi/skala node tersebut setiap frame. Jangan mengalikan rotasi node yang juga dianimasikan klip: nilainya akan menumpuk dan mata bisa berputar.

## Nama node penting (rig)
`Root` → `Hips` → `Torso` → `Head` → `HeadLook` → `HeadCenter` → (`Eyes` → `EyesLook` → `EyeL`/`EyeR` → `EyeLBlink`/`EyeRBlink`, `HeadphoneL/R`, `AntennaMount` → `AntennaBase` → `AntennaTip` → `Glow`/`Sparks`, `ThoughtDots` → `Dot1..3`, `WaveLines`)
Lengan: `ShoulderL/R` → `ElbowL/R` → `HandL/R`. Kaki: `LegL/R`. 

## Catatan produksi
- Model ini dibangun dari primitif secara prosedural agar cocok dengan gambar referensi. Kalau nanti ingin dipoles seniman 3D di Blender (tekstur kain, detail logo asli), pertahankan **nama node dan nama klip** supaya kode aplikasi tidak perlu diubah.
- Ukuran: ±4,2 MB, ±110 ribu segitiga. Untuk ponsel kelas bawah, kompres dengan `gltf-transform optimize maskot_ai.glb out.glb` (Draco/meshopt).
- Logo di dada adalah tiruan dari gambar. Ganti fungsi `logoGeometry()` di `mascot.js` dengan bentuk logo resmi Anda bila perlu.
