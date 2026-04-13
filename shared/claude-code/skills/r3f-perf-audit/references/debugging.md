# R3F Live Debugging Guide

## Table of Contents

1. [@r3f/perf — In-Scene Overlay](#1-r3fperf--in-scene-overlay)
2. [renderer.info — Three.js GPU Stats](#2-rendererinfo--threejs-gpu-stats)
3. [React DevTools Profiler](#3-react-devtools-profiler)
4. [Chrome DevTools Performance](#4-chrome-devtools-performance)
5. [Spector.js — WebGL Frame Capture](#5-spectorjs--webgl-frame-capture)
6. [Diagnostic Checklist](#6-diagnostic-checklist)

---

## 1. @r3f/perf — In-Scene Overlay

The fastest way to get an at-a-glance performance dashboard inside your R3F app.

**Install:**

```bash
vp add @r3f/perf
```

**Usage:**

```tsx
import { Perf } from "r3f-perf";

function Scene() {
  return (
    <>
      <Perf position="top-left" />
      {/* rest of scene */}
    </>
  );
}
```

**What it shows:**

- FPS and frame time (ms)
- Draw calls per frame
- Triangle count
- Memory: geometry and texture counts
- Component render counts (React)

**Key signals:**
| Metric | Healthy | Investigate |
|--------|---------|-------------|
| FPS | 60 | < 50 consistently |
| Draw calls | < 100 | > 200 |
| Triangles | < 500k | > 2M |
| Geometries | Stable | Growing over time |
| Textures | Stable | Growing over time |

**Conditional inclusion (dev only):**

```tsx
{
  process.env.NODE_ENV === "development" && <Perf />;
}
```

---

## 2. renderer.info — Three.js GPU Stats

Access raw Three.js renderer statistics without any additional packages.

```tsx
import { useThree } from "@react-three/fiber";
import { useFrame } from "@react-three/fiber";

function RendererStats() {
  const { gl } = useThree();

  useFrame(() => {
    const info = gl.info;
    console.log({
      drawCalls: info.render.calls,
      triangles: info.render.triangles,
      points: info.render.points,
      lines: info.render.lines,
      geometries: info.memory.geometries,
      textures: info.memory.textures,
      programs: info.programs?.length,
    });
  });

  return null;
}
```

**Or log on demand (not every frame):**

```tsx
// In a button handler or useEffect
const { gl } = useThree();
console.log(gl.info);
```

**Memory leak detection:** Mount and unmount components, then compare `gl.info.memory.geometries` and `.textures`. Numbers should return to baseline.

---

## 3. React DevTools Profiler

Identifies which React components are re-rendering unnecessarily.

**Setup:**

1. Install React DevTools browser extension
2. Open DevTools → Profiler tab
3. Click Record → interact with your scene → Stop

**What to look for:**

- Components that commit on every frame (animation components should NOT cause React commits unless they must)
- Components that re-render when props/state haven't meaningfully changed
- High "self" render time in a component (indicates expensive render function)

**R3F-specific tips:**

- Components using `useThree()` broadly will re-render on any canvas resize
- Components using `useFrame` should NOT appear in Profiler commits (useFrame bypasses React)
- If you see your scene root re-rendering every frame, look for `useState` in `useFrame` callbacks

**Using React.memo to prevent re-renders:**

```tsx
// Wrap expensive components that receive stable props
const ExpensiveMesh = React.memo(({ position }) => {
  return (
    <mesh position={position}>
      <boxGeometry />
      <meshStandardMaterial />
    </mesh>
  );
});
```

---

## 4. Chrome DevTools Performance

For CPU-level profiling: JavaScript execution time, garbage collection, and layout.

**Steps:**

1. Open Chrome DevTools → Performance tab
2. Click Record
3. Interact with your scene for 5–10 seconds
4. Stop and analyze

**What to look for in the flame chart:**

- **Long tasks (red triangles):** JavaScript blocking the main thread > 50ms
- **GC events:** Frequent garbage collection = objects being created/destroyed (likely unmemoized Three.js objects)
- **`useFrame` callback time:** Should be < 5ms per frame for 60 FPS
- **React commit phases:** Should not appear in the animation loop

**GPU profiling (Chrome):**

1. DevTools → More tools → Rendering
2. Enable "Frame Rendering Stats" overlay for GPU memory and FPS

**Identifying shader compile stalls:**

- Shader compilation causes large one-time spikes early in scene load
- Use `gl.compile(scene, camera)` to pre-compile shaders before showing the scene:

```tsx
useEffect(() => {
  const { gl, scene, camera } = state;
  gl.compile(scene, camera);
}, []);
```

---

## 5. Spector.js — WebGL Frame Capture

Captures every WebGL call in a single frame. Useful for understanding exactly what is being drawn and in what order.

**Install (browser extension):** [Spector.js Chrome Extension](https://chrome.google.com/webstore/detail/spectorjs/denbgaamihkadbghdceggmchnflmhpmk)

**Or programmatic use:**

```bash
vp add spectorjs
```

```tsx
import { Spector } from "spectorjs";

// Run once in development
if (process.env.NODE_ENV === "development") {
  const spector = new Spector();
  spector.displayUI();
  spector.spyCanvases();
}
```

**What to look for:**

- Number of draw calls per frame (each `drawArrays` or `drawElements` call)
- Redundant state changes (setting the same uniform or texture repeatedly)
- Unintended draws (objects you thought were culled)
- Shader program switches (expensive on some GPUs)

---

## 6. Diagnostic Checklist

Work through this top-to-bottom when investigating a performance issue:

**Step 1 — Measure baseline**

- [ ] Add `<Perf />` or log `gl.info` and record FPS, draw calls, triangle count
- [ ] Note whether FPS is consistently low or spiky/intermittent

**Step 2 — Isolate the problem type**

- [ ] **CPU-bound:** `useFrame` time high, GC spikes in Performance tab → check unmemoized objects, heavy JS in render loop
- [ ] **GPU-bound:** Draw calls > 100, triangles > 1M → check instancing, LOD, frustum culling
- [ ] **Memory leak:** Geometry/texture counts grow on scene changes → check `dispose()` calls
- [ ] **React re-render storm:** React Profiler shows unexpected commits → check `useState` in useFrame, `useThree()` overuse

**Step 3 — Apply targeted fixes**

- CPU issues → see anti-patterns.md §3 (useState), §5 (useFrame), §7 (useThree)
- GPU issues → see anti-patterns.md §4 (instancing), §8 (textures), §9 (shadows), §10 (dpr)
- Memory leaks → see anti-patterns.md §2 (dispose)
- Re-render issues → see anti-patterns.md §3, §7

**Step 4 — Verify improvement**

- Re-measure with `<Perf />` or `gl.info` after each fix
- Compare before/after in Chrome DevTools Performance
