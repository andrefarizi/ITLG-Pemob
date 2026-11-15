// =====================================================================
//  Maskot AI — model 3D + rig + klip animasi + controller state
//  Dipakai bersama oleh demo web (browser) dan skrip ekspor GLB (Node).
//  Proporsi diukur dari gambar desain (kepala ±54% tinggi badan).
// =====================================================================
import * as THREE from 'three';

const D2R = Math.PI / 180;

export const PALETTE = {
  white: 0xf7f7f9,
  blueDark: 0x284585,  // panel kiri-atas (gelap)
  blueLight: 0x3a98fc, // panel kanan (terang)
  red: 0xb83e3d,
  redPhone: 0xc8363a,
  charcoal: 0x3a3c42,
  pants: 0x4a494f,
  shoe: 0x3c3b40,
  black: 0x0d0e12,
  yellow: 0xf7bd1d,
};

// ---------- material (lembut seperti mainan vinyl/clay) ----------
function makeMaterials() {
  const P = PALETTE;
  const phys = (color, o = {}) =>
    new THREE.MeshPhysicalMaterial({ color, roughness: 0.5, clearcoat: 0.25, clearcoatRoughness: 0.35, ...o });
  return {
    face: phys(P.white, { name: 'M_Face', roughness: 0.42, clearcoat: 0.35 }),
    capDark: phys(P.blueDark, { name: 'M_CapDark', roughness: 0.55, clearcoat: 0.12 }),
    capLight: phys(P.blueLight, { name: 'M_CapLight', roughness: 0.55, clearcoat: 0.12 }),
    phone: phys(P.redPhone, { name: 'M_Headphone', roughness: 0.38, clearcoat: 0.45 }),
    sweater: phys(P.red, { name: 'M_Sweater', roughness: 0.68, clearcoat: 0.05 }),
    trim: phys(P.charcoal, { name: 'M_Trim', roughness: 0.7, clearcoat: 0.05 }),
    pants: phys(P.pants, { name: 'M_Pants', roughness: 0.75, clearcoat: 0.05 }),
    shoe: phys(P.shoe, { name: 'M_Shoe', roughness: 0.6, clearcoat: 0.2 }),
    hand: phys(P.white, { name: 'M_Hand', roughness: 0.42, clearcoat: 0.35 }),
    logo: phys(0xffffff, { name: 'M_Logo', roughness: 0.55, clearcoat: 0.1 }),
    shirt: phys(0xe4e5ea, { name: 'M_Undershirt', roughness: 0.6, clearcoat: 0.05 }),
    eye: phys(0x141215, { name: 'M_Eye', roughness: 0.3, clearcoat: 0.5, clearcoatRoughness: 0.2 }),
    eyeHi: new THREE.MeshBasicMaterial({ color: 0xffffff, name: 'M_EyeHighlight' }),
    antenna: phys(0x1a1b20, { name: 'M_Antenna', roughness: 0.3, clearcoat: 0.8 }),
    antennaTip: phys(0x15161a, { name: 'M_AntennaTip', roughness: 0.2, clearcoat: 1, emissive: new THREE.Color(P.yellow), emissiveIntensity: 0 }),
    glow: new THREE.MeshBasicMaterial({ color: P.yellow, transparent: true, opacity: 0.5, name: 'M_Glow', depthWrite: false }),
    fx: new THREE.MeshBasicMaterial({ color: P.yellow, name: 'M_FX' }),
    dot: phys(0xffffff, { name: 'M_ThoughtDot', roughness: 0.4, clearcoat: 0.4 }),
  };
}

// ---------- pose istirahat (rest) setiap tulang ----------
// rot = derajat Euler XYZ, pos = posisi lokal, scl = skala lokal
const TINY = 0.001;
export const REST = {
  Root: { pos: [0, 0, 0], rot: [0, 0, 0], scl: [1, 1, 1] },
  Torso: { rot: [0, 0, 0] },
  Head: { rot: [0, 0, 0], scl: [1, 1, 1] },
  Eyes: { rot: [0, 0, 0] },
  EyeL: { scl: [1, 1, 1] },
  EyeR: { scl: [1, 1, 1] },
  ShoulderR: { rot: [0, 0, -18] },
  ShoulderL: { rot: [0, 0, 18] },
  ElbowR: { rot: [-6, 0, 0] },
  ElbowL: { rot: [-6, 0, 0] },
  HandR: { rot: [0, 0, 0] },
  HandL: { rot: [0, 0, 0] },
  LegR: { rot: [0, 0, 0] },
  LegL: { rot: [0, 0, 0] },
  AntennaBase: { rot: [0, 0, 0] },
  Glow: { scl: [TINY, TINY, TINY] },
  Sparks: { scl: [TINY, TINY, TINY], rot: [0, 0, 0] },
  Dot1: { scl: [TINY, TINY, TINY] },
  Dot2: { scl: [TINY, TINY, TINY] },
  Dot3: { scl: [TINY, TINY, TINY] },
  WaveLines: { scl: [TINY, TINY, TINY] },
};

// =====================================================================
//  GEOMETRI
// =====================================================================
const smoothstep = (a, b, x) => { const u = Math.min(1, Math.max(0, (x - a) / (b - a))); return u * u * (3 - 2 * u); };

function roundedPuckProfile(radius, half, bevel, seg = 10) {
  const pts = [new THREE.Vector2(0, -half)];
  const r0 = radius - bevel;
  for (let i = 0; i <= seg; i++) {
    const a = -Math.PI / 2 + (i / seg) * Math.PI;
    pts.push(new THREE.Vector2(r0 + Math.cos(a) * bevel, Math.sin(a) * half));
  }
  pts.push(new THREE.Vector2(0, half));
  return pts;
}

// ---- kepala: superellipsoid (bola agak kotak seperti marshmallow) ----
export const HEAD = { A: 1.12, B: 0.93, C: 0.92, n: 2.45 };
function dirFrom(phiDeg, thetaDeg) {
  // phi = azimut (0 = depan, + ke kiri maskot / kanan layar), theta = sudut dari puncak
  const f = phiDeg * D2R, t = thetaDeg * D2R;
  return new THREE.Vector3(Math.sin(t) * Math.sin(f), Math.cos(t), Math.sin(t) * Math.cos(f));
}
function surfFromDir(d, r = 1) {
  const { A, B, C, n } = HEAD;
  const k = Math.pow(Math.abs(d.x) ** n + Math.abs(d.y) ** n + Math.abs(d.z) ** n, 1 / n);
  return new THREE.Vector3((d.x / k) * A * r, (d.y / k) * B * r, (d.z / k) * C * r);
}
function headPoint(phiDeg, thetaDeg, r = 1) { return surfFromDir(dirFrom(phiDeg, thetaDeg), r); }
function headNormal(p) {
  const { A, B, C, n } = HEAD;
  const g = (v, s) => Math.sign(v) * Math.pow(Math.abs(v / s), n - 1) / s;
  return new THREE.Vector3(g(p.x, A), g(p.y, B), g(p.z, C)).normalize();
}
// titik permukaan kepala pada (x,y) di sisi depan
function frontPoint(x, y) {
  const { A, B, C, n } = HEAD;
  const z = C * Math.pow(Math.max(0, 1 - Math.abs(x / A) ** n - Math.abs(y / B) ** n), 1 / n);
  return new THREE.Vector3(x, y, z);
}
// panel di permukaan kepala, diparametrisasi (phi, theta) → tepi rapi tanpa gerigi
function panelGeometry(phi0, phi1, th0, th1, r, nu, nv, puff = 0) {
  const pos = [], nor = [], idx = [];
  for (let i = 0; i <= nu; i++) {
    const u = i / nu;
    const f = phi0 + (phi1 - phi0) * u;
    const a = th0(f), b = th1(f);
    for (let j = 0; j <= nv; j++) {
      const v = j / nv;
      const t = Math.max(0.01, a + (b - a) * v);
      // "puff": panel sedikit menggembung di tengah seperti bantalan
      const bulge = puff * Math.sin(Math.PI * u) * Math.cos(v * Math.PI / 2);
      const p = headPoint(f, t, r + bulge);
      const nn = headNormal(headPoint(f, t, 1));
      pos.push(p.x, p.y, p.z); nor.push(nn.x, nn.y, nn.z);
    }
  }
  for (let i = 0; i < nu; i++) for (let j = 0; j < nv; j++) {
    const a = i * (nv + 1) + j, b = (i + 1) * (nv + 1) + j, c = a + 1, d = b + 1;
    idx.push(a, c, b, b, c, d);
  }
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  g.setAttribute('normal', new THREE.Float32BufferAttribute(nor, 3));
  g.setIndex(idx);
  return g;
}
// batas bawah panel helm (simetris kiri-kanan). psi = jarak sudut dari depan (0..180)
function capEdge(psi) {
  if (psi <= 14) return 76;
  if (psi <= 85) return 76 + (88 - 76) * smoothstep(14, 85, psi);
  if (psi <= 150) return 88 + (106 - 88) * smoothstep(85, 150, psi);
  return 104;
}
const psiOf = (f) => { const a = ((f % 360) + 360) % 360; return a > 180 ? 360 - a : a; };

// ---- badan sweater (lathe) ----
const TORSO_Z = 0.72;
const torsoCurve = new THREE.SplineCurve([
  // trapesium: sempit di bahu, melebar ke bawah, sudut bawah membulat (seperti desain)
  new THREE.Vector2(0.0, -0.13),
  new THREE.Vector2(0.68, -0.13),
  new THREE.Vector2(0.77, -0.08),
  new THREE.Vector2(0.8, 0.02),
  new THREE.Vector2(0.765, 0.22),
  new THREE.Vector2(0.705, 0.42),
  new THREE.Vector2(0.62, 0.59),
  new THREE.Vector2(0.48, 0.72),
  new THREE.Vector2(0.32, 0.81),
  new THREE.Vector2(0.0, 0.85),
]);
const torsoPts = torsoCurve.getPoints(56).map((p) => new THREE.Vector2(Math.max(0, p.x) * (0.86 + 0.14 * Math.min(1, Math.max(0, (p.y - 0.6) / 0.25))), p.y));
function torsoRadiusAt(y) {
  let best = 0;
  for (let i = 0; i < torsoPts.length - 1; i++) {
    const a = torsoPts[i], b = torsoPts[i + 1];
    if ((y >= a.y && y <= b.y) || (y <= a.y && y >= b.y)) {
      const t = b.y === a.y ? 0 : (y - a.y) / (b.y - a.y);
      best = Math.max(best, a.x + (b.x - a.x) * t);
    }
  }
  return best;
}
function surfaceZ(x, y) {
  const r = torsoRadiusAt(y);
  if (Math.abs(x) >= r) return 0;
  return TORSO_Z * Math.sqrt(r * r - x * x);
}
function wrapOnTorso(geo, lift = 0.012) {
  const pos = geo.attributes.position;
  for (let i = 0; i < pos.count; i++) pos.setZ(i, surfaceZ(pos.getX(i), pos.getY(i)) + lift + pos.getZ(i));
  pos.needsUpdate = true;
  geo.computeVertexNormals();
  return geo;
}
function subdivide(geo, times) {
  let g = geo.index ? geo.toNonIndexed() : geo;
  for (let t = 0; t < times; t++) {
    const p = g.attributes.position.array, out = [];
    for (let i = 0; i < p.length; i += 9) {
      const a = [p[i], p[i + 1], p[i + 2]], b = [p[i + 3], p[i + 4], p[i + 5]], c = [p[i + 6], p[i + 7], p[i + 8]];
      const m = (u, v) => [(u[0] + v[0]) / 2, (u[1] + v[1]) / 2, (u[2] + v[2]) / 2];
      const ab = m(a, b), bc = m(b, c), ca = m(c, a);
      out.push(...a, ...ab, ...ca, ...ab, ...b, ...bc, ...ca, ...bc, ...c, ...ab, ...bc, ...ca);
    }
    g = new THREE.BufferGeometry();
    g.setAttribute('position', new THREE.Float32BufferAttribute(out, 3));
  }
  return g;
}
// lengan baju: profil lathe dihaluskan spline, banyak segmen → tidak bergaris
function sleeveGeometry(pts) {
  const curve = new THREE.SplineCurve(pts.map(([x, y]) => new THREE.Vector2(x, y)));
  const prof = curve.getPoints(40).map((p) => new THREE.Vector2(Math.max(0, p.x), p.y)).reverse();
  return new THREE.LatheGeometry(prof, 48);
}

