---
name: threejs-skills
description: "Create 3D scenes, interactive experiences, and visual effects using Three.js. Use when user requests 3D graphics, WebGL experiences, 3D visualizations, animations, or interactive 3D elements."
risk: safe
source: "https://github.com/CloudAI-X/threejs-skills"
date_added: "2026-02-27"
---

# Three.js Skills

Systematically create high-quality 3D scenes and interactive experiences using Three.js best practices.

## When to Use
- Requests 3D visualizations or graphics ("create a 3D model", "show in 3D")
- Wants interactive 3D experiences ("rotating cube", "explorable scene")
- Needs WebGL or canvas-based rendering
- Asks for animations, particles, or visual effects
- Mentions Three.js, WebGL, or 3D rendering
- Wants to visualize data in 3D space

## Core Setup Pattern

### 1. Essential Three.js Imports

Use ES module import maps for modern Three.js (r183+):

```html
<script type="importmap">
{
  "imports": {
    "three": "https://cdn.jsdelivr.net/npm/three@0.183.0/build/three.module.js",
    "three/addons/": "https://cdn.jsdelivr.net/npm/three@0.183.0/examples/jsm/"
  }
}
</script>
<script type="module">
import * as THREE from "three";
import { OrbitControls } from "three/addons/controls/OrbitControls.js";
</script>
```

For production with npm/vite/webpack:

```javascript
import * as THREE from "three";
import { OrbitControls } from "three/addons/controls/OrbitControls.js";
```

### 2. Scene Initialization

Every Three.js artifact needs these core components:

```javascript
// Scene - contains all 3D objects
const scene = new THREE.Scene();

// Camera - defines viewing perspective
const camera = new THREE.PerspectiveCamera(
  75, // Field of view
  window.innerWidth / window.innerHeight, // Aspect ratio
  0.1, // Near clipping plane
  1000, // Far clipping plane
);
camera.position.z = 5;

// Renderer - draws the scene
const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setSize(window.innerWidth, window.innerHeight);
document.body.appendChild(renderer.domElement);
```

### 3. Animation Loop

Use `renderer.setAnimationLoop()` (preferred) or `requestAnimationFrame`:

```javascript
// Preferred: setAnimationLoop (handles WebXR compatibility)
renderer.setAnimationLoop(() => {
  mesh.rotation.x += 0.01;
  mesh.rotation.y += 0.01;
  renderer.render(scene, camera);
});

// Alternative: manual requestAnimationFrame
function animate() {
  requestAnimationFrame(animate);
  mesh.rotation.x += 0.01;
  mesh.rotation.y += 0.01;
  renderer.render(scene, camera);
}
animate();
```

## Systematic Development Process

### 1. Define the Scene

Start by identifying:

- **What objects** need to be rendered
- **Camera position** and field of view
- **Lighting setup** required
- **Interaction model** (static, rotating, user-controlled)

### 2. Build Geometry

Choose appropriate geometry types:

**Basic Shapes:**

- `BoxGeometry` - cubes, rectangular prisms
- `SphereGeometry` - spheres, planets
- `CylinderGeometry` - cylinders, tubes
- `PlaneGeometry` - flat surfaces, ground planes
- `TorusGeometry` - donuts, rings

**CapsuleGeometry** is available (stable since r142):

```javascript
new THREE.CapsuleGeometry(0.5, 1, 4, 8); // radius, length, capSegments, radialSegments
```

### 3. Apply Materials

Choose materials based on visual needs:

**Common Materials:**

- `MeshBasicMaterial` - unlit, flat colors (no lighting needed)
- `MeshStandardMaterial` - physically-based, realistic (needs lighting)
- `MeshPhongMaterial` - shiny surfaces with specular highlights
- `MeshLambertMaterial` - matte surfaces, diffuse reflection

```javascript
const material = new THREE.MeshStandardMaterial({
  color: 0x00ff00,
  metalness: 0.5,
  roughness: 0.5,
});
```

### 4. Add Lighting

**If using lit materials** (Standard, Phong, Lambert), add lights:

