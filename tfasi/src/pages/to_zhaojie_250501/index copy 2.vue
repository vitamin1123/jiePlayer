<template>
  <div ref="container"></div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount } from 'vue';
import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';

const container = ref(null);
let camera, scene, renderer, controls;
let points, currentStage = 0;
const POINT_COUNT = 10000;
const ANIMATION_DURATION = 15;
const STAGE_DELAY = 5000;

// 缓动函数
const easeOutElastic = (t) => {
  return Math.pow(2, -10 * t) * Math.sin((t - 0.075) * (2 * Math.PI) / 0.3) + 1;
};

// 创建长方形点阵
const createRectangleGrid = (width = 1.8, height = 0.4, density = 50) => {
  const points = [];
  const wStep = width / density;
  const hStep = height / density;
  
  for (let x = -width/2; x <= width/2; x += wStep) {
    for (let y = -height/2; y <= height/2; y += hStep) {
      points.push({
        x: x,
        y: y - 0.8,
        z: 0
      });
    }
  }
  return points;
};

// 创建球体烟花
const createSphereFirework = (radius = 0.3, count = 500) => {
  const points = [];
  for (let i = 0; i < count; i++) {
    const theta = Math.random() * Math.PI * 2;
    const phi = Math.acos(2 * Math.random() - 1);
    const r = radius * Math.pow(Math.random(), 1/3);
    
    points.push({
      x: r * Math.sin(phi) * Math.cos(theta),
      y: r * Math.sin(phi) * Math.sin(theta),
      z: r * Math.cos(phi),
      angle: theta,
      distance: r / radius
    });
  }
  return points;
};

// 创建流星线
const createMeteorLines = () => {
  const points = [];
  const lineCount = 5;
  const length = 0.6;
  
  for (let l = 0; l < lineCount; l++) {
    const startX = -0.9 + l * 0.1;
    const startY = 0.7 - l * 0.05;
    const pointsInLine = 50;
    
    for (let i = 0; i < pointsInLine; i++) {
      const ratio = i / pointsInLine;
      points.push({
        x: startX + ratio * length,
        y: startY - ratio * length,
        z: 0,
        lineIndex: l,
        pointIndex: i
      });
    }
  }
  return points;
};

// 加载汉字图片并离散为点阵  
const loadChineseCharacter = async () => {
  return new Promise((resolve) => {
    const img = new Image();
    img.src = './assets/imgs/赵洁.png';
    img.onload = () => {
      const canvas = document.createElement('canvas');
      const ctx = canvas.getContext('2d');
      canvas.width = img.width;
      canvas.height = img.height;
      ctx.drawImage(img, 0, 0);
      
      const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
      const data = imageData.data;
      const points = [];
      const step = 4;
      
      for(let y = 0; y < canvas.height; y += step) {
        for(let x = 0; x < canvas.width; x += step) {
          const index = (y * canvas.width + x) * 4;
          if(data[index + 3] > 0) {
            const nx = (x / canvas.width * 2 - 1) * 0.8;
            const ny = (1 - y / canvas.height) * 2 - 1;
            points.push({ 
              x: nx, 
              y: ny, 
              z: 0,
              originalX: nx,
              originalY: ny
            });
          }
        }
      }
      resolve(points);
    };
  });
};