// Logo dada: 4 potongan jajaran genjang putih, dilacak langsung dari gambar desain
// (koordinat dinormalisasi: lebar logo = 1, pusat = 0,0)
const LOGO_POLYS = [[[0.07, 0.4531], [-0.2452, 0.1162], [-0.4735, 0.1814], [-0.1583, 0.5183]], [[0.1678, 0.301], [0.3635, 0.377], [0.5048, -0.0795], [0.2548, -0.0143]], [[-0.4952, 0.0836], [-0.267, 0.0183], [-0.1583, -0.2969], [-0.3539, -0.3838]], [[0.4721, -0.1882], [0.1678, -0.5143], [-0.0822, -0.449], [0.233, -0.123]]];
function logoGeometry(cx, cy, width = 0.46) {
  const shapes = LOGO_POLYS.map((q) => {
    const sh = new THREE.Shape();
    sh.setFromPoints(q.map(([x, y]) => new THREE.Vector2(cx + x * width, cy + y * width)));
    return sh;
  });
  return new THREE.ShapeGeometry(shapes, 4);
}
function vNeckGeometry(inner = false) {
  const s = new THREE.Shape();
  if (!inner) {
    s.moveTo(-0.33, 0.83);
    s.quadraticCurveTo(-0.18, 0.7, -0.04, 0.565);
    s.quadraticCurveTo(0, 0.54, 0.04, 0.565);
    s.quadraticCurveTo(0.18, 0.7, 0.33, 0.83);
    s.lineTo(-0.33, 0.83);
  } else {
    s.moveTo(-0.21, 0.84);
    s.quadraticCurveTo(-0.11, 0.74, -0.025, 0.665);
    s.quadraticCurveTo(0, 0.65, 0.025, 0.665);
    s.quadraticCurveTo(0.11, 0.74, 0.21, 0.84);
    s.lineTo(-0.21, 0.84);
  }
  return new THREE.ShapeGeometry(s, 16);
}

// =====================================================================
//  BUILD
// =====================================================================
export function buildMascot() {
  const M = makeMaterials();
  const nodes = {};
  const group = (name, parent, pos = [0, 0, 0]) => {
    const o = new THREE.Group();
    o.name = name;
    o.position.set(...pos);
    if (parent) parent.add(o);
    nodes[name] = o;
    return o;
  };
  const mesh = (name, geo, mat, parent, pos = [0, 0, 0], rot = [0, 0, 0], scl = [1, 1, 1]) => {
    const m = new THREE.Mesh(geo, mat);
    m.name = name;
    m.position.set(...pos);
    m.rotation.set(rot[0] * D2R, rot[1] * D2R, rot[2] * D2R);
    m.scale.set(...scl);
    m.castShadow = true;
    m.receiveShadow = true;
    parent.add(m);
    return m;
  };

  const mascot = new THREE.Group();
  mascot.name = 'Mascot';
  const root = group('Root', mascot);

  // ---------------- PINGGUL + KAKI ----------------
  const hips = group('Hips', root, [0, 1.06, 0]);
  const pantsProfile = [
    new THREE.Vector2(0, -0.3), new THREE.Vector2(0.46, -0.3), new THREE.Vector2(0.56, -0.22),
    new THREE.Vector2(0.56, -0.1), new THREE.Vector2(0.56, 0.05), new THREE.Vector2(0, 0.05),
  ];
  mesh('PantsTop', new THREE.LatheGeometry(pantsProfile, 40), M.pants, hips, [0, 0, 0], [0, 0, 0], [1, 1, 0.78]);
  for (const side of ['R', 'L']) {
    const sx = side === 'R' ? -1 : 1;
    const leg = group('Leg' + side, hips, [0.285 * sx, -0.1, 0]);
    mesh('PantsLeg' + side, new THREE.CapsuleGeometry(0.31, 0.24, 10, 24), M.pants, leg, [0, -0.33, 0]);
    mesh('Shoe' + side, new THREE.SphereGeometry(1, 32, 20), M.shoe, leg, [0.02 * sx, -0.73, 0.1], [0, 0, 0], [0.36, 0.23, 0.45]);
  }

  // ---------------- BADAN (SWEATER) ----------------
  const torso = group('Torso', hips, [0, 0, 0]);
  mesh('Sweater', new THREE.LatheGeometry(torsoPts, 64), M.sweater, torso, [0, 0, 0], [0, 0, 0], [1, 1, TORSO_Z]);
  mesh('Collar', new THREE.TorusGeometry(0.31, 0.06, 14, 48), M.trim, torso, [0, 0.82, 0], [90, 0, 0], [1, TORSO_Z * 1.05, 1]);
  mesh('VNeck', wrapOnTorso(subdivide(vNeckGeometry(), 4), 0.008), M.trim, torso);
  mesh('VNeckInner', wrapOnTorso(subdivide(vNeckGeometry(true), 4), 0.014), M.shirt, torso);
  mesh('Logo', wrapOnTorso(subdivide(logoGeometry(0.0, 0.32, 0.47), 3), 0.012), M.logo, torso);

  // ---------------- LENGAN (lengan baju tebal, manset gelap) ----------------
  for (const side of ['R', 'L']) {
    const sx = side === 'R' ? -1 : 1;
    const sh = group('Shoulder' + side, torso, [0.46 * sx, 0.6, 0]);
    // lengan baju atas: satu permukaan mulus (bahu membulat → siku)
    mesh('UpperSleeve' + side, sleeveGeometry([[0, 0.2], [0.11, 0.185], [0.185, 0.13], [0.222, 0.04], [0.222, -0.12], [0.212, -0.3], [0.17, -0.4], [0, -0.43]]), M.sweater, sh);
    const el = group('Elbow' + side, sh, [0, -0.36, 0]);
    // lengan baju bawah: siku membulat → melebar sedikit ke manset
    mesh('LowerSleeve' + side, sleeveGeometry([[0, 0.17], [0.12, 0.15], [0.19, 0.08], [0.205, -0.02], [0.215, -0.2], [0, -0.2]]), M.sweater, el);
    mesh('Cuff' + side, new THREE.CylinderGeometry(0.212, 0.212, 0.13, 48), M.trim, el, [0, -0.25, 0]);
    mesh('CuffEdge' + side, new THREE.TorusGeometry(0.195, 0.03, 12, 48), M.trim, el, [0, -0.315, 0], [90, 0, 0]);
    const hand = group('Hand' + side, el, [0, -0.44, 0]);
    mesh('Palm' + side, new THREE.SphereGeometry(0.215, 28, 20), M.hand, hand, [0, -0.02, 0], [0, 0, 0], [1, 1.02, 0.95]);
    mesh('Thumb' + side, new THREE.SphereGeometry(0.08, 18, 12), M.hand, hand, [-0.07 * sx, 0.04, 0.16]);
  }

  // ---------------- KEPALA ----------------
  // Head (animasi) → HeadLook (tatapan runtime) → HeadCenter (statis)
  const head = group('Head', torso, [0, 0.72, 0]);
  const headLook = group('HeadLook', head);
  const hc = group('HeadCenter', headLook, [0, 0.88, 0]);
  mesh('Face', panelGeometry(0, 360, () => 0, () => 180, 1, 96, 64), M.face, hc);

  // Helm: dua pelat TEBAL seperti bantalan (gelap = kanan maskot, terang = kiri maskot)
  // dipisah jalur putih selebar sama yang naik miring dari dahi ke arah antena (seperti desain).
  // Bentuk pelat = area di mana "jarak ke tepi" > 0; sudut-sudutnya dibulatkan (smooth-min),
  // ketebalan naik membulat dari tepi lalu rata di tengah.
  const capR = 1.004, TILT = 18 * D2R, HALF_W = 0.075, OFF = 0.0; // bidang lewat pusat kepala → lebar jalur rata
  const CAP_T = 0.09, BEVEL = 0.07, CORNER = 0.04;
  const gapN = new THREE.Vector3(Math.cos(TILT), -Math.sin(TILT), 0); // normal bidang jalur
  const xg = (f, t) => headPoint(f, t, capR).dot(gapN) + OFF;
  const bottomDark = (f) => { const a = Math.abs(f); return a <= 25 ? 70 : a <= 95 ? 70 + 18 * smoothstep(25, 95, a) : 88 + 16 * smoothstep(95, 160, a); };
  const bottomLight = (f) => { const a = Math.abs(f); return a <= 12 ? 75 : a <= 85 ? 75 + 14 * smoothstep(12, 85, a) : 89 + 15 * smoothstep(85, 160, a); };
  const smin = (a, b, k) => { const h = Math.max(k - Math.abs(a - b), 0) / k; return Math.min(a, b) - h * h * k * 0.25; };
  // sudut antara tepi jalur dan tepi bawah: dipotong miring (chamfer) lalu dibulatkan, tidak lancip
  const CHAMFER = 0.055;
  // pelat terang: sisi kirinya bersegi seperti segi enam (miring → tegak → tepi bawah)
  const XV = 0.31;
  const sdf = (f, t, sign, bottom) => {
    let a = sign * xg(f, t) - HALF_W;
    if (sign > 0) a = smin(a, headPoint(f, t, capR).x - XV, 0.03);
    const b = (bottom(f) - t) * D2R * 0.95;
    const ch = sign > 0 ? 0.15 : CHAMFER;          // pelat terang: potongan bawah miring lebih panjang
    return smin(smin(a, b, CORNER), (a + b) * 0.7071 - ch * 0.7071, CORNER);
  };
  const puff = (d) => { const u = Math.min(1, Math.max(0, d) / BEVEL); return CAP_T * Math.sqrt(1 - (1 - u) * (1 - u)); };
  // rentang theta (dari atas) di mana sdf > 0 pada kolom phi
  const span = (f, sign, bottom) => {
    let best = -1, bt = 0;
    for (let t = 0.3; t <= 150; t += 0.75) { const v = sdf(f, t, sign, bottom); if (v > best) { best = v; bt = t; } }
    if (best <= 0.002) return null;
    const edge = (lo, hi) => { for (let i = 0; i < 30; i++) { const m = (lo + hi) / 2; if (sdf(f, m, sign, bottom) > 0) hi = m; else lo = m; } return hi; };
    const top = sdf(f, 0.3, sign, bottom) > 0 ? 0.3 : edge(0.3, bt);
    let bot; { let lo = bt, hi = 150; for (let i = 0; i < 30; i++) { const m = (lo + hi) / 2; if (sdf(f, m, sign, bottom) > 0) lo = m; else hi = m; } bot = lo; }
    return [top, bot];
  };
  const plate = (name, mat, f0, f1, sign, bottom) => {
    const cols = [];
    for (let i = 0; i <= 220; i++) { const f = f0 + ((f1 - f0) * i) / 220; const r = span(f, sign, bottom); if (r && r[1] - r[0] > 0.3) cols.push([f, ...r]); }
    const nv = 34, pos = [], idx = [];
    for (const [f, a, b] of cols) for (let j = 0; j <= nv; j++) {
      const s = 0.5 - 0.5 * Math.cos((Math.PI * j) / nv);   // baris rapat di dekat tepi
      const t = a + (b - a) * s;
      const p = headPoint(f, t, capR + puff(sdf(f, t, sign, bottom)));
      pos.push(p.x, p.y, p.z);
    }
    for (let i = 0; i < cols.length - 1; i++) for (let j = 0; j < nv; j++) {
      const a = i * (nv + 1) + j, b = (i + 1) * (nv + 1) + j;
      idx.push(a, a + 1, b, b, a + 1, b + 1);
    }
    const g = new THREE.BufferGeometry();
    g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
    g.setIndex(idx);
    g.computeVertexNormals();
    mesh(name, g, mat, hc);
  };
  plate('CapPanelLight', M.capLight, 0.3, 179.7, 1, bottomLight);
  plate('CapPanelDark', M.capDark, -179.7, 179.7, -1, bottomDark);

  // Mata: hitam bulat mengilap
  // Eyes (animasi) → EyesLook (tatapan runtime) → EyeL/EyeR (kedip di klip) → EyeLBlink (kedip runtime)
  const eyes = group('Eyes', hc);
  const eyesLook = group('EyesLook', eyes);
  const eyeGeo = new THREE.SphereGeometry(1, 40, 28);
  eyeGeo.scale(0.18, 0.215, 0.08);
  for (const side of ['R', 'L']) {
    const sx = side === 'R' ? -1 : 1;
    const p = frontPoint(0.42 * sx, -0.24);
    const nrm = headNormal(p);
    const eye = group('Eye' + side, eyesLook);
    eye.position.copy(p).addScaledVector(nrm, -0.018);
    eye.quaternion.setFromUnitVectors(new THREE.Vector3(0, 0, 1), nrm);
    const blink = group('Eye' + side + 'Blink', eye);
    mesh('EyeBall' + side, eyeGeo, M.eye, blink);
    mesh('EyeShine' + side, new THREE.SphereGeometry(0.05, 16, 12), M.eyeHi, blink, [0.06, 0.08, 0.062], [0, 0, 0], [1.1, 1.15, 0.45]);
  }

  // Headphone merah besar
  const puck = new THREE.LatheGeometry(roundedPuckProfile(0.37, 0.15, 0.1, 12), 56);
  for (const side of ['R', 'L']) {
    const sx = side === 'R' ? -1 : 1;
    const hp = group('Headphone' + side, hc, [1.09 * sx, -0.2, -0.02]);
    mesh('Cup' + side, puck, M.phone, hp, [0.07 * sx, 0, 0], [0, 0, 90]);
  }

  // Antena: kerucut hitam + bola, di panel terang (kanan atas layar)
  const aPos = headPoint(48, 36, capR + 0.03);
  const mount = group('AntennaMount', hc, aPos.toArray());
  mount.quaternion.setFromUnitVectors(new THREE.Vector3(0, 1, 0), new THREE.Vector3(0.55, 1, -0.05).normalize());
  const antBase = group('AntennaBase', mount);
  mesh('AntennaCone', new THREE.CylinderGeometry(0.04, 0.15, 0.3, 24), M.antenna, antBase, [0, 0.12, 0]);
  const tip = group('AntennaTip', antBase, [0, 0.36, 0]);
  mesh('AntennaBall', new THREE.SphereGeometry(0.14, 28, 18), M.antennaTip, tip);
  const glow = group('Glow', tip);
  mesh('GlowBall', new THREE.SphereGeometry(0.22, 24, 16), M.glow, glow).castShadow = false;
  const sparks = group('Sparks', tip);
  for (let i = 0; i < 6; i++) {
    const sp = new THREE.Group();
    sp.rotation.z = (i / 6) * Math.PI * 2 + 0.3;
    sparks.add(sp);
    mesh('Spark' + i, new THREE.CapsuleGeometry(0.026, 0.11, 4, 8), M.fx, sp, [0, 0.34, 0]).castShadow = false;
  }

  // Gelembung pikiran
  const dots = group('ThoughtDots', hc, [1.12, 0.9, 0.3]);
  [[0, 0, 0.07], [0.17, 0.2, 0.1], [0.42, 0.45, 0.15]].forEach(([x, y, r], i) => {
    const d = group('Dot' + (i + 1), dots, [x, y, 0]);
    mesh('DotBall' + (i + 1), new THREE.SphereGeometry(r, 20, 14), M.dot, d);
  });

  // Garis kuning saat melambai (kiri atas tangan, seperti di gambar)
  const wl = group('WaveLines', hc, [-1.45, -0.15, 0.35]);
  [[28, 0.42, 0.13], [62, 0.44, 0.15], [98, 0.42, 0.12]].forEach(([deg, dist, len], i) => {
    const holder = new THREE.Group();
    holder.rotation.z = deg * D2R;
    wl.add(holder);
    mesh('WaveLine' + i, new THREE.CapsuleGeometry(0.032, len, 4, 8), M.fx, holder, [0, dist, 0]).castShadow = false;
  });

  applyRest(nodes);
  return { root: mascot, nodes, materials: M };
}

