// =====================================================================
//  Gyro — runtime 3D untuk WebView Flutter.
//  Model, rig, klip & MascotController diambil dari gyro/mascot.js.
//  Flutter mengendalikan lewat window.gyro.*; event dikirim balik ke
//  channel JavaScript "GyroBridge".
// =====================================================================
import * as THREE from 'three';
import { RoomEnvironment } from 'three/examples/jsm/environments/RoomEnvironment.js';
import { buildMascot, buildClips, MascotController } from './mascot.js'; // disalin dari gyro/mascot.js oleh build.mjs

const MODEL_H = 4.0; // tinggi maskot (unit) dari ujung kaki sampai antena
const FOV = 30;

function post(msg) {
  try {
    if (window.GyroBridge) window.GyroBridge.postMessage(JSON.stringify(msg));
  } catch (_) { /* abaikan */ }
}

const canvas = document.getElementById('c');
const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: true, powerPreference: 'high-performance' });
renderer.setClearColor(0x000000, 0);
renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
renderer.outputColorSpace = THREE.SRGBColorSpace;
renderer.toneMapping = THREE.NeutralToneMapping;
renderer.toneMappingExposure = 1.0;
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;

const scene = new THREE.Scene();
const pmrem = new THREE.PMREMGenerator(renderer);
scene.environment = pmrem.fromScene(new RoomEnvironment(), 0.04).texture;
scene.environmentIntensity = 0.75;

// Cahaya: kunci lembut dari kiri-atas depan + pengisi
const key = new THREE.DirectionalLight(0xffffff, 1.9);
key.position.set(-3.5, 7, 6);
key.castShadow = true;
key.shadow.mapSize.set(1024, 1024);
key.shadow.camera.left = -3; key.shadow.camera.right = 3;
key.shadow.camera.top = 6; key.shadow.camera.bottom = -2;
key.shadow.camera.near = 1; key.shadow.camera.far = 20;
key.shadow.radius = 6;
key.shadow.bias = -0.0005;
scene.add(key);
scene.add(new THREE.HemisphereLight(0xffffff, 0xdfe5ee, 0.55));

// Bayangan kontak di "lantai" (piringan putihnya digambar oleh Flutter)
const ground = new THREE.Mesh(new THREE.CircleGeometry(2.4, 48), new THREE.ShadowMaterial({ opacity: 0.22 }));
ground.rotation.x = -Math.PI / 2;
ground.receiveShadow = true;
scene.add(ground);

const mascot = buildMascot();
scene.add(mascot.root);
const ctrl = new MascotController(mascot, buildClips());
ctrl.addEventListener('state', (e) => post({ type: 'state', state: e.state }));

// ---------------------------------------------------------------------
//  Kamera & framing: Flutter menentukan posisi kaki (px) dan tinggi (px)
// ---------------------------------------------------------------------
const camera = new THREE.PerspectiveCamera(FOV, 1, 0.1, 100);
const tanHalf = Math.tan((FOV / 2) * Math.PI / 180);
const frame = { feetX: null, feetY: null, height: null };
const cam = { x: 0, y: 2, d: 14, tx: 0, ty: 2, td: 14, ready: false };
let W = 1, H = 1;

// Kamera sedikit menunduk (seperti demo & render Figma) supaya Gyro terlihat
// berdiri DI ATAS piringan, bukan melayang di depannya.
const PITCH = 10 * Math.PI / 180;
const probe = new THREE.PerspectiveCamera(FOV, 1, 0.1, 100);
const pFeet = new THREE.Vector3(), pTop = new THREE.Vector3();

function placeCamera(c, x, y, d) {
  c.position.set(x, y + d * Math.sin(PITCH), d * Math.cos(PITCH));
  c.lookAt(x, y, 0);
  c.updateMatrixWorld(true);
}

function toScreen(v, c) {
  v.project(c);
  return [(v.x + 1) / 2 * W, (1 - v.y) / 2 * H];
}

function computeTarget() {
  const fx = frame.feetX ?? W / 2;
  const fy = frame.feetY ?? H * 0.82;
  const hp = Math.max(40, frame.height ?? H * 0.6);
  probe.aspect = W / H;
  probe.updateProjectionMatrix();
  // tebakan awal (kamera lurus), lalu disempurnakan dengan proyeksi sungguhan
  const u = MODEL_H / hp;
  let d = (H / 2) * u / tanHalf;
  let x = -(fx - W / 2) * u;
  let y = (fy - H / 2) * u;
  for (let i = 0; i < 8; i++) {
    placeCamera(probe, x, y, d);
    const [, feetY] = toScreen(pFeet.set(0, 0, 0), probe);
    const [, topY] = toScreen(pTop.set(0, MODEL_H, 0), probe);
    d *= Math.max(0.2, (feetY - topY) / hp);
    placeCamera(probe, x, y, d);
    const [ax, ay] = toScreen(pFeet.set(0, 0, 0), probe);
    const wpp = (2 * d * tanHalf) / H; // unit dunia per piksel di titik target
    x -= (fx - ax) * wpp;
    y += (fy - ay) * wpp;
  }
  cam.tx = x; cam.ty = y; cam.td = d;
}

