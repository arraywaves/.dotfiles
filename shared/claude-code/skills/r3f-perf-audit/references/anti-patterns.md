# R3F Performance Anti-Patterns

## Table of Contents
1. [Unmemoized Geometries and Materials](#1-unmemoized-geometries-and-materials)
2. [Missing dispose() — Memory Leaks](#2-missing-dispose--memory-leaks)
3. [useState for Per-Frame State](#3-usestate-for-per-frame-state)
4. [Missing Instancing for Repeated Meshes](#4-missing-instancing-for-repeated-meshes)
5. [Unnecessary useFrame Subscriptions](#5-unnecessary-useframe-subscriptions)
6. [frameloop Always When Not Needed](#6-frameloop-always-when-not-needed)
7. [useThree Overuse](#7-usethree-overuse)
8. [Unbounded Texture Sizes](#8-unbounded-texture-sizes)
9. [Unoptimized Shadows](#9-unoptimized-shadows)
10. [Missing dpr Limits](#10-missing-dpr-limits)

---

## 1. Unmemoized Geometries and Materials

**Problem:** Creating `THREE.BufferGeometry`, `THREE.Material`, or similar objects directly in a component body causes them to be recreated on every render, spiking GPU upload costs and leaking the old ones.

```tsx
// BAD — new geometry every render
function Box() {
  const geo = new THREE.BoxGeometry(1, 1, 1)   // recreated each render
  const mat = new THREE.MeshStandardMaterial({ color: 'red' })
  return <mesh geometry={geo} material={mat} />
}
```

```tsx
// GOOD — memoized, created once
function Box() {
  const geo = useMemo(() => new THREE.BoxGeometry(1, 1, 1), [])
  const mat = useMemo(() => new THREE.MeshStandardMaterial({ color: 'red' }), [])
  return <mesh geometry={geo} material={mat} />
}

// BEST — use R3F JSX declarative form (R3F manages lifecycle)
function Box() {
  return (
    <mesh>
      <boxGeometry args={[1, 1, 1]} />
      <meshStandardMaterial color="red" />
    </mesh>
  )
}
```

---

## 2. Missing dispose() — Memory Leaks

**Problem:** Three.js geometries, materials, and textures are GPU resources. They must be explicitly disposed when no longer needed, or GPU memory grows indefinitely.

```tsx
// BAD — geometry and texture leak when component unmounts
function Model({ url }) {
  const geo = useMemo(() => loadGeometry(url), [url])
  return <mesh geometry={geo} />
}
```

```tsx
// GOOD — cleanup on unmount
function Model({ url }) {
  const geo = useMemo(() => loadGeometry(url), [url])
  useEffect(() => {
    return () => {
      geo.dispose()
    }
  }, [geo])
  return <mesh geometry={geo} />
}

// GOOD — useGLTF from @react-three/drei handles disposal automatically
// For Three.js objects created manually, always pair creation with useEffect cleanup.
```

**Detection signal:** `renderer.info.memory.geometries` or `.textures` increases when components mount/unmount.

---

## 3. useState for Per-Frame State

**Problem:** Updating React state inside `useFrame` triggers a React re-render every frame (60+ per second), defeating the purpose of the render loop.

```tsx
// BAD — setState in useFrame causes 60 re-renders/sec
function Spinner() {
  const [rotation, setRotation] = useState(0)
  useFrame((_, delta) => {
    setRotation(r => r + delta)  // triggers React re-render!
  })
  return <mesh rotation-y={rotation} />
}
```

```tsx
// GOOD — mutate ref directly, no React re-render
function Spinner() {
  const meshRef = useRef()
  useFrame((_, delta) => {
    meshRef.current.rotation.y += delta
  })
  return <mesh ref={meshRef} />
}
```

---

## 4. Missing Instancing for Repeated Meshes

**Problem:** Rendering N identical meshes as N separate `<mesh>` elements = N draw calls. Each draw call has significant CPU overhead.

```tsx
// BAD — 1000 draw calls for identical geometry
function Crowd({ positions }) {
  return positions.map((pos, i) => (
    <mesh key={i} position={pos}>
      <sphereGeometry args={[0.1]} />
      <meshStandardMaterial color="blue" />
    </mesh>
  ))
}
```

```tsx
// GOOD — 1 draw call for all instances
import { useRef } from 'react'
import { InstancedMesh } from 'three'

function Crowd({ positions }) {
  const ref = useRef()
  useEffect(() => {
    const dummy = new THREE.Object3D()
    positions.forEach((pos, i) => {
      dummy.position.set(...pos)
      dummy.updateMatrix()
      ref.current.setMatrixAt(i, dummy.matrix)
    })
    ref.current.instanceMatrix.needsUpdate = true
  }, [positions])

  return (
    <instancedMesh ref={ref} args={[null, null, positions.length]}>
      <sphereGeometry args={[0.1]} />
      <meshStandardMaterial color="blue" />
    </instancedMesh>
  )
}

// Also consider <Instances> from @react-three/drei for ergonomic instancing
```

**Threshold:** Consider instancing when rendering > 20–50 identical meshes.

---

## 5. Unnecessary useFrame Subscriptions

**Problem:** Every component with `useFrame` runs its callback every frame. Subscribing when not needed wastes CPU.

```tsx
// BAD — subscribing unconditionally even when paused
function Animator({ active }) {
  useFrame(() => {
    if (!active) return  // callback still runs, just returns early
    // ...animation
  })
}
```

```tsx
// GOOD — conditionally subscribe using invalidate or frameloop="demand"
// OR conditionally register the subscription
function Animator({ active }) {
  useFrame(active ? (_, delta) => {
    // animate
  } : () => {})
}

// BEST — unmount the component when inactive so no subscription exists
```

**Also:** Avoid heavy computation (raycasting, physics, large array iteration) inside `useFrame` without throttling.

```tsx
// Throttle expensive checks
let tick = 0
useFrame(() => {
  if (tick++ % 6 !== 0) return  // run every 6th frame
  runExpensiveCheck()
})
```

---

## 6. frameloop Always When Not Needed

**Problem:** `<Canvas frameloop="always">` (the default) renders every frame even when nothing changes.

```tsx
// BAD — renders every frame for a static scene
<Canvas>
  <StaticScene />
</Canvas>
```

```tsx
// GOOD — only renders when invalidated
<Canvas frameloop="demand">
  <StaticScene />
</Canvas>

// Trigger a render when something changes:
const { invalidate } = useThree()
invalidate()  // call after user interaction, state changes, etc.
```

**When to use `"always"`:** Continuous animations, physics simulations, video/audio visualization.

---

## 7. useThree Overuse

**Problem:** `useThree()` subscribes the component to the R3F store. Each store update re-renders all subscribed components. Subscribing too broadly causes cascade re-renders.

```tsx
// BAD — subscribes to entire store; re-renders on any store update
function MyComponent() {
  const { camera, scene, gl, size } = useThree()
  // only uses `camera` but now re-renders on size changes too
}
```

```tsx
// GOOD — select only what you need
function MyComponent() {
  const camera = useThree(state => state.camera)
  // only re-renders when camera changes
}
```

**Also:** Avoid calling `useThree()` in many leaf components. Prefer passing values as props or using a single parent to extract and distribute.

---

## 8. Unbounded Texture Sizes

**Problem:** Large textures consume VRAM and slow GPU upload. A 4096×4096 texture uses ~64 MB of VRAM (uncompressed).

```tsx
// Check texture dimensions after loading
useEffect(() => {
  if (texture) {
    console.log(texture.image.width, texture.image.height)
  }
}, [texture])
```

**Guidelines:**
- UI/environment maps: 512×512 or 1024×1024 max
- Detailed surfaces: 2048×2048 max, use only if visible up close
- Always use power-of-two dimensions (256, 512, 1024, 2048)
- Use `texture.minFilter = THREE.LinearMipmapLinearFilter` and generate mipmaps
- Prefer compressed formats (KTX2/Basis) for production via `useKTX2` from `@react-three/drei`

```tsx
// Enable mipmaps for distant textures
texture.generateMipmaps = true
texture.minFilter = THREE.LinearMipmapLinearFilter
```

---

## 9. Unoptimized Shadows

**Problem:** Shadow maps are expensive. Each shadow-casting light renders the scene from its perspective. Default shadow map sizes are often too large.

```tsx
// BAD — default shadow map size is 512×512 per light, but many lights = many passes
<directionalLight castShadow />  // uses default shadow map, re-renders entire scene
```

```tsx
// GOOD — tune shadow map size and camera frustum
<directionalLight
  castShadow
  shadow-mapSize={[1024, 1024]}   // only as large as needed
  shadow-camera-near={0.1}
  shadow-camera-far={50}          // tight frustum = better depth precision
  shadow-camera-left={-10}
  shadow-camera-right={10}
  shadow-camera-top={10}
  shadow-camera-bottom={-10}
/>
```

**Tips:**
- Use `castShadow` only on lights that must cast shadows — minimize shadow-casting lights to 1–2
- Use `castShadow={false}` on small/far meshes that don't need precise shadows
- Consider baked shadows (lightmaps) for static scenes
- Use `<ContactShadows>` from drei for cheap approximate shadows

---

## 10. Missing dpr Limits

**Problem:** On high-DPI displays, the default device pixel ratio can be 2–3×, multiplying pixel fill rate and significantly increasing GPU load.

```tsx
// BAD — renders at full device pixel ratio (may be 3x on modern phones)
<Canvas>
  ...
</Canvas>
```

```tsx
// GOOD — cap DPR to a reasonable maximum
<Canvas dpr={[1, 2]}>
  ...
</Canvas>

// For low-end devices, consider adaptive DPR via @react-three/drei PerformanceMonitor
import { PerformanceMonitor } from '@react-three/drei'

function AdaptiveScene() {
  const [dpr, setDpr] = useState(2)
  return (
    <Canvas dpr={dpr}>
      <PerformanceMonitor onDecline={() => setDpr(1)} onIncline={() => setDpr(2)} />
      {/* scene */}
    </Canvas>
  )
}
```