export function applyRest(nodes) {
  for (const [name, r] of Object.entries(REST)) {
    const n = nodes[name];
    if (!n) continue;
    if (r.rot) n.rotation.set(r.rot[0] * D2R, r.rot[1] * D2R, r.rot[2] * D2R);
    if (r.pos) n.position.set(...r.pos);
    if (r.scl) n.scale.set(...r.scl);
  }
}

// =====================================================================
//  ANIMASI — keyframe pose, diinterpolasi spline halus (tanpa patah-patah)
// =====================================================================
const S = (v) => [v, v, v];
const k = (t, v) => [t, v];
const add = (a, b) => a.map((v, i) => v + b[i]);

// Pose lengan hasil "solve" agar tangan tepat di posisi yang diinginkan
export const P = {
  // melambai: tangan di samping pipi, depan headphone (seperti gambar)
  waveShoulder: [32, 22, -130],
  waveElbow: [0, 0, -41],
  // berpikir: tangan kiri di dagu
  thinkShoulderL: [-88, -2, -6],
  thinkElbowL: [-43, 0, -11],
  // mendengarkan: tangan kanan memegang headphone
  listenShoulderR: [-27, 20, -92],
  listenElbowR: [0, 0, -14],
};

// lintasan lompat balistik (fungsi waktu): lepas landas tegas, melayang di puncak, jatuh cepat
const hop = (...segs) => (t) => { for (const [a, b, h] of segs) if (t > a && t < b) { const u = (t - a) / (b - a); return [0, 4 * h * u * (1 - u), 0]; } return [0, 0, 0]; };
const easeIO = (u) => { u = Math.min(1, Math.max(0, u)); return u < 0.5 ? 2 * u * u : 1 - 2 * (1 - u) * (1 - u); };
// kepala besar tidak ikut gepeng saat badan jongkok/meregang: skala kepala melawan skala badan
const headComp = (rootKeys, c = 0.72) => rootKeys.map(([t, v]) => [t, v.map((x) => Math.pow(1 / x, c))]);
// kedipan pada waktu tertentu
const blinks = (dur, ...ts) => { const out = [k(0, S(1))]; for (const t of ts) out.push(k(t - 0.03, S(1)), k(t + 0.06, [1, 0.1, 1]), k(t + 0.18, S(1))); out.push(k(dur, S(1))); return out; };
// geser kunci tengah sebesar d detik: bagian tubuh ini bergerak menyusul (overlap), tidak serentak
const late = (keys, d) => keys.map(([t, v], i) => [i === 0 || i === keys.length - 1 ? t : t + d, v]);
// cerminkan kunci rotasi lengan/kaki kanan → kiri
const mir = (keys) => keys.map(([t, v]) => [t, [v[0], -v[1], -v[2]]]);
const RS = [0, 0, -18], RE = [-6, 0, 0]; // pose istirahat bahu & siku kanan

