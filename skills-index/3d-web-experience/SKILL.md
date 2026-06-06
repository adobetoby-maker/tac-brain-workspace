---
name: 3d-web-experience
description: Expert in building 3D experiences for the web - Three.js, React
  Three Fiber, Spline, WebGL, and interactive 3D scenes. Covers product
  configurators, 3D portfolios, immersive websites, and bringing depth to web
  experiences.
risk: unknown
source: vibeship-spawner-skills (Apache 2.0)
date_added: 2026-02-27
---

# 3D Web Experience

Expert in building 3D experiences for the web - Three.js, React Three Fiber,
Spline, WebGL, and interactive 3D scenes. Covers product configurators, 3D
portfolios, immersive websites, and bringing depth to web experiences.

**Role**: 3D Web Experience Architect

You bring the third dimension to the web. You know when 3D enhances
and when it's just showing off. You balance visual impact with
performance. You make 3D accessible to users who've never touched
a 3D app. You create moments of wonder without sacrificing usability.

### Expertise

- Three.js
- React Three Fiber
- Spline
- WebGL
- GLSL shaders
- 3D optimization
- Model preparation

## Capabilities

- Three.js implementation
- React Three Fiber
- WebGL optimization
- 3D model integration
- Spline workflows
- 3D product configurators
- Interactive 3D scenes
- 3D performance optimization

## Patterns

### 3D Stack Selection

Choosing the right 3D approach

**When to use**: When starting a 3D web project

## 3D Stack Selection

### Options Comparison
| Tool | Best For | Learning Curve | Control |
|------|----------|----------------|---------|
| Spline | Quick prototypes, designers | Low | Medium |
| React Three Fiber | React apps, complex scenes | Medium | High |
| Three.js vanilla | Max control, non-React | High | Maximum |
| Babylon.js | Games, heavy 3D | High | Maximum |

### Decision Tree
```
Need quick 3D element?
└── Yes → Spline
└── No → Continue

Using React?
└── Yes → React Three Fiber
└── No → Continue

Need max performance/control?
└── Yes → Three.js vanilla
└── No → Spline or R3F
```

### Spline (Fastest Start)
```jsx
import Spline from '@splinetool/react-spline';

export default function Scene() {
  return (
    <Spline scene="https://prod.spline.design/xxx/scene.splinecode" />
  );
}
```

### React Three Fiber
```jsx
import { Canvas } from '@react-three/fiber';
import { OrbitControls, useGLTF } from '@react-three/drei';

function Model() {
  const { scene } = useGLTF('/model.glb');
  return <primitive object={scene} />;
}

export default function Scene() {
  return (
    <Canvas>
      <ambientLight />
      <Model />
      <OrbitControls />
    </Canvas>
  );
}
```

### 3D Model Pipeline

Getting models web-ready

**When to use**: When preparing 3D assets

## 3D Model Pipeline

### Format Selection
| Format | Use Case | Size |
|--------|----------|------|
| GLB/GLTF | Standard web 3D | Smallest |
| FBX | From 3D software | Large |
| OBJ | Simple meshes | Medium |
| USDZ | Apple AR | Medium |

### Optimization Pipeline
```
1. Model in Blender/etc
2. Reduce poly count (< 100K for web)
3. Bake textures (combine materials)
4. Export as GLB
5. Compress with gltf-transform
6. Test file size (< 5MB ideal)
```

### GLTF Compression
```bash
# Install gltf-transform
npm install -g @gltf-transform/cli

# Compress model
gltf-transform optimize input.glb output.glb \
  --compress draco \
  --texture-compress webp
```

### Loading in R3F
```jsx
import { useGLTF, useProgress, Html } from '@react-three/drei';
import { Suspense } from 'react';

function Loader() {
  const { progress } = useProgress();
  return <Html center>{progress.toFixed(0)}%</Html>;
}

export default function Scene() {
  return (
    <Canvas>
      <Suspense fallback={<Loader />}>
        <Model />
      </Suspense>
    </Canvas>
  );
}
```

### Scroll-Driven 3D

3D that responds to scroll

**When to use**: When integrating 3D with scroll

## Scroll-Driven 3D

### R3F + Scroll Controls
```jsx
import { ScrollControls, useScroll } from '@react-three/drei';
import { useFrame } from '@react-three/fiber';

function RotatingModel() {
  const scroll = useScroll();
  const ref = useRef();

  useFrame(() => {
    // Rotate based on scroll position
    ref.current.rotation.y = scroll.offset * Math.PI * 2;
  });

  return <mesh ref={ref}>...</mesh>;
}

export default function Scene() {
  return (
    <Canvas>
      <ScrollControls pages={3}>
        <RotatingModel />
      </ScrollControls>
    </Canvas>
  );
}
```