```javascript
// Ambient light - general illumination
const ambientLight = new THREE.AmbientLight(0xffffff, 0.5);
scene.add(ambientLight);

// Directional light - like sunlight
const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
directionalLight.position.set(5, 5, 5);
scene.add(directionalLight);
```

**Skip lighting** if using `MeshBasicMaterial` - it's unlit by design.

### 5. Handle Responsiveness

Always add window resize handling:

```javascript
window.addEventListener("resize", () => {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
});
```

## Common Patterns

### Rotating Object

```javascript
function animate() {
  requestAnimationFrame(animate);
  mesh.rotation.x += 0.01;
  mesh.rotation.y += 0.01;
  renderer.render(scene, camera);
}
```

### OrbitControls

With import maps or build tools, OrbitControls works directly:

```javascript
import { OrbitControls } from "three/addons/controls/OrbitControls.js";

const controls = new OrbitControls(camera, renderer.domElement);
controls.enableDamping = true;

// Update in animation loop
renderer.setAnimationLoop(() => {
  controls.update();
  renderer.render(scene, camera);
});
```

### Custom Camera Controls (Alternative)

For lightweight custom controls without importing OrbitControls:

```javascript
let isDragging = false;
let previousMousePosition = { x: 0, y: 0 };

renderer.domElement.addEventListener("mousedown", () => {
  isDragging = true;
});

renderer.domElement.addEventListener("mouseup", () => {
  isDragging = false;
});

renderer.domElement.addEventListener("mousemove", (event) => {
  if (isDragging) {
    const deltaX = event.clientX - previousMousePosition.x;
    const deltaY = event.clientY - previousMousePosition.y;

    // Rotate camera around scene
    const rotationSpeed = 0.005;
    camera.position.x += deltaX * rotationSpeed;
    camera.position.y -= deltaY * rotationSpeed;
    camera.lookAt(scene.position);
  }

  previousMousePosition = { x: event.clientX, y: event.clientY };
});

// Zoom with mouse wheel
renderer.domElement.addEventListener("wheel", (event) => {
  event.preventDefault();
  camera.position.z += event.deltaY * 0.01;
  camera.position.z = Math.max(2, Math.min(20, camera.position.z)); // Clamp
});
```

### Raycasting for Object Selection

Detect mouse clicks and hovers on 3D objects:

```javascript
const raycaster = new THREE.Raycaster();
const mouse = new THREE.Vector2();
const clickableObjects = []; // Array of meshes that can be clicked

// Update mouse position
window.addEventListener("mousemove", (event) => {
  mouse.x = (event.clientX / window.innerWidth) * 2 - 1;
  mouse.y = -(event.clientY / window.innerHeight) * 2 + 1;
});

// Detect clicks
window.addEventListener("click", () => {
  raycaster.setFromCamera(mouse, camera);
  const intersects = raycaster.intersectObjects(clickableObjects);

  if (intersects.length > 0) {
    const clickedObject = intersects[0].object;
    // Handle click - change color, scale, etc.
    clickedObject.material.color.set(0xff0000);
  }
});

// Hover effect in animation loop
function animate() {
  requestAnimationFrame(animate);

  raycaster.setFromCamera(mouse, camera);
  const intersects = raycaster.intersectObjects(clickableObjects);

  // Reset all objects
  clickableObjects.forEach((obj) => {
    obj.scale.set(1, 1, 1);
  });

  // Highlight hovered object
  if (intersects.length > 0) {
    intersects[0].object.scale.set(1.2, 1.2, 1.2);
    document.body.style.cursor = "pointer";
  } else {
    document.body.style.cursor = "default";
  }

  renderer.render(scene, camera);
}
```

### Particle System

```javascript
const particlesGeometry = new THREE.BufferGeometry();
const particlesCount = 1000;
const posArray = new Float32Array(particlesCount * 3);

for (let i = 0; i < particlesCount * 3; i++) {
  posArray[i] = (Math.random() - 0.5) * 10;
}

particlesGeometry.setAttribute(
  "position",
  new THREE.BufferAttribute(posArray, 3),
);

const particlesMaterial = new THREE.PointsMaterial({
  size: 0.02,
  color: 0xffffff,
});

const particlesMesh = new THREE.Points(particlesGeometry, particlesMaterial);
scene.add(particlesMesh);
```