export function makeClipDefs() {
  const wE = P.waveElbow, wA = add(wE, [0, 0, 24]), wB = add(wE, [0, 0, 2]);
  const defs = {
    // ---------- IDLE: napas, berat badan berpindah, melirik, lengan berayun ----------
    Idle: {
      dur: 8, loop: true,
      keys: {
        'Root.scl': [k(0, S(1)), k(1.33, [1.014, 0.984, 1.014]), k(2.67, S(1)), k(4, [1.014, 0.984, 1.014]), k(5.33, S(1)), k(6.67, [1.014, 0.984, 1.014]), k(8, S(1))],
        'Root.rot': [k(0, [0, 0, 1.6]), k(4, [0, 0, -1.6]), k(8, [0, 0, 1.6])],
        'Torso.rot': [k(0, [0, 1.5, -1.6]), k(2, [1.5, 0, 0]), k(4, [0.5, -2.5, 1.8]), k(6, [1.5, 0, 0]), k(8, [0, 1.5, -1.6])],
        'Head.rot': [k(0, [0, 3, -3]), k(1.6, [2, 6, 1]), k(3.2, [-2, -4, 3]), k(4.5, [0, -9, 5]), k(5.5, [1, -7, 4]), k(6.8, [-1, 2, -2]), k(8, [0, 3, -3])],
        'Eyes.rot': [k(0, [0, 0, 0]), k(3.0, [0, 0, 0]), k(3.35, [0, -9, 0]), k(4.7, [0, -10, 0]), k(5.3, [0, 0, 0]), k(8, [0, 0, 0])],
        'ShoulderR.rot': [k(0, [2, 0, -18]), k(2, [-4, 0, -22]), k(4, [3, 0, -17]), k(6, [-3, 0, -21]), k(8, [2, 0, -18])],
        'ShoulderL.rot': [k(0, [-3, 0, 21]), k(2, [3, 0, 17]), k(4, [-4, 0, 22]), k(6, [2, 0, 18]), k(8, [-3, 0, 21])],
        'ElbowR.rot': [k(0, [-6, 0, 0]), k(2, [-14, 0, 0]), k(4, [-6, 0, 0]), k(6, [-13, 0, 0]), k(8, [-6, 0, 0])],
        'ElbowL.rot': [k(0, [-13, 0, 0]), k(2, [-6, 0, 0]), k(4, [-14, 0, 0]), k(6, [-6, 0, 0]), k(8, [-13, 0, 0])],
        'AntennaBase.rot': [k(0, [0, 0, 3]), k(1.5, [2, 0, -5]), k(2.9, [-1, 0, 5]), k(4.4, [1, 0, -6]), k(5.6, [0, 0, 4]), k(6.9, [1, 0, -3]), k(8, [0, 0, 3])],
        'EyeL.scl': blinks(8, 2.6, 6.2, 6.5),
        'EyeR.scl': blinks(8, 2.6, 6.2, 6.5),
      },
    },

    // ---------- SELINGAN IDLE 1: celingak-celinguk (mata dulu, kepala menyusul) ----------
    IdleLook: {
      dur: 2.9, loop: false,
      keys: {
        'Eyes.rot': [k(0, [0, 0, 0]), k(0.22, [0, -9, 0]), k(0.95, [0, -9, 0]), k(1.2, [0, 9, 0]), k(1.95, [0, 9, 0]), k(2.35, [0, 0, 0]), k(2.9, [0, 0, 0])],
        'Head.rot': [k(0, [0, 0, 0]), k(0.5, [-3, -21, -5]), k(1.0, [-3, -23, -5]), k(1.5, [-3, 21, 5]), k(2.05, [-3, 23, 5]), k(2.6, [0, 0, 0]), k(2.9, [0, 0, 0])],
        'Torso.rot': [k(0, [0, 0, 0]), k(0.6, [0, -9, 0]), k(1.05, [0, -10, 0]), k(1.6, [0, 9, 0]), k(2.1, [0, 10, 0]), k(2.7, [0, 0, 0]), k(2.9, [0, 0, 0])],
        'Root.rot': [k(0, [0, 0, 0]), k(0.6, [0, 0, 1.5]), k(1.1, [0, 0, 1.5]), k(1.65, [0, 0, -1.5]), k(2.1, [0, 0, -1.5]), k(2.7, [0, 0, 0]), k(2.9, [0, 0, 0])],
        'ShoulderR.rot': [k(0, RS), k(0.6, [-6, 0, -24]), k(1.6, [6, 0, -16]), k(2.7, RS), k(2.9, RS)],
        'ShoulderL.rot': [k(0, [0, 0, 18]), k(0.6, [6, 0, 16]), k(1.6, [-6, 0, 24]), k(2.7, [0, 0, 18]), k(2.9, [0, 0, 18])],
        'AntennaBase.rot': [k(0, [0, 0, 0]), k(0.4, [0, 0, -10]), k(0.75, [0, 0, 6]), k(1.05, [0, 0, 0]), k(1.4, [0, 0, 12]), k(1.75, [0, 0, -6]), k(2.1, [0, 0, 0]), k(2.5, [0, 0, -7]), k(2.75, [0, 0, 3]), k(2.9, [0, 0, 0])],
        'EyeL.scl': blinks(2.9, 1.08, 2.3),
        'EyeR.scl': blinks(2.9, 1.08, 2.3),
      },
    },

    // ---------- SELINGAN IDLE 2: kepala miring penasaran "hm?" ----------
    IdleTilt: {
      dur: 2.3, loop: false,
      keys: {
        'Root.scl': [k(0, S(1)), k(0.15, [1.03, 0.96, 1.03]), k(0.36, [0.98, 1.03, 0.98]), k(0.6, S(1)), k(2.3, S(1))],
        'Head.rot': [k(0, [0, 0, 0]), k(0.34, [-4, 5, 18]), k(0.95, [-4, 6, 20]), k(1.3, [-2, -4, -13]), k(1.75, [-2, -5, -14]), k(2.12, [0, 0, 0]), k(2.3, [0, 0, 0])],
        'Torso.rot': [k(0, [0, 0, 0]), k(0.4, [0, 2, -5]), k(0.95, [0, 2, -5]), k(1.35, [0, -2, 4]), k(1.75, [0, -2, 4]), k(2.15, [0, 0, 0]), k(2.3, [0, 0, 0])],
        'Root.rot': [k(0, [0, 0, 0]), k(0.4, [0, 0, -1.5]), k(0.95, [0, 0, -1.5]), k(1.35, [0, 0, 1.2]), k(1.75, [0, 0, 1.2]), k(2.15, [0, 0, 0]), k(2.3, [0, 0, 0])],
        'ShoulderL.rot': [k(0, [0, 0, 18]), k(0.4, [4, 0, 28]), k(0.95, [4, 0, 28]), k(1.4, [0, 0, 18]), k(2.3, [0, 0, 18])],
        'AntennaBase.rot': [k(0, [0, 0, 0]), k(0.3, [0, 0, -15]), k(0.5, [0, 0, 9]), k(0.7, [0, 0, -5]), k(0.92, [0, 0, 0]), k(1.25, [0, 0, 13]), k(1.47, [0, 0, -7]), k(1.7, [0, 0, 3]), k(2.0, [0, 0, 0]), k(2.3, [0, 0, 0])],
        'EyeL.scl': [k(0, S(1)), k(0.32, [1.06, 1.1, 1]), k(0.9, [1.06, 1.1, 1]), k(1.03, [1, 0.1, 1]), k(1.15, S(1)), k(1.75, S(1)), k(1.84, [1, 0.1, 1]), k(1.96, S(1)), k(2.3, S(1))],
        'EyeR.scl': [k(0, S(1)), k(0.32, [1.06, 1.1, 1]), k(0.9, [1.06, 1.1, 1]), k(1.03, [1, 0.1, 1]), k(1.15, S(1)), k(1.75, S(1)), k(1.84, [1, 0.1, 1]), k(1.96, S(1)), k(2.3, S(1))],
      },
    },

    // ---------- SELINGAN IDLE 3: dua lompatan kecil riang ----------
    IdleBounce: {
      dur: 1.8, loop: false,
      keys: {
        'Root.pos': hop([0.22, 0.56, 0.16], [0.72, 1.08, 0.22]),
        'Root.scl': [k(0, S(1)), k(0.16, [1.05, 0.93, 1.05]), k(0.32, [0.97, 1.04, 0.97]), k(0.5, S(1)), k(0.62, [1.06, 0.92, 1.06]), k(0.8, [0.96, 1.05, 0.96]), k(1.0, S(1)), k(1.14, [1.06, 0.92, 1.06]), k(1.32, [0.98, 1.02, 0.98]), k(1.5, S(1)), k(1.8, S(1))],
        'Head.rot': [k(0, [0, 0, 0]), k(0.16, [6, 0, 0]), k(0.4, [-6, 0, 8]), k(0.62, [5, 0, 0]), k(0.9, [-7, 0, -8]), k(1.14, [6, 0, 0]), k(1.4, [-2, 0, 0]), k(1.8, [0, 0, 0])],
        'Torso.rot': [k(0, [0, 0, 0]), k(0.16, [6, 0, 0]), k(0.4, [-3, 0, -2]), k(0.62, [5, 0, 0]), k(0.9, [-3, 0, 2]), k(1.14, [6, 0, 0]), k(1.4, [0, 0, 0]), k(1.8, [0, 0, 0])],
        'ShoulderR.rot': [k(0, RS), k(0.16, [8, 0, -14]), k(0.4, [0, 0, -60]), k(0.62, [6, 0, -20]), k(0.9, [0, 0, -68]), k(1.14, [6, 0, -22]), k(1.45, RS), k(1.8, RS)],
        'LegR.rot': [k(0, [0, 0, 0]), k(0.22, [0, 0, 0]), k(0.4, [-8, 0, -8]), k(0.56, [0, 0, 0]), k(0.72, [0, 0, 0]), k(0.9, [-10, 0, -10]), k(1.08, [0, 0, 0]), k(1.8, [0, 0, 0])],
        'AntennaBase.rot': [k(0, [0, 0, 0]), k(0.2, [0, 0, -8]), k(0.4, [0, 0, 14]), k(0.6, [0, 0, -12]), k(0.9, [0, 0, 16]), k(1.14, [0, 0, -14]), k(1.32, [0, 0, 8]), k(1.5, [0, 0, -4]), k(1.8, [0, 0, 0])],
        'EyeL.scl': [k(0, S(1)), k(0.16, [1.05, 0.6, 1]), k(0.4, [1.08, 1.1, 1]), k(0.62, [1.05, 0.7, 1]), k(0.9, [1.08, 1.1, 1]), k(1.14, [1.05, 0.6, 1]), k(1.4, S(1)), k(1.8, S(1))],
        'EyeR.scl': [k(0, S(1)), k(0.16, [1.05, 0.6, 1]), k(0.4, [1.08, 1.1, 1]), k(0.62, [1.05, 0.7, 1]), k(0.9, [1.08, 1.1, 1]), k(1.14, [1.05, 0.6, 1]), k(1.4, S(1)), k(1.8, S(1))],
      },
    },

    // ---------- SELINGAN IDLE 4: meregangkan badan lalu geleng-geleng ----------
    IdleStretch: {
      dur: 3.0, loop: false,
      keys: {
        'Root.scl': [k(0, S(1)), k(0.3, [1.03, 0.96, 1.03]), k(0.9, [0.96, 1.06, 0.96]), k(1.6, [0.96, 1.06, 0.96]), k(2.0, [1.04, 0.95, 1.04]), k(2.3, S(1)), k(3, S(1))],
        'Torso.rot': [k(0, [0, 0, 0]), k(0.3, [4, 0, 0]), k(0.9, [-8, 0, -2]), k(1.6, [-9, 0, 2]), k(2.0, [4, 0, 0]), k(2.4, [0, 0, 0]), k(3, [0, 0, 0])],
        'Head.rot': [k(0, [0, 0, 0]), k(0.3, [5, 0, 0]), k(0.9, [-12, 0, -5]), k(1.6, [-13, 0, 5]), k(2.0, [6, 0, 0]), k(2.2, [2, -10, 0]), k(2.36, [2, 10, 0]), k(2.52, [2, -6, 0]), k(2.68, [1, 4, 0]), k(2.85, [0, 0, 0]), k(3, [0, 0, 0])],
        'ShoulderR.rot': [k(0, RS), k(0.35, [10, 0, -30]), k(0.9, [20, 0, -96]), k(1.25, [22, 0, -104]), k(1.6, [20, 0, -98]), k(2.0, [6, 0, -30]), k(2.3, [0, 0, -14]), k(3, RS)],
        'ElbowR.rot': [k(0, RE), k(0.35, [-30, 0, 0]), k(0.9, [0, 0, -8]), k(1.6, [0, 0, -4]), k(2.0, [-18, 0, 0]), k(3, RE)],
        'AntennaBase.rot': [k(0, [0, 0, 0]), k(0.9, [0, 0, -8]), k(1.6, [0, 0, -10]), k(2.0, [0, 0, 12]), k(2.2, [0, 0, -12]), k(2.36, [0, 0, 12]), k(2.52, [0, 0, -8]), k(2.68, [0, 0, 5]), k(2.85, [0, 0, 0]), k(3, [0, 0, 0])],
        'EyeL.scl': [k(0, S(1)), k(0.6, [1, 0.9, 1]), k(0.85, [1.08, 0.14, 1]), k(1.65, [1.08, 0.14, 1]), k(1.9, S(1)), k(2.45, [1, 0.1, 1]), k(2.57, S(1)), k(3, S(1))],
        'EyeR.scl': [k(0, S(1)), k(0.6, [1, 0.9, 1]), k(0.85, [1.08, 0.14, 1]), k(1.65, [1.08, 0.14, 1]), k(1.9, S(1)), k(2.45, [1, 0.1, 1]), k(2.57, S(1)), k(3, S(1))],
      },
    },

    // ---------- WAVE: "Halo!" — loncat kecil, kepala miring, melambai berirama ----------
    Wave: {
      dur: 3.2, loop: false,
      keys: {
        'Root.pos': hop([0.2, 0.48, 0.1]),
        'Root.scl': [k(0, S(1)), k(0.16, [1.05, 0.93, 1.05]), k(0.3, [0.97, 1.04, 0.97]), k(0.52, [1.05, 0.94, 1.05]), k(0.72, S(1)), k(0.94, [1.014, 0.984, 1.014]), k(1.16, S(1)), k(1.38, [1.014, 0.984, 1.014]), k(1.6, S(1)), k(1.82, [1.014, 0.984, 1.014]), k(2.04, S(1)), k(2.26, [1.014, 0.984, 1.014]), k(2.5, S(1)), k(2.86, [1.02, 0.975, 1.02]), k(3.05, S(1)), k(3.2, S(1))],
        'Root.rot': [k(0, [0, 0, 0]), k(0.52, [0, 0, 1.6]), k(2.4, [0, 0, 1.6]), k(2.86, [0, 0, -0.6]), k(3.2, [0, 0, 0])],
        'Torso.rot': [k(0, [0, 0, 0]), k(0.16, [4, 0, 2]), k(0.5, [-2, -6, -2]), k(1.4, [-1, -4, -1]), k(2.4, [-2, -6, -2]), k(2.86, [2, 0, 0]), k(3.2, [0, 0, 0])],
        'Head.rot': [k(0, [0, 0, 0]), k(0.16, [6, 0, 5]), k(0.5, [-5, 6, -20]), k(0.72, [-4, 5, -15]), k(0.94, [-5, 7, -20]), k(1.16, [-4, 5, -15]), k(1.38, [-5, 7, -20]), k(1.6, [-4, 5, -15]), k(1.82, [-5, 7, -20]), k(2.04, [-4, 5, -15]), k(2.26, [-5, 7, -19]), k(2.5, [-3, 5, -17]), k(2.86, [4, 0, 3]), k(3.2, [0, 0, 0])],
        'ShoulderR.rot': [k(0, RS), k(0.16, [8, 0, -12]), k(0.46, P.waveShoulder), k(2.42, P.waveShoulder), k(2.86, [4, 0, -26]), k(3.2, RS)],
        'ElbowR.rot': [k(0, RE), k(0.16, [-12, 0, 0]), k(0.46, wE), k(0.72, wA), k(0.94, wB), k(1.16, wA), k(1.38, wB), k(1.6, wA), k(1.82, wB), k(2.04, wA), k(2.26, wB), k(2.42, wE), k(2.86, [-12, 0, 0]), k(3.2, RE)],
        'HandR.rot': [k(0, [0, 0, 0]), k(0.46, [0, -20, 0]), k(0.78, [0, -20, 16]), k(1.0, [0, -20, -14]), k(1.22, [0, -20, 16]), k(1.44, [0, -20, -14]), k(1.66, [0, -20, 16]), k(1.88, [0, -20, -14]), k(2.1, [0, -20, 16]), k(2.42, [0, -20, 0]), k(3.2, [0, 0, 0])],
        'ShoulderL.rot': [k(0, [0, 0, 18]), k(0.2, [8, 0, 28]), k(0.5, [4, 0, 34]), k(0.94, [4, 0, 28]), k(1.38, [4, 0, 34]), k(1.82, [4, 0, 28]), k(2.26, [4, 0, 33]), k(2.86, [0, 0, 16]), k(3.2, [0, 0, 18])],
        'ElbowL.rot': [k(0, RE), k(0.5, [-12, 0, 0]), k(2.4, [-12, 0, 0]), k(3.2, RE)],
        'WaveLines.scl': [k(0, S(TINY)), k(0.56, S(TINY)), k(0.72, S(1.1)), k(0.94, S(0.75)), k(1.16, S(1.1)), k(1.38, S(0.75)), k(1.6, S(1.1)), k(1.82, S(0.75)), k(2.04, S(1.1)), k(2.26, S(0.8)), k(2.42, S(TINY)), k(3.2, S(TINY))],
        'AntennaBase.rot': [k(0, [0, 0, 0]), k(0.2, [0, 0, -8]), k(0.5, [0, 0, 16]), k(0.72, [0, 0, -8]), k(0.94, [0, 0, 7]), k(1.16, [0, 0, -5]), k(1.38, [0, 0, 6]), k(1.6, [0, 0, -5]), k(1.82, [0, 0, 6]), k(2.04, [0, 0, -4]), k(2.4, [0, 0, 0]), k(2.86, [0, 0, -10]), k(3.02, [0, 0, 5]), k(3.2, [0, 0, 0])],
        'EyeL.scl': [k(0, S(1)), k(0.16, [1.04, 0.65, 1]), k(0.48, [1.08, 1.1, 1]), k(0.8, [1.05, 0.9, 1]), k(2.3, [1.05, 0.9, 1]), k(2.52, [1, 0.1, 1]), k(2.66, S(1)), k(3.2, S(1))],
        'EyeR.scl': [k(0, S(1)), k(0.16, [1.04, 0.65, 1]), k(0.48, [1.08, 1.1, 1]), k(0.8, [1.05, 0.9, 1]), k(2.3, [1.05, 0.9, 1]), k(2.52, [1, 0.1, 1]), k(2.66, S(1)), k(3.2, S(1))],
      },
    },

    // ---------- LISTEN: tangan memegang headphone, kepala miring, mengangguk-angguk ----------
    Listen: {
      dur: 3.2, loop: true,
      keys: {
        'Root.rot': [k(0, [0, 0, -1]), k(1.6, [0, 0, 1]), k(3.2, [0, 0, -1])],
        'Torso.rot': [k(0, [4, -4, -3]), k(1.6, [6, -2, -4]), k(3.2, [4, -4, -3])],
        'Head.rot': [k(0, [6, -10, 12]), k(0.55, [12, -10, 12]), k(0.8, [6, -9, 13]), k(1.05, [11, -9, 13]), k(1.3, [6, -8, 13]), k(2.2, [8, -6, 15]), k(3.2, [6, -10, 12])],
        'Eyes.rot': [k(0, [-4, -6, 0]), k(1.6, [-5, -3, 0]), k(3.2, [-4, -6, 0])],
        'ShoulderR.rot': [k(0, P.listenShoulderR), k(1.6, add(P.listenShoulderR, [1, 0, 2])), k(3.2, P.listenShoulderR)],
        'ElbowR.rot': [k(0, P.listenElbowR), k(1.6, add(P.listenElbowR, [0, 0, -3])), k(3.2, P.listenElbowR)],
        'HandR.rot': [k(0, [0, 20, 10]), k(0.8, [0, 20, 16]), k(1.6, [0, 20, 10]), k(2.4, [0, 20, 16]), k(3.2, [0, 20, 10])],
        'ShoulderL.rot': [k(0, [2, 0, 18]), k(1.6, [5, 0, 21]), k(3.2, [2, 0, 18])],
        'ElbowL.rot': [k(0, [-10, 0, 0]), k(1.6, [-16, 0, 0]), k(3.2, [-10, 0, 0])],
        'Root.scl': [k(0, S(1)), k(0.55, [1.012, 0.986, 1.012]), k(0.8, S(1)), k(1.05, [1.012, 0.986, 1.012]), k(1.3, S(1)), k(2.2, [1.01, 0.988, 1.01]), k(3.2, S(1))],
        'AntennaBase.rot': [k(0, [0, 0, 0]), k(0.55, [0, 0, -7]), k(0.8, [0, 0, 5]), k(1.05, [0, 0, -6]), k(1.3, [0, 0, 4]), k(1.7, [0, 0, 0]), k(2.4, [0, 0, -4]), k(3.2, [0, 0, 0])],
        'EyeL.scl': blinks(3.2, 2.1),
        'EyeR.scl': blinks(3.2, 2.1),
      },
    },

    // ---------- THINK: tangan di dagu, mata melirik atas, badan bergoyang pelan ----------
    Think: {
      dur: 3.6, loop: true,
      keys: {
        'Root.rot': [k(0, [0, 0, 1.4]), k(1.8, [0, 0, -1.4]), k(3.6, [0, 0, 1.4])],
        'Torso.rot': [k(0, [2, 5, -3]), k(1.8, [3, 2, -4]), k(3.6, [2, 5, -3])],
        'Head.rot': [k(0, [-9, 10, 9]), k(1.8, [-11, 3, 12]), k(3.6, [-9, 10, 9])],
        'Eyes.rot': [k(0, [-12, 10, 0]), k(0.9, [-12, 10, 0]), k(1.25, [-13, -8, 0]), k(2.5, [-13, -8, 0]), k(2.85, [-12, 10, 0]), k(3.6, [-12, 10, 0])],
        'ShoulderL.rot': [k(0, P.thinkShoulderL), k(1.8, add(P.thinkShoulderL, [-2, 0, 2])), k(3.6, P.thinkShoulderL)],
        'ElbowL.rot': [k(0, P.thinkElbowL), k(1.8, add(P.thinkElbowL, [-2, 0, 0])), k(3.6, P.thinkElbowL)],
        'HandL.rot': [k(0, [0, 0, 0]), k(0.22, [12, 0, 0]), k(0.44, [0, 0, 0]), k(0.66, [12, 0, 0]), k(0.88, [0, 0, 0]), k(3.6, [0, 0, 0])],
        'ShoulderR.rot': [k(0, [6, 0, -16]), k(1.8, [9, 0, -20]), k(3.6, [6, 0, -16])],
        'ElbowR.rot': [k(0, [-10, 0, 0]), k(1.8, [-16, 0, 0]), k(3.6, [-10, 0, 0])],
        'Root.scl': [k(0, S(1)), k(1.8, [1.012, 0.986, 1.012]), k(3.6, S(1))],
        'AntennaBase.rot': [k(0, [0, 0, 0]), k(0.45, [0, 0, -8]), k(0.9, [0, 0, 7]), k(1.35, [0, 0, -7]), k(1.8, [0, 0, 6]), k(2.25, [0, 0, -7]), k(2.7, [0, 0, 6]), k(3.15, [0, 0, -5]), k(3.6, [0, 0, 0])],
        'Dot1.scl': [k(0, S(TINY)), k(0.2, S(TINY)), k(0.42, S(1.15)), k(0.58, S(1)), k(2.9, S(1)), k(3.25, S(TINY)), k(3.6, S(TINY))],
        'Dot2.scl': [k(0, S(TINY)), k(0.55, S(TINY)), k(0.77, S(1.15)), k(0.93, S(1)), k(2.9, S(1)), k(3.25, S(TINY)), k(3.6, S(TINY))],
        'Dot3.scl': [k(0, S(TINY)), k(0.9, S(TINY)), k(1.12, S(1.15)), k(1.28, S(1)), k(2.0, S(0.9)), k(2.5, S(1.05)), k(2.9, S(1)), k(3.25, S(TINY)), k(3.6, S(TINY))],
        'EyeL.scl': blinks(3.6, 1.12, 2.72),
        'EyeR.scl': blinks(3.6, 1.12, 2.72),
      },
    },

    // ---------- EUREKA: dapat jawaban! lompat gembira (tanpa putaran) ----------
    // kaget "aha" → jongkok, lengan ke belakang → melesat: dada naik dulu, lengan menyusul ke atas,
    // kepala menengadah belakangan → di puncak satu kaki menendang ke depan, satu ke belakang →
    // jatuh (lengan tertinggal di atas) → mendarat empuk, lengan & kepala menyusul turun →
    // memantul sekali lagi sambil bersorak → kembali santai.
    Eureka: {
      dur: 2.6, loop: false,
      keys: {
        'Root.pos': hop([0.40, 1.04, 0.8], [1.32, 1.60, 0.16]),
        'Root.rot': [k(0, [0, 0, 0]), k(0.4, [0, 0, 0]), k(0.72, [0, 0, 1.5]), k(1.04, [0, 0, 0]), k(1.46, [0, 0, -1.5]), k(1.6, [0, 0, 0]), k(2.6, [0, 0, 0])],
        'Root.scl': [k(0, S(1)), k(0.1, [0.98, 1.03, 0.98]), k(0.34, [1.1, 0.8, 1.1]), k(0.46, [0.93, 1.13, 0.93]), k(0.62, [0.98, 1.03, 0.98]), k(0.72, [1.01, 0.99, 1.01]), k(0.96, [0.96, 1.07, 0.96]), k(1.13, [1.08, 0.86, 1.08]), k(1.3, [0.96, 1.06, 0.96]), k(1.46, S(1)), k(1.58, [0.98, 1.03, 0.98]), k(1.68, [1.06, 0.91, 1.06]), k(1.84, [0.98, 1.03, 0.98]), k(2.0, [1.015, 0.985, 1.015]), k(2.2, S(1)), k(2.6, S(1))],
        'Torso.rot': [k(0, [0, 0, 0]), k(0.1, [-3, 0, 0]), k(0.34, [9, 0, 0]), k(0.48, [-7, 0, 0]), k(0.72, [-4, 6, 4]), k(0.94, [4, 2, 1]), k(1.14, [6, 0, 0]), k(1.32, [-4, 0, 0]), k(1.46, [-3, -4, -3]), k(1.68, [5, 0, 0]), k(1.9, [-2, 0, 0]), k(2.2, [0, 0, 0]), k(2.6, [0, 0, 0])],
        'Head.rot': [k(0, [0, 0, 0]), k(0.12, [-8, 0, 0]), k(0.3, [6, 0, 0]), k(0.39, [-3, 0, 0]), k(0.5, [5, 0, 0]), k(0.76, [-11, -4, -8]), k(0.98, [-4, 0, -3]), k(1.18, [7, 0, 2]), k(1.36, [-8, 0, 4]), k(1.5, [-7, 3, 7]), k(1.72, [6, 0, 2]), k(1.92, [-5, 0, -5]), k(2.2, [-1, 0, 2]), k(2.45, [0, 0, 0]), k(2.6, [0, 0, 0])],
        'ShoulderR.rot': [k(0, RS), k(0.1, [0, 0, -28]), k(0.34, [32, 0, -30]), k(0.5, [20, 0, -80]), k(0.6, [24, 0, -126]), k(0.74, [24, 0, -114]), k(0.92, [24, 0, -128]), k(1.06, [24, 0, -120]), k(1.2, [14, 0, -52]), k(1.32, [8, 0, -16]), k(1.46, [24, 0, -110]), k(1.6, [24, 0, -116]), k(1.74, [18, 0, -80]), k(1.92, [24, 0, -106]), k(2.18, [8, 0, -38]), k(2.42, [0, 0, -13]), k(2.6, RS)],
        'ElbowR.rot': [k(0, RE), k(0.34, [-26, 0, 0]), k(0.5, [-14, 0, -30]), k(0.62, [-6, 0, -10]), k(0.74, [-8, 0, -22]), k(0.92, [-6, 0, -12]), k(1.2, [-22, 0, -6]), k(1.32, [-28, 0, 0]), k(1.46, [-8, 0, -24]), k(1.74, [-18, 0, -30]), k(1.92, [-8, 0, -20]), k(2.18, [-16, 0, 0]), k(2.6, RE)],
        // lengan kiri: menyusul ±0,04 dtk dan sedikit lebih rendah di puncak (tidak simetris = tidak kaku)
        'ShoulderL.rot': [k(0, [0, 0, 18]), k(0.1, [0, 0, 28]), k(0.36, [32, 0, 30]), k(0.54, [20, 0, 78]), k(0.64, [22, 0, 118]), k(0.78, [20, 0, 102]), k(0.95, [22, 0, 122]), k(1.08, [22, 0, 114]), k(1.23, [14, 0, 50]), k(1.35, [8, 0, 16]), k(1.5, [22, 0, 118]), k(1.63, [22, 0, 112]), k(1.77, [18, 0, 78]), k(1.95, [22, 0, 100]), k(2.21, [8, 0, 38]), k(2.45, [0, 0, 13]), k(2.6, [0, 0, 18])],
        'ElbowL.rot': late(mir([k(0, RE), k(0.34, [-26, 0, 0]), k(0.5, [-14, 0, -30]), k(0.62, [-6, 0, -10]), k(0.74, [-8, 0, -22]), k(0.92, [-6, 0, -12]), k(1.2, [-22, 0, -6]), k(1.32, [-28, 0, 0]), k(1.46, [-8, 0, -24]), k(1.74, [-18, 0, -30]), k(1.92, [-8, 0, -20]), k(2.18, [-16, 0, 0]), k(2.6, RE)]), 0.04),
        'HandR.rot': [k(0, [0, 0, 0]), k(0.5, [0, 0, 18]), k(0.64, [0, 0, -14]), k(0.8, [0, 0, 4]), k(1.2, [0, 0, -16]), k(1.36, [0, 0, 10]), k(1.5, [0, 0, -10]), k(1.76, [0, 0, 12]), k(1.96, [0, 0, -6]), k(2.3, [0, 0, 0]), k(2.6, [0, 0, 0])],
        'HandL.rot': [k(0, [0, 0, 0]), k(0.54, [0, 0, -18]), k(0.68, [0, 0, 14]), k(0.84, [0, 0, -4]), k(1.24, [0, 0, 16]), k(1.4, [0, 0, -10]), k(1.54, [0, 0, 10]), k(1.8, [0, 0, -12]), k(2.0, [0, 0, 6]), k(2.34, [0, 0, 0]), k(2.6, [0, 0, 0])],
        // kaki: tertinggal saat naik, lalu satu menendang ke depan-samping dan satu ke belakang
        'LegR.rot': [k(0, [0, 0, 0]), k(0.4, [0, 0, 0]), k(0.52, [8, 0, -2]), k(0.72, [-14, 0, -20]), k(0.9, [-5, 0, -7]), k(1.04, [0, 0, 0]), k(1.32, [0, 0, 0]), k(1.46, [-4, 0, -9]), k(1.6, [0, 0, 0]), k(2.6, [0, 0, 0])],
        'LegL.rot': [k(0, [0, 0, 0]), k(0.4, [0, 0, 0]), k(0.52, [8, 0, 2]), k(0.72, [16, 0, 13]), k(0.9, [4, 0, 5]), k(1.04, [0, 0, 0]), k(1.32, [0, 0, 0]), k(1.46, [5, 0, 8]), k(1.6, [0, 0, 0]), k(2.6, [0, 0, 0])],
        'Eyes.rot': [k(0, [0, 0, 0]), k(0.12, [-4, 0, 0]), k(0.3, [-7, 0, 0]), k(0.72, [-7, 0, 0]), k(1.13, [4, 0, 0]), k(1.4, [0, 0, 0]), k(2.6, [0, 0, 0])],
        'EyeL.scl': [k(0, S(1)), k(0.1, [1.12, 1.16, 1]), k(0.24, [1.1, 1.12, 1]), k(0.34, [1.06, 0.55, 1]), k(0.48, [1.1, 1.12, 1]), k(0.72, [1.14, 1.18, 1]), k(0.98, [1.12, 1.14, 1]), k(1.13, [1.08, 0.5, 1]), k(1.3, [1.1, 1.12, 1]), k(1.68, [1.06, 0.75, 1]), k(1.84, [1.08, 1.1, 1]), k(2.2, [1.04, 1.05, 1]), k(2.36, [1, 0.1, 1]), k(2.48, S(1)), k(2.6, S(1))],
        'EyeR.scl': [k(0, S(1)), k(0.1, [1.12, 1.16, 1]), k(0.24, [1.1, 1.12, 1]), k(0.34, [1.06, 0.55, 1]), k(0.48, [1.1, 1.12, 1]), k(0.72, [1.14, 1.18, 1]), k(0.98, [1.12, 1.14, 1]), k(1.13, [1.08, 0.5, 1]), k(1.3, [1.1, 1.12, 1]), k(1.68, [1.06, 0.75, 1]), k(1.84, [1.08, 1.1, 1]), k(2.2, [1.04, 1.05, 1]), k(2.36, [1, 0.1, 1]), k(2.48, S(1)), k(2.6, S(1))],
        'Glow.scl': [k(0, S(TINY)), k(0.06, S(0.8)), k(0.34, S(0.6)), k(0.6, S(1.5)), k(0.9, S(1)), k(2.0, S(1)), k(2.35, S(TINY)), k(2.6, S(TINY))],
        'Sparks.scl': [k(0, S(TINY)), k(0.5, S(TINY)), k(0.64, S(1.35)), k(0.9, S(1)), k(1.46, S(1.25)), k(1.8, S(1)), k(2.2, S(TINY)), k(2.6, S(TINY))],
        'Sparks.rot': [k(0, [0, 0, 0]), k(0.5, [0, 0, 0]), k(2.2, [0, 0, 90]), k(2.6, [0, 0, 90])],
        // antena paling belakangan: melecut berlawanan arah gerak badan lalu berayun reda
        'AntennaBase.rot': [k(0, [0, 0, 0]), k(0.12, [-6, 0, -12]), k(0.36, [10, 0, 12]), k(0.52, [14, 0, -22]), k(0.68, [4, 0, -6]), k(0.8, [-8, 0, 12]), k(0.98, [-12, 0, 16]), k(1.16, [16, 0, -22]), k(1.32, [-6, 0, 14]), k(1.48, [6, 0, -8]), k(1.64, [-8, 0, 10]), k(1.76, [10, 0, -14]), k(1.92, [-4, 0, 8]), k(2.08, [2, 0, -5]), k(2.28, [0, 0, 2]), k(2.6, [0, 0, 0])],
      },
    },

    // ---------- TALK: menjelaskan jawaban dengan gestur tangan dan anggukan ----------
    Talk: {
      dur: 2.4, loop: true,
      keys: {
        'Root.scl': [k(0, S(1)), k(0.3, [1.01, 0.988, 1.01]), k(0.6, S(1)), k(0.9, [1.01, 0.988, 1.01]), k(1.2, S(1)), k(1.5, [1.01, 0.988, 1.01]), k(1.8, S(1)), k(2.1, [1.01, 0.988, 1.01]), k(2.4, S(1))],
        'Root.rot': [k(0, [0, 0, 1.2]), k(1.2, [0, 0, -1.2]), k(2.4, [0, 0, 1.2])],
        'Torso.rot': [k(0, [0, -5, 1]), k(1.2, [2, 6, -2]), k(2.4, [0, -5, 1])],
        'Head.rot': [k(0, [0, -2, 0]), k(0.3, [7, -4, 3]), k(0.6, [-1, -2, 0]), k(0.9, [6, 1, -4]), k(1.2, [0, 4, -2]), k(1.5, [7, 6, -5]), k(1.8, [-1, 3, 0]), k(2.1, [6, 0, 3]), k(2.4, [0, -2, 0])],
        'ShoulderL.rot': [k(0, [-30, 0, 30]), k(0.6, [-44, 0, 42]), k(1.2, [-32, 0, 28]), k(1.8, [-46, 0, 40]), k(2.4, [-30, 0, 30])],
        'ElbowL.rot': [k(0, [-60, 0, 0]), k(0.6, [-44, 0, 8]), k(1.2, [-64, 0, 0]), k(1.8, [-46, 0, 8]), k(2.4, [-60, 0, 0])],
        'HandL.rot': [k(0, [0, 30, 0]), k(0.6, [0, 50, 10]), k(1.2, [0, 30, 0]), k(1.8, [0, 50, 10]), k(2.4, [0, 30, 0])],
        'ShoulderR.rot': [k(0, [-6, 0, -20]), k(0.9, [-30, 0, -30]), k(1.5, [-18, 0, -24]), k(2.4, [-6, 0, -20])],
        'ElbowR.rot': [k(0, [-20, 0, 0]), k(0.9, [-56, 0, 0]), k(1.5, [-40, 0, 0]), k(2.4, [-20, 0, 0])],
        'AntennaBase.rot': [k(0, [0, 0, 0]), k(0.4, [0, 0, -6]), k(0.8, [0, 0, 6]), k(1.2, [0, 0, -5]), k(1.6, [0, 0, 5]), k(2.0, [0, 0, -4]), k(2.4, [0, 0, 0])],
        'EyeL.scl': blinks(2.4, 1.75),
        'EyeR.scl': blinks(2.4, 1.75),
      },
    },

    // ---------- POKE: kaget saat badan disentuh — terlonjak kecil ----------
    Poke: {
      dur: 1.1, loop: false,
      keys: {
        'Root.pos': hop([0.1, 0.4, 0.12]),
        'Root.scl': [k(0, S(1)), k(0.08, [1.06, 0.92, 1.06]), k(0.24, [0.96, 1.06, 0.96]), k(0.44, [1.05, 0.94, 1.05]), k(0.62, [0.99, 1.02, 0.99]), k(0.8, S(1)), k(1.1, S(1))],
        'Head.rot': [k(0, [0, 0, 0]), k(0.1, [6, 0, 0]), k(0.28, [-8, -8, -6]), k(0.5, [2, 8, 5]), k(0.72, [0, -3, -2]), k(0.95, [0, 0, 0]), k(1.1, [0, 0, 0])],
        'EyeL.scl': [k(0, S(1)), k(0.08, [1.14, 1.18, 1]), k(0.4, [1.12, 1.16, 1]), k(0.52, [1, 0.1, 1]), k(0.64, S(1)), k(1.1, S(1))],
        'EyeR.scl': [k(0, S(1)), k(0.08, [1.14, 1.18, 1]), k(0.4, [1.12, 1.16, 1]), k(0.52, [1, 0.1, 1]), k(0.64, S(1)), k(1.1, S(1))],
        'ShoulderR.rot': [k(0, RS), k(0.14, [0, 0, -62]), k(0.44, [0, 0, -30]), k(0.7, [0, 0, -14]), k(1.1, RS)],
        'LegR.rot': [k(0, [0, 0, 0]), k(0.1, [0, 0, 0]), k(0.25, [-8, 0, -8]), k(0.4, [0, 0, 0]), k(1.1, [0, 0, 0])],
        'AntennaBase.rot': [k(0, [0, 0, 0]), k(0.12, [0, 0, 20]), k(0.3, [0, 0, -20]), k(0.5, [0, 0, 12]), k(0.7, [0, 0, -6]), k(0.9, [0, 0, 2]), k(1.1, [0, 0, 0])],
      },
    },

    // ---------- GIGGLE: geli — badan bergetar, mata menyipit, tangan ke dada ----------
    Giggle: {
      dur: 1.6, loop: false,
      keys: {
        'Root.rot': [k(0, [0, 0, 0]), k(0.15, [0, 0, 3]), k(0.3, [0, 0, -3]), k(0.45, [0, 0, 3]), k(0.6, [0, 0, -3]), k(0.75, [0, 0, 2.5]), k(0.9, [0, 0, -2]), k(1.05, [0, 0, 1]), k(1.25, [0, 0, 0]), k(1.6, [0, 0, 0])],
        'Root.scl': [k(0, S(1)), k(0.1, [1.06, 0.93, 1.06]), k(0.25, [0.99, 1.02, 0.99]), k(0.4, [1.04, 0.95, 1.04]), k(0.55, [0.99, 1.02, 0.99]), k(0.7, [1.04, 0.95, 1.04]), k(0.85, [0.99, 1.02, 0.99]), k(1.0, [1.03, 0.97, 1.03]), k(1.25, S(1)), k(1.6, S(1))],
        'Head.rot': [k(0, [0, 0, 0]), k(0.15, [8, 0, -8]), k(0.45, [10, 0, 9]), k(0.75, [9, 0, -7]), k(1.05, [6, 0, 5]), k(1.35, [0, 0, 0]), k(1.6, [0, 0, 0])],
        'Torso.rot': [k(0, [0, 0, 0]), k(0.15, [6, 0, 0]), k(1.05, [6, 0, 0]), k(1.35, [0, 0, 0]), k(1.6, [0, 0, 0])],
        'ShoulderR.rot': [k(0, RS), k(0.2, [-38, 0, -10]), k(1.05, [-38, 0, -10]), k(1.4, RS), k(1.6, RS)],
        'ElbowR.rot': [k(0, RE), k(0.2, [-88, 0, 0]), k(0.45, [-80, 0, 0]), k(0.7, [-90, 0, 0]), k(1.05, [-84, 0, 0]), k(1.4, RE), k(1.6, RE)],
        'AntennaBase.rot': [k(0, [0, 0, 0]), k(0.15, [0, 0, -12]), k(0.3, [0, 0, 12]), k(0.45, [0, 0, -12]), k(0.6, [0, 0, 12]), k(0.75, [0, 0, -10]), k(0.9, [0, 0, 8]), k(1.05, [0, 0, -5]), k(1.25, [0, 0, 0]), k(1.6, [0, 0, 0])],
        'EyeL.scl': [k(0, S(1)), k(0.12, [1.1, 0.16, 1]), k(1.0, [1.1, 0.16, 1]), k(1.2, S(1)), k(1.6, S(1))],
        'EyeR.scl': [k(0, S(1)), k(0.12, [1.1, 0.16, 1]), k(1.0, [1.1, 0.16, 1]), k(1.2, S(1)), k(1.6, S(1))],
      },
    },

    // ---------- PAT: kepala dielus — merunduk senang, mata terpejam, antena bergoyang ----------
    Pat: {
      dur: 1.7, loop: false,
      keys: {
        'Root.scl': [k(0, S(1)), k(0.14, [1.06, 0.92, 1.06]), k(0.5, [1.04, 0.95, 1.04]), k(1.1, [1.04, 0.95, 1.04]), k(1.3, [0.97, 1.04, 0.97]), k(1.5, S(1)), k(1.7, S(1))],
        'Torso.rot': [k(0, [0, 0, 0]), k(0.14, [5, 0, 0]), k(1.1, [4, 0, 0]), k(1.35, [-2, 0, 0]), k(1.55, [0, 0, 0]), k(1.7, [0, 0, 0])],
        'Head.rot': [k(0, [0, 0, 0]), k(0.14, [10, 0, 0]), k(0.35, [8, 0, 8]), k(0.6, [8, 0, -8]), k(0.85, [8, 0, 8]), k(1.1, [8, 0, -6]), k(1.35, [-3, 0, 0]), k(1.55, [0, 0, 0]), k(1.7, [0, 0, 0])],
        'ShoulderR.rot': [k(0, RS), k(0.2, [10, 0, -32]), k(1.1, [10, 0, -30]), k(1.4, RS), k(1.7, RS)],
        'AntennaBase.rot': [k(0, [0, 0, 0]), k(0.14, [0, 0, 16]), k(0.3, [0, 0, -14]), k(0.46, [0, 0, 14]), k(0.62, [0, 0, -14]), k(0.78, [0, 0, 14]), k(0.94, [0, 0, -12]), k(1.1, [0, 0, 10]), k(1.3, [0, 0, -6]), k(1.5, [0, 0, 0]), k(1.7, [0, 0, 0])],
        'EyeL.scl': [k(0, S(1)), k(0.1, [1.1, 0.14, 1]), k(1.15, [1.1, 0.14, 1]), k(1.32, [1.04, 1.06, 1]), k(1.55, S(1)), k(1.7, S(1))],
        'EyeR.scl': [k(0, S(1)), k(0.1, [1.1, 0.14, 1]), k(1.15, [1.1, 0.14, 1]), k(1.32, [1.04, 1.06, 1]), k(1.55, S(1)), k(1.7, S(1))],
      },
    },
  };
  // lengan/kaki kiri = cermin dari kanan bila tidak ditulis sendiri
  for (const def of Object.values(defs)) {
    if (Array.isArray(def.keys['Root.scl']) && !def.keys['Head.scl']) def.keys['Head.scl'] = headComp(def.keys['Root.scl']);
    for (const part of ['Shoulder', 'Elbow', 'Leg']) {
      const r = def.keys[part + 'R.rot'], l = part + 'L.rot';
      if (r && !def.keys[l]) def.keys[l] = part === 'Leg' ? mir(r) : late(mir(r), 0.03);
    }
  }
  return defs;
}

