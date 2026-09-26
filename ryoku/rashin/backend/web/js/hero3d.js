// The hero canvas: a slow-turning 3D compass needle over the poster header,
// the dashboard's one loud element. It is deliberately cheap: one lathe mesh,
// no shadows, one point light, and the render loop parks itself while the
// motion switch is off, while the tab is hidden, and while the overview panel
// is not on screen. WebGL failing at all (no context, software disabled) is
// silent: the CSS poster art underneath simply stays visible, because the
// canvas is an enhancement layered on an already-finished header.

import * as THREE from "../vendor/three.module.min.js";
import { motion } from "./motion.js";

function needleGeometry() {
  // A flat, tapered shank built as a lathe: the needle of the compass, not a
  // stylised arrow. Two facets (edge and back) read at small sizes.
  const pts = [];
  const profile = [
    [0.0, 0.0],
    [0.09, 0.35],
    [0.075, 1.6],
    [0.03, 2.4],
    [0.0, 2.7],
  ];
  for (const [r, y] of profile) pts.push(new THREE.Vector2(r, y));
  const g = new THREE.LatheGeometry(pts, 3);
  g.rotateX(Math.PI / 2);
  return g;
}

export function initHero(canvas) {
  if (!canvas || typeof THREE !== "object" || !THREE.WebGLRenderer) return;
  let renderer;
  try {
    renderer = new THREE.WebGLRenderer({
      canvas,
      alpha: true,
      antialias: true,
      powerPreference: "low-power",
    });
  } catch (err) {
    canvas.remove();
    return;
  }
  renderer.setClearAlpha(0);

  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(34, 1, 0.1, 40);
  camera.position.set(0, 0.6, 6.4);
  camera.lookAt(0, 0, 0);

  const sun = new THREE.PointLight(0xc94e44, 40, 30);
  sun.position.set(3.4, 1.8, 3.2);
  scene.add(sun);
  scene.add(new THREE.AmbientLight(0xe8d8c9, 0.55));

  const needle = new THREE.Mesh(
    needleGeometry(),
    new THREE.MeshStandardMaterial({
      color: 0xe8d8c9,
      metalness: 0.65,
      roughness: 0.32,
      flatShading: true,
    })
  );
  needle.rotation.x = -0.32;
  const rig = new THREE.Group();
  scene.add(rig);
  rig.add(needle);
  // The poster's figure owns the centre; the needle hovers over the open
  // sun disc at the right of the header instead of colliding with it.
  rig.position.set(2.95, 0.1, 0);
  rig.scale.setScalar(0.72);

  const halo = new THREE.Mesh(
    new THREE.RingGeometry(1.62, 1.68, 96),
    new THREE.MeshBasicMaterial({
      color: 0xc94e44,
      transparent: true,
      opacity: 0.5,
      side: THREE.DoubleSide,
    })
  );
  halo.position.z = -0.6;
  rig.add(halo);

  // The needle answers the pointer: yaw and pitch ease toward it, so the
  // header feels looked-at rather than watched.
  const target = { x: 0, y: -0.32 };
  const hero = canvas.closest("[data-hero]") || canvas.parentElement;
  if (hero) {
    hero.addEventListener("pointermove", (e) => {
      const r = hero.getBoundingClientRect();
      const nx = ((e.clientX - r.left) / r.width) * 2 - 1;
      const ny = ((e.clientY - r.top) / r.height) * 2 - 1;
      target.x = nx * 1.15;
      target.y = -0.32 + ny * 0.5;
    });
    hero.addEventListener("pointerleave", () => {
      target.x = 0;
      target.y = -0.32;
    });
  }

  function resize() {
    const w = canvas.clientWidth || hero?.clientWidth || 640;
    const h = canvas.clientHeight || hero?.clientHeight || 260;
    renderer.setPixelRatio(Math.min(devicePixelRatio || 1, 2));
    renderer.setSize(w, h, false);
    camera.aspect = w / Math.max(1, h);
    camera.updateProjectionMatrix();
  }
  resize();
  addEventListener("resize", resize);

  let raf = 0;
  let spin = 0;

  function frame() {
    raf = 0;
    if (!running()) return;
    const move = motion.on ? 1 : 0;
    spin += 0.0035 * move;
    needle.rotation.y += (target.x + (motion.on ? Math.sin(spin) * 0.25 : 0) - needle.rotation.y) * 0.06;
    needle.rotation.x += (target.y - needle.rotation.x) * 0.06;
    halo.rotation.z += 0.0016 * move;
    renderer.render(scene, camera);
    if (motion.on) raf = requestAnimationFrame(frame);
  }

  function running() {
    const panel = canvas.closest("[data-panel]");
    if (panel && panel.hidden) return false;
    if (document.hidden) return false;
    return true;
  }

  function ensure() {
    if (!running()) return;
    if (!raf) raf = requestAnimationFrame(frame);
  }

  motion.onChange(() => ensure());
  document.addEventListener("visibilitychange", () => ensure());
  addEventListener("hashchange", () => ensure());
  renderer.render(scene, camera);
}
