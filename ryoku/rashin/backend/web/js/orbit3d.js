// ORBIT 3D: the memory graph as a slow-turning constellation. Same nodes and
// links as the force layout, projected into depth by three.js: spheres sized
// by degree, tinted by the existing legend colors, links as faded lines, and
// the whole cloud rotating until you drag it. The graph physics itself still
// runs in memory.js (the tested layoutStep), so both renderers share one
// model and the 2D/3D toggle never disagrees about what the vault looks like.
// Motion off means one static frame, not a dead canvas; WebGL absence means
// the toggle keeps 2D only and the ORBIT chip hides itself.

import * as THREE from "../vendor/three.module.min.js";
import { motion } from "./motion.js";

const COLORS = {
  hub: 0xc94e44,
  generated: 0xcda47b,
  notes: 0x3e6868,
  journal: 0x4b607f,
  memory: 0xf3701e,
  learned: 0xf3701e,
  hermes: 0xf3701e,
  skill: 0xe8d8c9,
  default: 0x8f8378,
};

function colorFor(kind) {
  return COLORS[kind] || COLORS.default;
}

export function supportsWebGL() {
  try {
    const c = document.createElement("canvas");
    return !!(c.getContext("webgl2") || c.getContext("webgl"));
  } catch (err) {
    return false;
  }
}

export function initOrbit(canvas, { nodes, links, onSelect }) {
  if (!canvas || typeof THREE !== "object" || !THREE.WebGLRenderer) return null;
  let renderer;
  try {
    renderer = new THREE.WebGLRenderer({ canvas, alpha: true, antialias: true, powerPreference: "low-power" });
  } catch (err) {
    return null;
  }
  renderer.setClearAlpha(0);

  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(50, 1, 0.1, 4000);
  const rig = new THREE.Group();
  scene.add(rig);

  const ambient = new THREE.AmbientLight(0xe8d8c9, 0.9);
  scene.add(ambient);
  const key = new THREE.DirectionalLight(0xffffff, 1.4);
  key.position.set(120, 160, 220);
  scene.add(key);

  const group = new THREE.Group();
  rig.add(group);

  const SCALE = 0.18;

  const degree = {};
  (links || []).forEach((l) => {
    const a = l.source ?? l.s;
    const b = l.target ?? l.t;
    degree[a] = (degree[a] || 0) + 1;
    degree[b] = (degree[b] || 0) + 1;
  });

  const meshes = [];
  const byId = {};
  const sphere = new THREE.SphereGeometry(1, 12, 10);
  for (const n of nodes || []) {
    const d = degree[n.id] || 0;
    const r = 2 + Math.sqrt(d) * 1.8;
    const m = new THREE.Mesh(
      sphere,
      new THREE.MeshStandardMaterial({
        color: colorFor(n.group || n.kind),
        roughness: 0.55,
        metalness: 0.15,
        emissive: colorFor(n.group || n.kind),
        emissiveIntensity: 0.22,
      })
    );
    m.scale.setScalar(r);
    m.position.set((n.x || 0) * SCALE, (n.y || 0) * SCALE, Math.sin((d + 1) * 1.7) * 6);
    m.userData = { node: n, id: n.id };
    group.add(m);
    meshes.push(m);
    byId[n.id] = m;
  }

  const linePts = [];
  for (const l of links || []) {
    const a = byId[l.source ?? l.s];
    const b = byId[l.target ?? l.t];
    if (!a || !b) continue;
    linePts.push(a.position.clone(), b.position.clone());
  }
  if (linePts.length) {
    const g = new THREE.BufferGeometry().setFromPoints(linePts);
    const lines = new THREE.LineSegments(g, new THREE.LineBasicMaterial({ color: 0x8f8378, transparent: true, opacity: 0.28 }));
    group.add(lines);
  }

  function fit() {
    const box = new THREE.Box3().setFromObject(group);
    const size = box.getSize(new THREE.Vector3());
    const center = box.getCenter(new THREE.Vector3());
    group.position.sub(center);
    const span = Math.max(size.x, size.y, size.z, 40);
    camera.position.set(0, 0, span * 1.9 + 30);
    camera.near = 1;
    camera.far = span * 10 + 1000;
    camera.lookAt(0, 0, 0);
    camera.updateProjectionMatrix();
  }
  fit();

  // drag rotates, wheel dollies, and the cloud self-orbits when untouched.
  let dragging = false;
  let last = null;
  let vel = { x: 0, y: 0 };
  let zoom = 1;
  canvas.style.touchAction = "none";
  canvas.addEventListener("pointerdown", (e) => {
    dragging = true;
    last = { x: e.clientX, y: e.clientY };
    canvas.setPointerCapture(e.pointerId);
  });
  canvas.addEventListener("pointermove", (e) => {
    if (!dragging) return hover(e);
    const dx = e.clientX - last.x;
    const dy = e.clientY - last.y;
    last = { x: e.clientX, y: e.clientY };
    rig.rotation.y += dx * 0.005;
    rig.rotation.x += dy * 0.005;
    vel = { x: dy * 0.0006, y: dx * 0.0006 };
  });
  canvas.addEventListener("pointerup", (e) => {
    dragging = false;
    click(e);
  });
  canvas.addEventListener("pointerleave", () => (dragging = false));
  canvas.addEventListener(
    "wheel",
    (e) => {
      e.preventDefault();
      zoom = Math.min(2.5, Math.max(0.35, zoom * (1 + e.deltaY * 0.001)));
      applyZoom();
    },
    { passive: false }
  );
  function applyZoom() {
    camera.zoom = zoom;
    camera.updateProjectionMatrix();
  }

  const pointer = new THREE.Vector2();
  const ray = new THREE.Raycaster();
  let picked = null;
  function pick(e) {
    const r = canvas.getBoundingClientRect();
    pointer.set(((e.clientX - r.left) / r.width) * 2 - 1, -((e.clientY - r.top) / r.height) * 2 + 1);
    ray.setFromCamera(pointer, camera);
    const hit = ray.intersectObjects(meshes, false)[0];
    return hit ? hit.object : null;
  }
  function hover(e) {
    const m = pick(e);
    if (m !== picked) {
      if (picked) picked.scale.setScalar(picked.userData.base || picked.scale.x);
      picked = m;
      canvas.style.cursor = m ? "pointer" : "grab";
    }
  }
  function click(e) {
    const m = pick(e);
    if (m && onSelect) onSelect(m.userData.node);
  }
  meshes.forEach((m) => (m.userData.base = m.scale.x));

  let raf = 0;
  function frame() {
    raf = 0;
    const panel = canvas.closest("[data-panel]");
    if (panel && panel.hidden) return;
    if (document.hidden) return;
    if (motion.on) {
      if (!dragging) {
        rig.rotation.y += 0.0016 + vel.y;
        rig.rotation.x += vel.x;
        vel.x *= 0.96;
        vel.y *= 0.96;
      }
      renderer.render(scene, camera);
      raf = requestAnimationFrame(frame);
    } else {
      renderer.render(scene, camera);
    }
  }

  motion.onChange(() => {
    if (motion.on && !raf) raf = requestAnimationFrame(frame);
  });
  renderer.render(scene, camera);
  if (motion.on) raf = requestAnimationFrame(frame);

  return {
    resume() {
      if (!raf) raf = requestAnimationFrame(frame);
    },
    step(nodesNow) {
      // the shared force layout advanced positions; copy them in
      for (const n of nodesNow) {
        const m = byId[n.id];
        if (m) m.position.set(n.x * SCALE, n.y * SCALE, m.position.z);
      }
      fit();
    },
  };
}