// ---- interpolasi: Hermite kubik dengan tangen "auto-clamped" (seperti Blender) ----
// gerakan mengalir melewati keyframe, berhenti halus di titik balik, tanpa overshoot liar
function channelTangents(keys, loop, dur) {
  const n = keys.length, dim = keys[0][1].length;
  const T = [];
  for (let i = 0; i < n; i++) {
    const m = new Array(dim).fill(0);
    let prev = i > 0 ? keys[i - 1] : null, next = i < n - 1 ? keys[i + 1] : null;
    if (loop && n > 2) {
      if (!prev) prev = [keys[n - 2][0] - dur, keys[n - 2][1]];
      if (!next) next = [keys[1][0] + dur, keys[1][1]];
    }
    if (prev && next) {
      for (let j = 0; j < dim; j++) {
        const d0 = (keys[i][1][j] - prev[1][j]) / (keys[i][0] - prev[0]);
        const d1 = (next[1][j] - keys[i][1][j]) / (next[0] - keys[i][0]);
        if (d0 * d1 <= 0) continue; // titik balik / tahan → berhenti halus
        const s = (next[1][j] - prev[1][j]) / (next[0] - prev[0]);
        const lim = 3 * Math.min(Math.abs(d0), Math.abs(d1));
        m[j] = Math.sign(s) * Math.min(Math.abs(s), lim);
      }
    }
    T.push(m);
  }
  return T;
}
function sampleHermite(keys, T, t) {
  const n = keys.length;
  if (n === 1 || t <= keys[0][0]) return keys[0][1];
  if (t >= keys[n - 1][0]) return keys[n - 1][1];
  let i = 0;
  while (i < n - 2 && t > keys[i + 1][0]) i++;
  const [t0, p0] = keys[i], [t1, p1] = keys[i + 1];
  const h = t1 - t0, u = (t - t0) / h, u2 = u * u, u3 = u2 * u;
  const h00 = 2 * u3 - 3 * u2 + 1, h10 = u3 - 2 * u2 + u, h01 = -2 * u3 + 3 * u2, h11 = u3 - u2;
  return p0.map((a, j) => h00 * a + h10 * h * T[i][j] + h01 * p1[j] + h11 * h * T[i + 1][j]);
}

