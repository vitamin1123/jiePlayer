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
const POINT_COUNT = 5000;
const ANIMATION_DURATION = 15;
const STAGE_DELAY = 5000;

// 缓动函数
const easeOutElastic = (t) => {
  return Math.pow(2, -10 * t) * Math.sin((t - 0.075) * (2 * Math.PI) / 0.3) + 1;
};

// 烟花形状定义
const createFireworkShape = () => {
  const points = [];
  const layers = 5;
  for(let l = 0; l < layers; l++) {
    const radius = 0.2 + l * 0.15;
    const count = 100 + l * 50;
    for(let i = 0; i < count; i++) {
      const angle = (i * 2 * Math.PI) / count;
      const variance = 0.05 * Math.random();
      points.push({
        x: radius * Math.cos(angle) + variance,
        y: radius * Math.sin(angle) + variance,
        z: (l - layers/2) * 0.1
      });
    }
  }
  return points;
};

// 加载汉字图片并离散为点阵  
const loadChineseCharacter = async () => {
  return new Promise((resolve) => {
    const img = new Image();
    img.src = './assets/imgs/赵洁.png'; // 替换为你的汉字图片路径
    img.onload = () => {
      const canvas = document.createElement('canvas');
      const ctx = canvas.getContext('2d');
      canvas.width = img.width;
      canvas.height = img.height;
      ctx.drawImage(img, 0, 0);
      
      const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
      const data = imageData.data;
      const points = [];
      const step = 4; // 采样步长，值越大点数越少
      
      for(let y = 0; y < canvas.height; y += step) {
        for(let x = 0; x < canvas.width; x += step) {
          const index = (y * canvas.width + x) * 4;
          // 检查像素是否不透明（alpha > 0）
          if(data[index + 3] > 0) {
            // 将坐标归一化到-1到1范围
            const nx = (x / canvas.width * 2 - 1) * 0.8; // 宽度缩小
            const ny = (1 - y / canvas.height) * 2 - 1; // 翻转Y轴并居中
            points.push({ x: nx, y: ny, z: 0 });
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

  // 加载汉字点阵
  const chinesePoints = await loadChineseCharacter();
  
  // 创建点阵系统
  const geometry = new THREE.BufferGeometry();
  const positions = new Float32Array(POINT_COUNT * 3);
  const colors = new Float32Array(POINT_COUNT * 3);
  const sizes = new Float32Array(POINT_COUNT);

  // 初始位置（在地面排列）
  for(let i = 0; i < POINT_COUNT; i++) {
    const angle = Math.random() * Math.PI * 2;
    const radius = Math.sqrt(Math.random()) * 0.9;
    positions[i*3] = Math.cos(angle) * radius;
    positions[i*3+1] = -0.95;
    positions[i*3+2] = Math.sin(angle) * radius;
    sizes[i] = 0.015 + Math.random() * 0.01;
  }

  geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
  geometry.setAttribute('color', new THREE.BufferAttribute(colors, 3));
  geometry.setAttribute('size', new THREE.BufferAttribute(sizes, 1));

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
  let currentTarget = 'ground';
  let nextTarget = 'text';
  const fireworkPoints = createFireworkShape();

  const animate = () => {
    requestAnimationFrame(animate);
    
    const time = Date.now() * 0.001;
    const positions = points.geometry.attributes.position.array;
    const colors = points.geometry.attributes.color.array;
    
    // 颜色渐变
    for(let i = 0; i < POINT_COUNT; i++) {
      const hue = (time * 0.05 + i * 0.00005) % 1;
      const saturation = 0.8 + Math.sin(time * 0.5 + i * 0.001) * 0.2;
      const color = new THREE.Color().setHSL(hue, saturation, 0.7);
      colors[i*3] = color.r;
      colors[i*3+1] = color.g;
      colors[i*3+2] = color.b;
    }

    // 计算动画进度
    const progress = Math.min((Date.now() - animationStartTime) / (ANIMATION_DURATION * 1000), 1);
    
    // 阶段转换
    if(progress >= 1 && Date.now() - animationStartTime > STAGE_DELAY) {
      animationStartTime = Date.now();
      currentTarget = nextTarget;
      nextTarget = currentTarget === 'text' ? 'firework' : 'text';
    }

    // 应用动画
    for(let i = 0; i < POINT_COUNT; i++) {
      const delayFactor = (i % 100) / 100;
      const easedProgress = Math.max(0, Math.min(1, (progress - delayFactor * 0.7) / (1 - delayFactor * 0.7)));
      
      let targetX, targetY, targetZ;
      
      if(currentTarget === 'text') {
        const point = chinesePoints[i % chinesePoints.length] || {x:0,y:0,z:0};
        targetX = point.x;
        targetY = point.y;
        targetZ = point.z || 0;
        
        if(easedProgress < 0.5) {
          const spiralProgress = easedProgress * 2;
          const angle = (i % 20) * 0.3 + spiralProgress * Math.PI * 2;
          const radius = 0.3 * spiralProgress;
          targetY = -0.95 + spiralProgress * (point.y + 0.95 + 0.5);
          targetX = positions[i*3] + Math.cos(angle) * radius;
          targetZ = positions[i*3+2] + Math.sin(angle) * radius;
        }
      } 
      else if(currentTarget === 'firework') {
        const point = fireworkPoints[i % fireworkPoints.length] || {x:0,y:0,z:0};
        targetX = point.x;
        targetY = point.y;
        targetZ = point.z;
        
        if(easedProgress < 0.3) {
          const burstProgress = easedProgress / 0.3;
          targetX *= burstProgress;
          targetY *= burstProgress;
          targetZ *= burstProgress;
        }
      }
      else {
        const angle = Math.atan2(positions[i*3+2], positions[i*3]);
        const radius = Math.sqrt(positions[i*3]*positions[i*3] + positions[i*3+2]*positions[i*3+2]);
        targetX = Math.cos(angle) * radius;
        targetY = -0.95;
        targetZ = Math.sin(angle) * radius;
      }
      
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