### User Interaction (Mouse Movement)

```javascript
let mouseX = 0;
let mouseY = 0;

document.addEventListener("mousemove", (event) => {
  mouseX = (event.clientX / window.innerWidth) * 2 - 1;
  mouseY = -(event.clientY / window.innerHeight) * 2 + 1;
});

function animate() {
  requestAnimationFrame(animate);
  camera.position.x = mouseX * 2;
  camera.position.y = mouseY * 2;
  camera.lookAt(scene.position);
  renderer.render(scene, camera);
}
```

### Loading Textures

```javascript
const textureLoader = new THREE.TextureLoader();
const texture = textureLoader.load("texture-url.jpg");

const material = new THREE.MeshStandardMaterial({
  map: texture,
});
```

## Best Practices

### Performance

- **Reuse geometries and materials** when creating multiple similar objects
- **Use `BufferGeometry`** for custom shapes (more efficient)
- **Limit particle counts** to maintain 60fps (start with 1000-5000)
- **Dispose of resources** when removing objects:
  ```javascript
  geometry.dispose();
  material.dispose();
  texture.dispose();
  ```

### Visual Quality

- Always set `antialias: true` on renderer for smooth edges
- Use appropriate camera FOV (45-75 degrees typical)
- Position lights thoughtfully - avoid overlapping multiple bright lights
- Add ambient + directional lighting for realistic scenes

### Code Organization

- Initialize scene, camera, renderer at the top
- Group related objects (e.g., all particles in one group)
- Keep animation logic in the animate function
- Separate object creation into functions for complex scenes

### Common Pitfalls to Avoid

- ❌ Using `outputEncoding` instead of `outputColorSpace` (renamed in r152)
- ❌ Forgetting to add objects to scene with `scene.add()`
- ❌ Using lit materials without adding lights
- ❌ Not handling window resize
- ❌ Forgetting to call `renderer.render()` in animation loop
- ❌ Using `THREE.Clock` without considering `THREE.Timer` (recommended in r183)

## Example Workflow

User: "Create an interactive 3D sphere that responds to mouse movement"

1. **Setup**: Import Three.js, create scene/camera/renderer
2. **Geometry**: Create `SphereGeometry(1, 32, 32)` for smooth sphere
3. **Material**: Use `MeshStandardMaterial` for realistic look
4. **Lighting**: Add ambient + directional lights
5. **Interaction**: Track mouse position, update camera
6. **Animation**: Rotate sphere, render continuously
7. **Responsive**: Add window resize handler
8. **Result**: Smooth, interactive 3D sphere ✓

## Troubleshooting

**Black screen / Nothing renders:**

- Check if objects added to scene
- Verify camera position isn't inside objects
- Ensure renderer.render() is called
- Add lights if using lit materials

**Poor performance:**

- Reduce particle count
- Lower geometry detail (segments)
- Reuse materials/geometries
- Check browser console for errors

**Objects not visible:**

- Check object position vs camera position
- Verify material has visible color/properties
- Ensure camera far plane includes objects
- Add lighting if needed

## Advanced Techniques

### Visual Polish for Portfolio-Grade Rendering

**Shadows:**

```javascript
// Enable shadows on renderer
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap; // Soft shadows

// Light that casts shadows
const directionalLight = new THREE.DirectionalLight(0xffffff, 1);
directionalLight.position.set(5, 10, 5);
directionalLight.castShadow = true;

// Configure shadow quality
directionalLight.shadow.mapSize.width = 2048;
directionalLight.shadow.mapSize.height = 2048;
directionalLight.shadow.camera.near = 0.5;
directionalLight.shadow.camera.far = 50;

scene.add(directionalLight);

// Objects cast and receive shadows
mesh.castShadow = true;
mesh.receiveShadow = true;

// Ground plane receives shadows
const groundGeometry = new THREE.PlaneGeometry(20, 20);
const groundMaterial = new THREE.MeshStandardMaterial({ color: 0x808080 });
const ground = new THREE.Mesh(groundGeometry, groundMaterial);
ground.rotation.x = -Math.PI / 2;
ground.receiveShadow = true;
scene.add(ground);
```