export function buildClips(defs = makeClipDefs(), fps = 30) {
  const channels = new Set();
  for (const def of Object.values(defs)) Object.keys(def.keys).forEach((c) => channels.add(c));
  for (const [node, r] of Object.entries(REST)) for (const p of Object.keys(r)) channels.add(`${node}.${p}`);
  const e = new THREE.Euler(), q = new THREE.Quaternion();
  const clips = [];
  for (const [name, def] of Object.entries(defs)) {
    const n = Math.round(def.dur * fps);
    const times = Array.from({ length: n + 1 }, (_, i) => Math.min(def.dur, i / fps));
    const tracks = [];
    for (const ch of channels) {
      const [node, prop] = ch.split('.');
      const keys = def.keys[ch] || [k(0, REST[node][prop])];
      const isFn = typeof keys === 'function';           // channel analitik (lompat, putaran)
      const isConst = !isFn && keys.length === 1;
      const T = isConst || isFn ? null : channelTangents(keys, def.loop, def.dur);
      const tt = isConst ? [0, def.dur] : times;
      const vals = [];
      let qPrev = null;
      for (const t of tt) {
        const v = isFn ? keys(t) : isConst ? keys[0][1] : sampleHermite(keys, T, t);
        if (prop === 'rot') {
          e.set(v[0] * D2R, v[1] * D2R, v[2] * D2R, 'XYZ');
          q.setFromEuler(e);
          if (qPrev && qPrev.dot(q) < 0) q.set(-q.x, -q.y, -q.z, -q.w);
          qPrev = q.clone();
          vals.push(q.x, q.y, q.z, q.w);
        } else vals.push(...v);
      }
      if (prop === 'rot') tracks.push(new THREE.QuaternionKeyframeTrack(`${node}.quaternion`, tt, vals));
      else if (prop === 'pos') tracks.push(new THREE.VectorKeyframeTrack(`${node}.position`, tt, vals));
      else tracks.push(new THREE.VectorKeyframeTrack(`${node}.scale`, tt, vals));
    }
    const clip = new THREE.AnimationClip(name, def.dur, tracks);
    clip.userData = { loop: def.loop };
    clips.push(clip);
  }
  return clips;
}