### GSAP + Three.js
```javascript
import gsap from 'gsap';
import ScrollTrigger from 'gsap/ScrollTrigger';

gsap.to(camera.position, {
  scrollTrigger: {
    trigger: '.section',
    scrub: true,
  },
  z: 5,
  y: 2,
});
```

### Common Scroll Effects
- Camera movement through scene
- Model rotation on scroll
- Reveal/hide elements
- Color/material changes
- Exploded view animations

### Performance Optimization

Keeping 3D fast

**When to use**: Always - 3D is expensive

## 3D Performance

### Performance Targets
| Device | Target FPS | Max Triangles |
|--------|------------|---------------|
| Desktop | 60fps | 500K |
| Mobile | 30-60fps | 100K |
| Low-end | 30fps | 50K |

### Quick Wins
```jsx
// 1. Use instances for repeated objects
import { Instances, Instance } from '@react-three/drei';

// 2. Limit lights
<ambientLight intensity={0.5} />
<directionalLight /> // Just one

// 3. Use LOD (Level of Detail)
import { LOD } from 'three';

// 4. Lazy load models
const Model = lazy(() => import('./Model'));
```

### Mobile Detection
```jsx
const isMobile = /iPhone|iPad|Android/i.test(navigator.userAgent);

<Canvas
  dpr={isMobile ? 1 : 2} // Lower resolution on mobile
  performance={{ min: 0.5 }} // Allow frame drops
>
```

### Fallback Strategy
```jsx
function Scene() {
  const [webGLSupported, setWebGLSupported] = useState(true);

  if (!webGLSupported) {
    return <img src="/fallback.png" alt="3D preview" />;
  }

  return <Canvas onCreated={...} />;
}
```

## Validation Checks

### No 3D Loading Indicator

Severity: HIGH

Message: No loading indicator for 3D content.

Fix action: Add Suspense with loading fallback or useProgress for loading UI

### No WebGL Fallback

Severity: MEDIUM

Message: No fallback for devices without WebGL support.

Fix action: Add WebGL detection and static image fallback

### Uncompressed 3D Models

Severity: MEDIUM

Message: 3D models may be unoptimized.

Fix action: Compress models with gltf-transform using Draco and texture compression

### OrbitControls Blocking Scroll

Severity: MEDIUM

Message: OrbitControls may be capturing scroll events.

Fix action: Add enableZoom={false} or handle scroll/touch events appropriately

### High DPR on Mobile

Severity: MEDIUM

Message: Canvas DPR may be too high for mobile devices.

Fix action: Limit DPR to 1 on mobile devices for better performance

## Collaboration

### Delegation Triggers

- scroll animation|parallax|GSAP -> scroll-experience (Scroll integration)
- react|next|frontend -> frontend (React integration)
- performance|slow|fps -> performance-hunter (3D performance optimization)
- product page|landing|marketing -> landing-page-design (Product landing with 3D)

### Product Configurator

Skills: 3d-web-experience, frontend, landing-page-design

Workflow:

```
1. Prepare 3D product model
2. Set up React Three Fiber scene
3. Add interactivity (colors, variants)
4. Integrate with product page
5. Optimize for mobile
6. Add fallback images
```

### Immersive Portfolio

Skills: 3d-web-experience, scroll-experience, interactive-portfolio

Workflow:

```
1. Design 3D scene concept
2. Build scene in Spline or R3F
3. Add scroll-driven animations
4. Integrate with portfolio sections
5. Ensure mobile fallback
6. Optimize performance
```

## Related Skills

Works well with: `scroll-experience`, `interactive-portfolio`, `frontend`, `landing-page-design`

## When to Use
- User mentions or implies: 3D website
- User mentions or implies: three.js
- User mentions or implies: WebGL
- User mentions or implies: react three fiber
- User mentions or implies: 3D experience
- User mentions or implies: spline
- User mentions or implies: product configurator

## Portfolio Architecture (R3F + Framer Motion separation, production pattern)

### Layer Separation Rule
Never put Framer Motion inside a `<Canvas>`. Never put Three.js in section components.
```
Layout (DOM)
├── <StarsCanvas />      ← absolute z-[-1], pure R3F, frameloop='always'
├── <Navbar />           ← Framer Motion slide-in
├── <Hero />             ← Framer Motion text + <ComputersCanvas /> inline
├── <SectionWrapper>     ← staggerContainer whileInView
│   └── <About />        ← fadeIn variants, useInView+useAnimation
├── <SectionWrapper>
│   └── <Tech />         ← honeycomb grid, BallCanvas per icon
├── <SectionWrapper>
│   └── <Contact />      ← <EarthCanvas /> beside form
└── footer
```
Each Canvas is isolated — a WebGL crash in one doesn't affect others.

### frameloop Strategy
| Canvas | frameloop | Why |
|--------|-----------|-----|
| Stars background | `'always'` | Continuous slow rotation needed |
| Desktop PC model | `'always'` | OrbitControls + useFrame rotation |
| Skill ball | `'always'` | Float animation via useFrame |
| Earth globe | `'demand'` | Only renders on OrbitControls input |