**Environment Maps & Reflections:**

```javascript
// Create environment map from cubemap
const loader = new THREE.CubeTextureLoader();
const envMap = loader.load([
  "px.jpg",
  "nx.jpg", // positive x, negative x
  "py.jpg",
  "ny.jpg", // positive y, negative y
  "pz.jpg",
  "nz.jpg", // positive z, negative z
]);

scene.environment = envMap; // Affects all PBR materials
scene.background = envMap; // Optional: use as skybox

// Or apply to specific materials
const material = new THREE.MeshStandardMaterial({
  metalness: 1.0,
  roughness: 0.1,
  envMap: envMap,
});
```

**Tone Mapping & Output Encoding:**

```javascript
// Improve color accuracy and HDR rendering
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.0;
renderer.outputColorSpace = THREE.SRGBColorSpace; // Was outputEncoding in older versions

// Makes colors more vibrant and realistic
```

**Fog for Depth:**

```javascript
// Linear fog
scene.fog = new THREE.Fog(0xcccccc, 10, 50); // color, near, far

// Or exponential fog (more realistic)
scene.fog = new THREE.FogExp2(0xcccccc, 0.02); // color, density
```

### Custom Geometry from Vertices

```javascript
const geometry = new THREE.BufferGeometry();
const vertices = new Float32Array([-1, -1, 0, 1, -1, 0, 1, 1, 0]);
geometry.setAttribute("position", new THREE.BufferAttribute(vertices, 3));
```

### Post-Processing Effects

Post-processing effects are available via import maps or build tools. See `threejs-postprocessing` skill for EffectComposer, bloom, DOF, and more.

### Group Objects

```javascript
const group = new THREE.Group();
group.add(mesh1);
group.add(mesh2);
group.rotation.y = Math.PI / 4;
scene.add(group);
```

## Summary

Three.js artifacts require systematic setup:

1. Import Three.js via import maps or build tools
2. Initialize scene, camera, renderer
3. Create geometry + material = mesh
4. Add lighting if using lit materials
5. Implement animation loop (prefer `setAnimationLoop`)
6. Handle window resize
7. Set `renderer.outputColorSpace = THREE.SRGBColorSpace`

Follow these patterns for reliable, performant 3D experiences.

## Modern Three.js Practices (r183)

### Modular Imports

```javascript
// With npm/vite/webpack:
import * as THREE from "three";
import { OrbitControls } from "three/addons/controls/OrbitControls.js";
import { GLTFLoader } from "three/addons/loaders/GLTFLoader.js";
import { EffectComposer } from "three/addons/postprocessing/EffectComposer.js";
```

### WebGPU Renderer (Alternative)

Three.js r183 includes a WebGPU renderer as an alternative to WebGL:

```javascript
import { WebGPURenderer } from "three/addons/renderers/webgpu/WebGPURenderer.js";

const renderer = new WebGPURenderer({ antialias: true });
await renderer.init();
renderer.setSize(window.innerWidth, window.innerHeight);
```

WebGPU uses TSL (Three.js Shading Language) instead of GLSL for custom shaders. See `threejs-shaders` for details.

### Timer (r183 Recommended)

`THREE.Timer` is recommended over `THREE.Clock` as of r183:

```javascript
const timer = new THREE.Timer();

renderer.setAnimationLoop(() => {
  timer.update();
  const delta = timer.getDelta();
  const elapsed = timer.getElapsed();

  mesh.rotation.y += delta;
  renderer.render(scene, camera);
});
```

**Benefits over Clock:**

- Not affected by page visibility (pauses when tab is hidden)
- Cleaner API design
- Better integration with `setAnimationLoop`

### Animation Libraries (GSAP Integration)