// =====================================================================
//  CONTROLLER — state machine yang digerakkan event aplikasi/AI
// =====================================================================
//   idle      → Idle (loop) + selingan acak (IdleLook, IdleTilt, IdleBounce, IdleStretch)
//   hello     → Wave sekali, lalu kembali ke state dasar
//   listening → Listen (loop)    : user sedang mengetik / bicara
//   thinking  → Think (loop)     : menunggu respons AI
//   answer    → Eureka sekali, lalu Talk
//   talking   → Talk (loop)      : jawaban sedang ditampilkan/dibacakan
//   poke      → Poke sekali      : badan disentuh (kaget)
//   giggle    → Giggle sekali    : badan disentuh (geli)
//   pat       → Pat sekali       : kepala dielus
//   happy     → IdleBounce sekali: senang (mis. user bilang terima kasih)
export const STATE_TO_CLIP = {
  idle: 'Idle', hello: 'Wave', listening: 'Listen', thinking: 'Think',
  answer: 'Eureka', talking: 'Talk', poke: 'Poke', giggle: 'Giggle', pat: 'Pat', happy: 'IdleBounce',
};
// gerakan selingan yang diputar acak saat idle supaya maskot terasa hidup
export const IDLE_FIDGETS = ['IdleLook', 'IdleTilt', 'IdleBounce', 'IdleLook', 'IdleTilt', 'IdleBounce', 'IdleStretch'];