### Mobile Strategy
```jsx
// Pattern used in every canvas component:
const [isMobile, setIsMobile] = useState(false)
useEffect(() => {
  const mq = window.matchMedia('(max-width: 500px)')
  setIsMobile(mq.matches)
  const handler = (e) => setIsMobile(e.matches)
  mq.addEventListener('change', handler)
  return () => mq.removeEventListener('change', handler)
}, [])
// Then: disable OrbitControls on mobile, use useFrame rotation instead
// Adjust camera position/FOV, model scale/position per device
```

### Key Drei Components Used
| Component | Purpose |
|-----------|---------|
| `Float` | Floating/bobbing animation — wraps any mesh, zero custom code |
| `Decal` | Apply image texture to mesh face — used for tech skill logos |
| `Points` + `PointMaterial` | Star fields from Float32Array positions |
| `OrbitControls autoRotate` | Auto-spinning model, disable zoom |
| `useGLTF` | Load `.gltf`/`.glb` models, returns `{ scene }` |
| `useTexture` | Load image as texture for Decal or material map |
| `Html` | Render DOM (loading %) anchored inside 3D space |
| `useProgress` | Global asset load progress across all Suspense boundaries |
| `Preload all` | Preloads all GLTF/textures in the Canvas |

### Service Card with Gradient Border + Icon Rotation
```jsx
// Gradient border via wrapper div — avoids CSS border-image limitations
<motion.div
  variants={fadeIn('up', 'spring', index * 0.5, 0.75)}
  whileHover={{ scale: 1.05 }}
  whileTap={{ scale: 0.95 }}
  className="p-[1px] rounded-[20px]"
  style={{ background: 'linear-gradient(135deg, #00cea8, #bf61ff)' }}
>
  <div className="bg-[#1d1836] rounded-[20px] py-5 px-12 min-h-[280px] flex flex-col items-center justify-evenly">
    <motion.img
      src={icon}
      className="w-16 h-16 object-contain"
      whileHover={{ rotate: 360 }}
      transition={{ duration: 0.8, ease: 'easeInOut' }}
    />
    <h3 className="text-white text-[20px] font-bold text-center">{title}</h3>
    {/* Overlay shimmer on hover */}
    <motion.div
      className="absolute inset-0 rounded-[20px] bg-gradient-to-r from-purple-500 to-pink-500 opacity-0"
      whileHover={{ opacity: 0.2 }}
      transition={{ duration: 0.3 }}
    />
  </div>
</motion.div>
// p-[1px] + gradient background = 1px gradient border that works with border-radius
// overlay div with opacity 0→0.2 on hover = shimmer without CSS keyframes
```

### Scroll Indicator (bounce arrow)
```jsx
// Bouncing mouse-scroll indicator — standard portfolio bottom-of-hero element
<div className="absolute bottom-10 w-full flex justify-center">
  <a href="#about">
    <div className="w-[35px] h-[64px] rounded-3xl border-4 border-white/30 flex justify-start items-start p-2">
      <motion.div
        animate={{ y: [0, 24, 0] }}
        transition={{ duration: 1.5, repeat: Infinity, repeatType: 'loop' }}
        className="w-3 h-3 rounded-full bg-white/40"
      />
    </div>
  </a>
</div>
// y: [0, 24, 0] keyframe array — Three-point tween, no need for css @keyframes
// Anchors to next section ID for smooth scroll
```

### CSS Gradient Text (category labels)
```jsx
// WebKit gradient text — used for section category labels like <programming>
<h2 style={{
  background: 'linear-gradient(90deg, #915EFF, #00BFFF)',
  WebkitBackgroundClip: 'text',
  WebkitTextFillColor: 'transparent',
  backgroundClip: 'text',
  filter: 'drop-shadow(0 0 10px #915EFF)',
}}>
  {'<programming>'}
</h2>
// WebkitTextFillColor: 'transparent' is required alongside WebkitBackgroundClip
// drop-shadow (not box-shadow) applies to text glyphs themselves
```

### maath — Math Utilities for 3D
```bash
npm i maath
# Provides: random sphere/disk/torus point sampling, easing functions, interpolation
```
```js
import * as random from 'maath/random/dist/maath-random.esm'
// Generate 2001 points uniformly distributed on a sphere surface:
const sphere = random.inSphere(new Float32Array(2001), { radius: 1.2 })
// Pass directly to <Points positions={sphere} stride={3} />
```
`inSphere` uses Marsaglia's rejection method — statistically uniform, no polar clustering.

## Limitations
- Use this skill only when the task clearly matches the scope described above.
- Do not treat the output as a substitute for environment-specific validation, testing, or expert review.
- Stop and ask for clarification if required inputs, permissions, safety boundaries, or success criteria are missing.