```javascript
// Smooth timeline-based animations
import gsap from "gsap";

// Instead of manual animation loops:
gsap.to(mesh.position, {
  x: 5,
  duration: 2,
  ease: "power2.inOut",
});

// Complex sequences:
const timeline = gsap.timeline();
timeline
  .to(mesh.rotation, { y: Math.PI * 2, duration: 2 })
  .to(mesh.scale, { x: 2, y: 2, z: 2, duration: 1 }, "-=1");
```

**Why GSAP:**

- Professional easing functions
- Timeline control (pause, reverse, scrub)
- Better than manual lerping for complex animations

### Scroll-Based Interactions

```javascript
// Sync 3D animations with page scroll
let scrollY = window.scrollY;

window.addEventListener("scroll", () => {
  scrollY = window.scrollY;
});

function animate() {
  requestAnimationFrame(animate);

  // Rotate based on scroll position
  mesh.rotation.y = scrollY * 0.001;

  // Move camera through scene
  camera.position.y = -(scrollY / window.innerHeight) * 10;

  renderer.render(scene, camera);
}
```

**Advanced scroll libraries:**

- ScrollTrigger (GSAP plugin)
- Locomotive Scroll
- Lenis smooth scroll

### Performance Optimization in Production

```javascript
// Level of Detail (LOD)
const lod = new THREE.LOD();
lod.addLevel(highDetailMesh, 0); // Close up
lod.addLevel(mediumDetailMesh, 10); // Medium distance
lod.addLevel(lowDetailMesh, 50); // Far away
scene.add(lod);

// Instanced meshes for many identical objects
const geometry = new THREE.BoxGeometry();
const material = new THREE.MeshStandardMaterial();
const instancedMesh = new THREE.InstancedMesh(geometry, material, 1000);

// Set transforms for each instance
const matrix = new THREE.Matrix4();
for (let i = 0; i < 1000; i++) {
  matrix.setPosition(
    Math.random() * 100,
    Math.random() * 100,
    Math.random() * 100,
  );
  instancedMesh.setMatrixAt(i, matrix);
}
```

### Modern Loading Patterns

```javascript
// In production, load 3D models:
import { GLTFLoader } from "three/examples/jsm/loaders/GLTFLoader";

const loader = new GLTFLoader();
loader.load("model.gltf", (gltf) => {
  scene.add(gltf.scene);

  // Traverse and setup materials
  gltf.scene.traverse((child) => {
    if (child.isMesh) {
      child.castShadow = true;
      child.receiveShadow = true;
    }
  });
});
```

### When to Use What

**Import Map Approach:**

- Quick prototypes and demos
- Educational content
- Artifacts and embedded experiences
- No build step required

**Production Build Approach:**

- Client projects and portfolios
- Complex applications
- Performance-critical applications
- Team collaboration with version control

### Recommended Production Stack

```
Three.js r183 + Vite
├── GSAP (animations)
├── React Three Fiber (optional - React integration)
├── Drei (helper components)
├── Leva (debug GUI)
└── Post-processing effects
```

## R3F Portfolio Patterns (production-verified, sunnypatell/react-threejs-portfolio)

Architecture rule: **Canvas layers are pure R3F — Framer Motion only in DOM layers.** Never mix them.
Each canvas component gets its own `<Canvas>` wrapper. Stars/background = `frameloop='always'`.
Static scenes like Earth = `frameloop='demand'` (renders only on state change — big perf win).

### Stars Background (full-page, behind all sections)

```jsx
// maath gives mathematically correct sphere point distribution — install: npm i maath
import * as random from 'maath/random/dist/maath-random.esm'
import { Points, PointMaterial, Preload } from '@react-three/drei'
import { Canvas, useFrame } from '@react-three/fiber'
import { useRef, useState } from 'react'

function Stars() {
  const ref = useRef()
  const [sphere] = useState(() => random.inSphere(new Float32Array(2001), { radius: 1.2 }))
  useFrame((_, delta) => {
    ref.current.rotation.x -= delta / 15
    ref.current.rotation.y -= delta / 20
  })
  return (
    <group rotation={[0, 0, Math.PI / 4]}>
      <Points ref={ref} positions={sphere} stride={3} frustumCulled>
        <PointMaterial transparent color="#915EFF" size={0.003} sizeAttenuation depthWrite={false} />
      </Points>
    </group>
  )
}

export function StarsCanvas() {
  return (
    <div className="w-full h-auto absolute inset-0 z-[-1]">
      <Canvas camera={{ position: [0, 0, 1] }}>
        <Stars />
        <Preload all />
      </Canvas>
    </div>
  )
}
// Note: z-index -1, pointerEvents none implied. Sits behind all section content.
// stride={3} = xyz packed Float32Array from maath. 2001 points = ~60fps on all devices.
```