export class MascotController extends THREE.EventDispatcher {
  constructor(mascot, clips) {
    super();
    this.m = mascot;
    this.nodes = mascot.nodes;
    this.mixer = new THREE.AnimationMixer(mascot.root);
    this.actions = {};
    for (const c of clips) {
      const a = this.mixer.clipAction(c);
      if (c.userData.loop) a.setLoop(THREE.LoopRepeat, Infinity);
      else { a.setLoop(THREE.LoopOnce, 1); a.clampWhenFinished = true; }
      this.actions[c.name] = a;
    }
    this.base = 'idle';
    this.state = null;
    this.current = null;
    this.after = null;
    this.look = { x: 0, y: 0, tx: 0, ty: 0, w: 1 };
    this.blink = { t: 0, next: 2.5 + Math.random() * 3 };
    this.glow = 0;
    this.fidget = { t: 0, next: 2.5 + Math.random() * 2, last: null, on: false, enabled: true };
    this.kick = { pos: 0, vel: 0 };
    this.mixer.addEventListener('finished', (ev) => {
      if (ev.action !== this.current) return;
      this.fidget.on = false; this.fidget.t = 0; this.fidget.next = 3 + Math.random() * 3.5;
      const next = this.after || this.base;
      this.after = null;
      this.setState(next);
    });
    this._e = new THREE.Euler();
  }

  _play(clipName, fade = 0.35) {
    const next = this.actions[clipName];
    if (!next) return;
    // Lepas SEMUA klip lain yang masih punya bobot, termasuk klip sekali-jalan yang sudah selesai
    // (clampWhenFinished membuatnya diam di pose akhir dengan bobot penuh, bukan "running").
    // Tanpa ini pose-pose lama menumpuk dan gerakan makin lama makin berbeda.
    for (const a of Object.values(this.actions)) {
      if (a === next) continue;
      if (a.getEffectiveWeight() > 0 || a.isRunning()) a.fadeOut(fade);
      else a.stop();
    }
    next.stop();
    next.reset().setEffectiveTimeScale(1).setEffectiveWeight(1).fadeIn(fade).play();
    this.current = next;
  }

  /** Ganti state maskot. opts.then = state setelah aksi sekali-jalan selesai. */
  setState(state, opts = {}) {
    const clip = STATE_TO_CLIP[state];
    if (!clip) return;
    const loop = this.actions[clip].loop === THREE.LoopRepeat;
    if (loop) {
      this.base = state;
      if (this.state === state && this.current?.isRunning()) return;
    } else {
      this.after = opts.then || (state === 'answer' ? 'talking' : this.base);
    }
    this.state = state;
    this.fidget.on = false; this.fidget.t = 0;
    if (state === 'answer' || state === 'happy') { this.kick.pos = 0; this.kick.vel = 0; this.blink.t = 0; }
    this._play(clip, opts.fade ?? (state === 'poke' || state === 'giggle' || state === 'pat' ? 0.12 : state === 'answer' ? 0.16 : 0.4));
    this.dispatchEvent({ type: 'state', state });
  }

  /** Putar satu gerakan selingan idle (dipanggil otomatis; bisa juga dipanggil manual). */
  playFidget(name) {
    const F = this.fidget;
    if (!name) { const pool = IDLE_FIDGETS.filter((n) => n !== F.last); name = pool[Math.floor(Math.random() * pool.length)]; }
    if (!this.actions[name]) return;
    F.last = name; F.on = true; F.t = 0;
    this.after = 'idle';
    this._play(name, 0.4);
    this.dispatchEvent({ type: 'fidget', name });
  }

  /** Anggukan kecil sesaat (mis. tiap user mengetik satu huruf) — terasa "nyambung" dengan user. */
  pulse(strength = 1) { this.kick.vel += 55 * strength; }

  /** Arahkan tatapan (x,y dalam -1..1 = posisi jari/kursor relatif ke wajah). */
  lookAt(x, y) { this.look.tx = THREE.MathUtils.clamp(x, -1, 1); this.look.ty = THREE.MathUtils.clamp(y, -1, 1); }

  update(dt) {
    this.mixer.update(dt);
    const n = this.nodes, L = this.look;
    // selingan idle otomatis
    const F = this.fidget;
    if (F.enabled && this.state === 'idle' && !F.on) { F.t += dt; if (F.t > F.next) this.playFidget(); }
    // pegas anggukan (pulse)
    const K = this.kick;
    K.vel += (-K.pos * 190 - K.vel * 15) * dt; K.pos += K.vel * dt;
    // Tatapan: node khusus (HeadLook/EyesLook) DISET langsung, tidak dikalikan → tidak pernah menumpuk/berputar
    const neutral = this.state === 'answer' || this.state === 'happy';
    const wantW = neutral ? 0 : (this.state === 'thinking' || this.state === 'hello') ? 0.2 : 1;
    const a = 1 - Math.exp(-dt * 5);
    L.w += (wantW - L.w) * (neutral ? 1 - Math.exp(-dt * 14) : a);
    L.x += (L.tx - L.x) * a;
    L.y += (L.ty - L.y) * a;
    const yaw = L.x * L.w, pitch = L.y * L.w;
    n.HeadLook.quaternion.setFromEuler(this._e.set((pitch * 9 + K.pos) * D2R, yaw * 12 * D2R, 0));
    n.EyesLook.quaternion.setFromEuler(this._e.set(pitch * 7 * D2R, yaw * 9 * D2R, 0));
    // Kedip acak (node EyeLBlink/EyeRBlink, juga diset langsung)
    const B = this.blink;
    if (this.state !== 'answer' && this.state !== 'happy') B.t += dt;
    let s = 1;
    if (B.t > B.next) {
      const p = (B.t - B.next) / 0.15;
      s = p < 1 ? 1 - Math.sin(p * Math.PI) * 0.9 : 1;
      if (p >= 1) { B.t = 0; B.next = 2.5 + Math.random() * 3.5; }
    }
    n.EyeLBlink.scale.set(1, s, 1);
    n.EyeRBlink.scale.set(1, s, 1);
    // Lampu antena: berkedip saat berpikir, menyala saat dapat jawaban
    const t = performance.now() / 1000;
    let target = 0;
    if (this.state === 'thinking') target = 0.35 + 0.35 * Math.sin(t * 6);
    else if (this.state === 'answer') target = 1.6;
    else if (this.state === 'listening') target = 0.12;
    this.glow += (target - this.glow) * Math.min(1, dt * 8);
    this.m.materials.antennaTip.emissiveIntensity = Math.max(0, this.glow);
  }
}