onMounted(async () => {
  // 初始化场景
  camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 0.25, 20);
  camera.position.set(-1.8, 0.6, 2.7);

  scene = new THREE.Scene();
  renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.setPixelRatio(window.devicePixelRatio);
  renderer.setSize(window.innerWidth, window.innerHeight);
  container.value.appendChild(renderer.domElement);

  controls = new OrbitControls(camera, renderer.domElement);
  controls.minDistance = 2;
  controls.maxDistance = 10;

  // 加载全景背景
  const loader = new THREE.CubeTextureLoader().setPath('./assets/city/');
  scene.background = await loader.loadAsync(['px.jpg', 'nx.jpg', 'py.jpg', 'ny.jpg', 'pz.jpg', 'nz.jpg']);

  // 创建环境光
  scene.add(new THREE.AmbientLight(0x404040));

  // 加载所有点阵
  const chinesePoints = await loadChineseCharacter();
  const rectanglePoints = createRectangleGrid();
  const fireworkPoints = [
    ...createSphereFirework(0.2, 800),
    ...createSphereFirework(0.15, 600),
    ...createSphereFirework(0.1, 400)
  ];
  const meteorPoints = createMeteorLines();

  // 创建点阵系统
  const geometry = new THREE.BufferGeometry();
  const positions = new Float32Array(POINT_COUNT * 3);
  const colors = new Float32Array(POINT_COUNT * 3);
  const sizes = new Float32Array(POINT_COUNT);
  const types = new Float32Array(POINT_COUNT);

  // 初始位置（长方形点阵）
  for(let i = 0; i < POINT_COUNT; i++) {
    if (i < rectanglePoints.length) {
      const p = rectanglePoints[i];
      positions[i*3] = p.x;
      positions[i*3+1] = p.y;
      positions[i*3+2] = p.z;
      types[i] = 3;
    } 
    else if (i < rectanglePoints.length + chinesePoints.length) {
      const p = chinesePoints[i - rectanglePoints.length];
      positions[i*3] = p.originalX;
      positions[i*3+1] = p.originalY;
      positions[i*3+2] = 0;
      types[i] = 0;
    }
    else if (i < rectanglePoints.length + chinesePoints.length + fireworkPoints.length) {
      const p = fireworkPoints[i - rectanglePoints.length - chinesePoints.length];
      positions[i*3] = 0.7 + p.x;
      positions[i*3+1] = 0.5 + p.y;
      positions[i*3+2] = p.z;
      types[i] = 1;
    }
    else if (i < rectanglePoints.length + chinesePoints.length + fireworkPoints.length + meteorPoints.length) {
      const p = meteorPoints[i - rectanglePoints.length - chinesePoints.length - fireworkPoints.length];
      positions[i*3] = p.x;
      positions[i*3+1] = p.y;
      positions[i*3+2] = p.z;
      types[i] = 2;
    }
    else {
      positions[i*3] = (Math.random() - 0.5) * 2;
      positions[i*3+1] = (Math.random() - 0.5) * 2;
      positions[i*3+2] = (Math.random() - 0.5) * 2;
      types[i] = Math.floor(Math.random() * 4);
    }
    
    sizes[i] = 0.015 + Math.random() * 0.01;
  }

  geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
  geometry.setAttribute('color', new THREE.BufferAttribute(colors, 3));
  geometry.setAttribute('size', new THREE.BufferAttribute(sizes, 1));
  geometry.setAttribute('type', new THREE.BufferAttribute(types, 1));

  const material = new THREE.PointsMaterial({
    size: 0.02,
    vertexColors: true,
    sizeAttenuation: true,
    transparent: true,
    opacity: 0.9,
    blending: THREE.AdditiveBlending
  });

  points = new THREE.Points(geometry, material);
  scene.add(points);

  // 动画控制
  let animationStartTime = Date.now();
  let currentTarget = 'init';
  let nextTarget = 'text';
  let globalTime = 0;

  const animate = () => {
    requestAnimationFrame(animate);
    
    globalTime += 0.016;
    const time = Date.now() * 0.001;
    const positions = points.geometry.attributes.position.array;
    const colors = points.geometry.attributes.color.array;
    const types = points.geometry.attributes.type.array;

    // 计算动画进度
    const progress = Math.min((Date.now() - animationStartTime) / (ANIMATION_DURATION * 1000), 1);
    
    // 阶段转换
    if(progress >= 1 && Date.now() - animationStartTime > STAGE_DELAY) {
      animationStartTime = Date.now();
      currentTarget = nextTarget;
      nextTarget = currentTarget === 'text' ? 'firework' : 'text';
    }

    // 处理所有点
    for(let i = 0; i < POINT_COUNT; i++) {
      const type = types[i];
      const delayFactor = (i % 100) / 100;
      const easedProgress = Math.max(0, Math.min(1, (progress - delayFactor * 0.7) / (1 - delayFactor * 0.7)));
      
      // 初始化目标位置
      let targetX = positions[i*3];
      let targetY = positions[i*3+1];
      let targetZ = positions[i*3+2];
      
      // 根据点类型处理
      if (type === 3) { // 长方形点阵
        if (easedProgress < 0.5) {
          targetY = 0;
        }
        
        const hue = (i * 0.01 + time * 0.1) % 1;
        const color = new THREE.Color().setHSL(hue, 0.9, 0.7);
        colors[i*3] = color.r;
        colors[i*3+1] = color.g;
        colors[i*3+2] = color.b;
      }
      else if (type === 0) { // 汉字点阵
        const point = chinesePoints[i % chinesePoints.length] || {x:0,y:0,z:0};
        
        const flowProgress = ((point.originalX + 1) + (1 - point.originalY)) / 4;
        const flowTime = (globalTime * 0.5 + flowProgress) % 1;
        
        if (flowTime < 0.3) {
          const intensity = Math.min(1, flowTime / 0.3);
          colors[i*3] = 1 * intensity;
          colors[i*3+1] = 0.9 * intensity;
          colors[i*3+2] = 0.5 * intensity;
        } else {
          colors[i*3] = Math.min(1, colors[i*3] + 0.01);
          colors[i*3+1] = Math.min(1, colors[i*3+1] + 0.01);
          colors[i*3+2] = Math.min(1, colors[i*3+2] + 0.01);
        }
        
        if (currentTarget === 'text') {
          targetX = point.x;
          targetY = point.y;
          targetZ = point.z || 0;
        } else {
          const angle = Math.atan2(positions[i*3+2], positions[i*3]);
          const radius = Math.sqrt(positions[i*3]*positions[i*3] + positions[i*3+2]*positions[i*3+2]);
          targetX = Math.cos(angle) * radius * 1.2;
          targetY = Math.sin(angle) * radius * 1.2;
          targetZ = (Math.random() - 0.5) * 0.5;
        }
      }
      else if (type === 1) { // 烟花球体
        const point = fireworkPoints[i % fireworkPoints.length] || {x:0,y:0,z:0};
        
        const colorTime = (globalTime * 0.3 + point.distance) % 1;
        const hue = colorTime;
        const color = new THREE.Color().setHSL(hue, 0.9, 0.7);
        colors[i*3] = color.r;
        colors[i*3+1] = color.g;
        colors[i*3+2] = color.b;
        
        targetX = 0.7 + point.x;
        targetY = 0.5 + point.y;
        targetZ = point.z;
      }
      else if (type === 2) { // 流星线
        const point = meteorPoints[i % meteorPoints.length] || {x:0,y:0,z:0};
        
        const pulseTime = (globalTime * 0.8 + point.lineIndex * 0.2) % 1;
        const pulseProgress = Math.max(0, Math.min(1, (pulseTime - point.pointIndex * 0.02) * 10));
        
        if (pulseProgress > 0 && pulseProgress < 1) {
          colors[i*3] = 1;
          colors[i*3+1] = 0.9;
          colors[i*3+2] = 0.5 * pulseProgress;
        } else {
          colors[i*3] = 0.1;
          colors[i*3+1] = 0.1;
          colors[i*3+2] = 0.1;
        }
        
        targetX = point.x;
        targetY = point.y;
        targetZ = point.z;
      }
      
      // 应用位置动画
      const eased = easeOutElastic(easedProgress);
      positions[i*3] += (targetX - positions[i*3]) * eased * 0.1;
      positions[i*3+1] += (targetY - positions[i*3+1]) * eased * 0.1;
      positions[i*3+2] += (targetZ - positions[i*3+2]) * eased * 0.1;
    }

    points.geometry.attributes.position.needsUpdate = true;
    points.geometry.attributes.color.needsUpdate = true;
    renderer.render(scene, camera);
  };

  animate();
  window.addEventListener('resize', onWindowResize);
});

onBeforeUnmount(() => {
  if (controls) controls.dispose();
  if (renderer) renderer.dispose();
  window.removeEventListener('resize', onWindowResize);
});

function onWindowResize() {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
}
</script>

<style>
body {
  margin: 0;
  overflow: hidden;
}
</style>