### Tech Skill Ball (Decal on icosahedron)

```jsx
// Floating icosahedron with logo texture decal — used for skill grid icons
import { Float, OrbitControls, Preload, useTexture, Decal } from '@react-three/drei'
import { Canvas } from '@react-three/fiber'
import { Suspense } from 'react'

function Ball({ imgUrl }) {
  const [decal] = useTexture([imgUrl])
  return (
    <Float speed={1.75} rotationIntensity={1} floatIntensity={2}>
      <ambientLight intensity={0.25} />
      <directionalLight position={[0, 0, 0.05]} />
      <mesh castShadow receiveShadow scale={2.75}>
        <icosahedronGeometry args={[1, 1]} />  {/* low-poly for performance */}
        <meshStandardMaterial color="#fff8eb" polygonOffset polygonOffsetFactor={-5} flatShading />
        <Decal position={[0, 0, 1]} rotation={[2 * Math.PI, 0, 6.25]} scale={1} map={decal} flatShading />
      </mesh>
    </Float>
  )
}

export function BallCanvas({ icon }) {
  return (
    <Canvas frameloop="always" dpr={[1, 2]} gl={{ preserveDrawingBuffer: true }}>
      <Suspense fallback={<CanvasLoader />}>
        <OrbitControls enableZoom={false} />
        <Ball imgUrl={icon} />
      </Suspense>
      <Preload all />
    </Canvas>
  )
}
// polygonOffset prevents z-fighting between Decal and parent mesh
// icosahedronGeometry args=[1, 1] = subdivided once — smooth enough, very cheap
// gl.preserveDrawingBuffer needed for screenshot/export functionality
```

### GLTF Model Canvas (with mobile adaptation)

```jsx
// Pattern: detect mobile → adjust camera/scale/rotation, disable OrbitControls on mobile (use useFrame instead)
import { Canvas, useFrame } from '@react-three/fiber'
import { OrbitControls, Preload, useGLTF } from '@react-three/drei'
import { Suspense, useEffect, useRef, useState } from 'react'

function Model({ isMobile }) {
  const gltf = useGLTF('./model/scene.gltf')
  const meshRef = useRef()
  useFrame((_, delta) => {
    if (meshRef.current && isMobile) {
      meshRef.current.rotation.y += delta * 0.5  // manual rotation replaces OrbitControls on mobile
    }
  })
  return (
    <mesh ref={meshRef}>
      <hemisphereLight intensity={0.15} groundColor="black" />
      <spotLight position={[-20, 50, 10]} angle={0.12} penumbra={1} intensity={1} castShadow shadow-mapSize={1024} />
      <pointLight intensity={1} />
      <primitive
        object={gltf.scene}
        scale={0.75}
        position={isMobile ? [0, -3, 0] : [0, -3.25, -1.5]}
        rotation={isMobile ? [0, 0, 0] : [-0.01, -0.2, -0.1]}
      />
    </mesh>
  )
}

export function ModelCanvas() {
  const [isMobile, setIsMobile] = useState(false)
  useEffect(() => {
    const mq = window.matchMedia('(max-width: 500px)')
    setIsMobile(mq.matches)
    const handler = (e) => setIsMobile(e.matches)
    mq.addEventListener('change', handler)
    return () => mq.removeEventListener('change', handler)
  }, [])
  return (
    <Canvas
      frameloop="always"
      shadows
      dpr={[1, 2]}
      camera={isMobile ? { position: [0, 0, 20], fov: 50 } : { position: [20, 3, 5], fov: 25 }}
      gl={{ preserveDrawingBuffer: true }}
    >
      <Suspense fallback={<CanvasLoader />}>
        {!isMobile && <OrbitControls enableZoom={false} maxPolarAngle={Math.PI / 2} minPolarAngle={Math.PI / 2} autoRotate />}
        <Model isMobile={isMobile} />
      </Suspense>
      <Preload all />
    </Canvas>
  )
}
// Key decisions: OrbitControls only on desktop. Mobile uses useFrame manual rotation.
// fov 25 (desktop) = compressed perspective, model fills more of frame
// fov 50 (mobile) = wider, model farther back to fit smaller screen
```