function resize() {
  W = Math.max(1, window.innerWidth);
  H = Math.max(1, window.innerHeight);
  renderer.setSize(W, H, false);
  camera.aspect = W / H;
  camera.updateProjectionMatrix();
  computeTarget();
  if (!cam.ready) { cam.x = cam.tx; cam.y = cam.ty; cam.d = cam.td; }
}
window.addEventListener('resize', resize);
resize();

// ---------------------------------------------------------------------
//  Sentuhan: kepala → Pat, badan → Giggle/Poke/Wave, 3x cepat → IdleBounce
//  Jari digeser → mata & kepala mengikuti.
// ---------------------------------------------------------------------
const ray = new THREE.Raycaster();
const ndc = new THREE.Vector2();
const tmp = new THREE.Vector3();
let lastInteract = performance.now();
let taps = [];
let releaseLookAt = 0;
let busy = false; // sedang thinking/answer/talking (dari Flutter)

function isUnder(obj, name) {
  for (let o = obj; o; o = o.parent) if (o.name === name) return true;
  return false;
}

function lookFromPointer(px, py) {
  mascot.nodes.HeadCenter.getWorldPosition(tmp);
  tmp.project(camera);
  const hx = (tmp.x + 1) / 2 * W, hy = (1 - tmp.y) / 2 * H;
  ctrl.lookAt((px - hx) / (W * 0.35), (py - hy) / (H * 0.3));
}

canvas.addEventListener('pointerdown', (ev) => {
  lastInteract = performance.now();
  lookFromPointer(ev.clientX, ev.clientY);
  releaseLookAt = 0;
  ndc.set(ev.clientX / W * 2 - 1, -(ev.clientY / H) * 2 + 1);
  ray.setFromCamera(ndc, camera);
  const hit = ray.intersectObject(mascot.root, true)[0];
  if (!hit) return;
  const now = performance.now();
  taps = taps.filter((t) => now - t < 1200);
  taps.push(now);
  if (busy) { post({ type: 'touch', part: 'busy' }); return; }
  let state;
  let part;
  if (taps.length >= 3) { state = 'happy'; part = 'many'; taps = []; }
  else if (isUnder(hit.object, 'Head')) { state = 'pat'; part = 'head'; }
  else {
    const pool = ['giggle', 'poke', 'hello'];
    state = pool[Math.floor(Math.random() * pool.length)];
    part = 'body';
  }
  ctrl.setState(state);
  post({ type: 'touch', part, state });
});
canvas.addEventListener('pointermove', (ev) => {
  if (ev.pointerType === 'mouse' || ev.buttons || ev.pressure > 0) lookFromPointer(ev.clientX, ev.clientY);
});
const endPointer = () => { releaseLookAt = performance.now() + 1500; };
canvas.addEventListener('pointerup', endPointer);
canvas.addEventListener('pointercancel', endPointer);

// ---------------------------------------------------------------------
//  API untuk Flutter
// ---------------------------------------------------------------------
window.gyro = {
  setState(state) {
    lastInteract = performance.now();
    busy = state === 'thinking' || state === 'answer' || state === 'talking';
    ctrl.setState(state);
  },
  pulse(strength) { lastInteract = performance.now(); ctrl.pulse(strength ?? 1); },
  lookAt(x, y) { ctrl.lookAt(x, y); releaseLookAt = performance.now() + 2500; },
  setFraming(feetX, feetY, height, animate) {
    frame.feetX = feetX; frame.feetY = feetY; frame.height = height;
    computeTarget();
    if (!animate || !cam.ready) { cam.x = cam.tx; cam.y = cam.ty; cam.d = cam.td; }
  },
  pause() { paused = true; },
  resume() { if (paused) { paused = false; clock.getDelta(); requestAnimationFrame(loop); } },
};

// ---------------------------------------------------------------------
//  Loop
// ---------------------------------------------------------------------
const clock = new THREE.Clock();
let paused = false;
let started = false;

function loop() {
  if (paused) return;
  const dt = Math.min(clock.getDelta(), 1 / 20);
  const now = performance.now();

  if (releaseLookAt && now > releaseLookAt) { ctrl.lookAt(0, 0); releaseLookAt = 0; }
  // Tidak ada interaksi ±25 dtk → menyapa lagi
  if (!busy && ctrl.state === 'idle' && now - lastInteract > 25000) {
    lastInteract = now;
    ctrl.setState('hello');
  }

  const k = 1 - Math.exp(-dt * 6);
  cam.x += (cam.tx - cam.x) * k;
  cam.y += (cam.ty - cam.y) * k;
  cam.d += (cam.td - cam.d) * k;
  placeCamera(camera, cam.x, cam.y, cam.d);

  ctrl.update(dt);
  renderer.render(scene, camera);

  if (!started) {
    started = true;
    cam.ready = true;
    post({ type: 'ready' });
  }
  requestAnimationFrame(loop);
}

document.addEventListener('visibilitychange', () => {
  if (document.hidden) window.gyro.pause(); else window.gyro.resume();
});

// Mulai dengan menyapa (Wave → Idle)
ctrl.setState('idle', { fade: 0 });
ctrl.setState('hello', { fade: 0.2 });
requestAnimationFrame(loop);