### CanvasLoader (progress indicator inside Canvas)

```jsx
// useProgress from Drei + Html renders DOM inside the WebGL canvas
import { Html, useProgress } from '@react-three/drei'
import { useEffect, useState } from 'react'

export function CanvasLoader() {
  const { progress } = useProgress()
  const [show, setShow] = useState(true)
  useEffect(() => {
    if (progress === 100) setTimeout(() => setShow(false), 500)
  }, [progress])
  if (!show) return null
  return (
    <Html as="div" center>
      <p className="text-white text-lg font-bold">{progress.toFixed(0)}%</p>
    </Html>
  )
}
// Html component from Drei: renders actual DOM element anchored inside 3D space
// useProgress: globally tracks all useGLTF / useTexture loads across all Suspense boundaries
```

### Framer Motion Variant Factory (motion.js utility pattern)

```js
// Reusable variant factories — import once, use across all section components
// Source pattern: sunnypatell portfolio utils/motion.js

export const textVariant = (delay) => ({
  hidden: { y: -50, opacity: 0 },
  show: { y: 0, opacity: 1, transition: { type: 'spring', duration: 1.25, delay } },
})

export const fadeIn = (direction, type, delay, duration) => ({
  hidden: {
    x: direction === 'left' ? 100 : direction === 'right' ? -100 : 0,
    y: direction === 'up' ? 100 : direction === 'down' ? -100 : 0,
    opacity: 0,
  },
  show: {
    x: 0, y: 0, opacity: 1,
    transition: { type, delay, duration, ease: 'easeOut' },
  },
})

export const zoomIn = (delay, duration) => ({
  hidden: { scale: 0, opacity: 0 },
  show: { scale: 1, opacity: 1, transition: { type: 'tween', delay, duration, ease: 'easeOut' } },
})

export const slideIn = (direction, type, delay, duration) => ({
  hidden: {
    x: direction === 'left' ? '-100%' : direction === 'right' ? '100%' : 0,
    y: direction === 'up' || direction === 'down' ? '100%' : 0,
  },
  show: { x: 0, y: 0, transition: { type, delay, duration, ease: 'easeOut' } },
})

export const staggerContainer = (staggerChildren, delayChildren = 0) => ({
  hidden: {},
  show: { transition: { staggerChildren, delayChildren } },
})
// Usage: <motion.div variants={staggerContainer(0.1, 0.2)} initial="hidden" whileInView="show">
//   <motion.p variants={fadeIn('right', 'spring', 0.5, 0.75)}>...</motion.p>
// </motion.div>
```

### SectionWrapper HOC (scroll ID anchoring + enter animation)

```jsx
// HOC that wraps every section: adds padding, section ID for nav anchoring, stagger enter
import { motion } from 'framer-motion'
import { staggerContainer } from '../utils/motion'

export function SectionWrapper(Component, idName) {
  return function HOC(props) {
    return (
      <motion.section
        variants={staggerContainer()}
        initial="hidden"
        whileInView="show"
        viewport={{ once: true, amount: 0.25 }}  // fires once, 25% visible
        className="sm:px-16 px-6 sm:py-16 py-10 max-w-7xl mx-auto relative z-0"
      >
        <span className="hash-span" id={idName}>&nbsp;</span>
        <Component {...props} />
      </motion.section>
    )
  }
}
// Usage: export default SectionWrapper(About, 'about')
// hash-span trick: gives negative-margin anchor above section for fixed-nav scroll offset
// whileInView triggers animation when scrolled into viewport — no manual useInView needed
```

### useInView + useAnimation (imperative scroll trigger)

```jsx
// When whileInView isn't enough (e.g. staggered children that need full control)
import { useAnimation, useInView } from 'framer-motion'
import { useEffect, useRef } from 'react'

export function AnimatedSection({ children }) {
  const ref = useRef(null)
  const isInView = useInView(ref, { once: true, amount: 0.2 })
  const controls = useAnimation()

  useEffect(() => {
    if (isInView) controls.start('visible')
  }, [isInView, controls])

  return (
    <motion.div
      ref={ref}
      initial="hidden"
      animate={controls}
      variants={{
        hidden: { opacity: 0, y: -20 },
        visible: { opacity: 1, y: 0, transition: { duration: 0.6 } },
      }}
    >
      {children}
    </motion.div>
  )
}
// useInView fires once → calls controls.start('visible') → all children animate in
// Prefer whileInView for simple cases. Use useInView + useAnimation for multi-step sequences.
```

### Typewriter Text (per-character Framer Motion)

```jsx
// Cycles through an array of role strings with typing + blinking cursor
import { motion } from 'framer-motion'
import { useState, useEffect } from 'react'

export function TypewriterText({ texts }) {
  const [display, setDisplay] = useState('')
  const [index, setIndex] = useState(0)
  const [typing, setTyping] = useState(true)

  useEffect(() => {
    const id = setInterval(() => {
      if (typing) {
        const current = texts[index]
        if (display.length < current.length) {
          setDisplay(current.slice(0, display.length + 1))
        } else {
          setTyping(false)
          clearInterval(id)
          setTimeout(() => { setTyping(true); setDisplay(''); setIndex(i => (i + 1) % texts.length) }, 2000)
        }
      }
    }, 100)
    return () => clearInterval(id)
  }, [index, typing, texts, display])

  return (
    <span className="text-[#915EFF] font-bold">
      {display.split('').map((char, i) => (
        <motion.span key={i} initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.1 }}>
          {char}
        </motion.span>
      ))}
      {typing && (
        <motion.span
          initial={{ opacity: 0 }} animate={{ opacity: 1 }}
          transition={{ duration: 0.5, repeat: Infinity, repeatType: 'reverse' }}
          className="ml-1"
        >|</motion.span>
      )}
    </span>
  )
}
// Per-character motion.span: each letter fades in individually as it's typed
// Cursor blinks with repeat Infinity + repeatType 'reverse' — no CSS keyframes needed
```

### Honeycomb Skill Grid (dynamic row sizing)

```jsx
// Responsive honeycomb layout: alternating rows of 6/5 items, staggered offset
// CSS: .honeycomb-row.staggered-row { margin-left: calc(hexWidth / 2 + gap / 2) }
// .hexagon { clip-path: polygon(50% 0%, 100% 25%, 100% 75%, 50% 100%, 0% 75%, 0% 25%) }

function calculateRows(windowWidth, items) {
  if (windowWidth < 500) {
    return [items.slice(0, 3), items.slice(3, 5), items.slice(5, 8), items.slice(8, 10)]
  }
  const rows = []
  let i = 0, rowSize = 6
  while (i < items.length) {
    rows.push(items.slice(i, i + rowSize))
    i += rowSize
    rowSize = rowSize === 6 ? 5 : 6  // alternate 6/5/6/5
  }
  return rows
}

// Stagger animation on enter:
const hexagonVariants = {
  hidden: { opacity: 0, scale: 0.8 },
  visible: { opacity: 1, scale: 1, transition: { delay: Math.random() * 1.5, duration: 0.5, type: 'spring' } },
  hover: { scale: 1.05, zIndex: 2, transition: { duration: 0.3 } },
}
// Note: Math.random() * 1.5 delay creates organic cascade — not uniform stagger
// Each hexagon triggers whileHover="hover" for subtle lift effect
```

## Limitations
- Use this skill only when the task clearly matches the scope described above.
- Do not treat the output as a substitute for environment-specific validation, testing, or expert review.
- Stop and ask for clarification if required inputs, permissions, safety boundaries, or success criteria are missing.
