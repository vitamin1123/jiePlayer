<template>
  <div ref="container"></div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount } from 'vue';
import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { CSS3DRenderer, CSS3DObject } from 'three/addons/renderers/CSS3DRenderer.js';

const container = ref(null);
let camera, scene, renderer, controls, css3dRenderer;
let points;
const COLS = 80; // 屏幕列数
const ROWS = 63; // 屏幕行数 (80x63=5040接近5000)
const POINT_COUNT = COLS * ROWS;
const INITIAL_DURATION = 8;  // 初始扩散动画(只播放一次)
const TO_SCREEN_DURATION = 6; // 飞向屏幕
const SCREEN_DURATION = 4;     // 屏幕停留
const TEXT_DURATION = 10;      // 文字动画
const FIREWORK_DURATION = 12;  // 烟花动画
const ROSE_DURATION = 15;      // 玫瑰花动画
const HEART_DURATION = 8;      // 心形动画

// 运动烟花类
class MovingFirework {
  constructor() {
    this.particles = [];
    this.geometry = new THREE.BufferGeometry();
    this.count = 1000; // 粒子数量
    this.positions = new Float32Array(this.count * 3);
    this.velocities = [];
    this.colors = new Float32Array(this.count * 3);
    this.sizes = new Float32Array(this.count);
    this.life = new Float32Array(this.count);

    // 随机起始位置
    const x = (Math.random() * 2 - 1) * 30;
    const y = (Math.random() * 2 - 1) * 25;
    const z = (Math.random() * 2 - 1) * 20;

    for (let i = 0; i < this.count; i++) {
      const phi = Math.random() * Math.PI * 2;
      const theta = Math.random() * Math.PI;
      const velocity = 2 + Math.random() * 2;

      this.velocities.push(
        velocity * Math.sin(theta) * Math.cos(phi),
        velocity * Math.sin(theta) * Math.sin(phi),
        velocity * Math.cos(theta)
      );

      this.positions[i * 3] = x;
      this.positions[i * 3 + 1] = y;
      this.positions[i * 3 + 2] = z;

      // 多彩颜色
      const hue = Math.random();
      const color = new THREE.Color().setHSL(hue, 1.0, 0.7);
      this.colors[i * 3] = color.r;
      this.colors[i * 3 + 1] = color.g;
      this.colors[i * 3 + 2] = color.b;

      this.sizes[i] = 0.5;
      this.life[i] = 1.0;
    }

    this.geometry.setAttribute('position', new THREE.BufferAttribute(this.positions, 3));
    this.geometry.setAttribute('color', new THREE.BufferAttribute(this.colors, 3));
    this.geometry.setAttribute('size', new THREE.BufferAttribute(this.sizes, 1));

    const material = new THREE.PointsMaterial({
      size: 0.5,
      vertexColors: true,
      blending: THREE.AdditiveBlending,
      transparent: true,
      opacity: 0.8,
    });

    this.points = new THREE.Points(this.geometry, material);
    scene.add(this.points);
  }

  update() {
    let alive = false;
    for (let i = 0; i < this.count; i++) {
      if (this.life[i] > 0) {
        alive = true;
        this.positions[i * 3] += this.velocities[i * 3] * 0.1;
        this.positions[i * 3 + 1] += this.velocities[i * 3 + 1] * 0.1;
        this.positions[i * 3 + 2] += this.velocities[i * 3 + 2] * 0.1;

        // 重力效果
        this.velocities[i * 3 + 1] -= 0.05;

        this.life[i] -= 0.01;
        this.sizes[i] = this.life[i] * 0.5;
      }
    }

    this.geometry.attributes.position.needsUpdate = true;
    this.geometry.attributes.size.needsUpdate = true;

    return alive;
  }

  dispose() {
    scene.remove(this.points);
    this.geometry.dispose();
    this.points.material.dispose();
  }
}

// 存储运动烟花实例
const movingFireworks = [];

// 创建心形点阵的函数
const generateHeartPoints = (width, height) => {
  const points = Array.from({ length: height }, () => Array(width).fill(0));
  const centerX = width / 2;
  const centerY = height / 2 - 5;
  
  // 大心形参数
  const bigHeartPoints = [];
  for (let t = 0; t < 2 * Math.PI; t += 0.01) {
    const x = 16 * Math.pow(Math.sin(t), 3);
    const y = 13 * Math.cos(t) - 5 * Math.cos(2*t) - 2 * Math.cos(3*t) - Math.cos(4*t);
    bigHeartPoints.push({x, y});
  }
  
  // 小心形参数
  const smallHeartPoints = [];
  for (let t = 0; t < 2 * Math.PI; t += 0.01) {
    const x = 12 * Math.pow(Math.sin(t), 3);
    const y = 9.75 * Math.cos(t) - 3.75 * Math.cos(2*t) - 1.5 * Math.cos(3*t) - 0.75 * Math.cos(4*t);
    smallHeartPoints.push({x, y});
  }
  
  // 填充大心形
  bigHeartPoints.forEach(point => {
    const px = Math.round(centerX + point.x * 0.9);
    const py = Math.round(centerY - point.y * 0.9);
    if (px >= 0 && px < width && py >= 0 && py < height) {
      points[py][px] = 2;
    }
  });
  
  // 填充小心形
  smallHeartPoints.forEach(point => {
    const px = Math.round(centerX + point.x * 0.9);
    const py = Math.round(centerY - point.y * 0.9);
    if (px >= 0 && px < width && py >= 0 && py < height && points[py][px] === 0) {
      points[py][px] = 1;
    }
  });
  
  return points;
};

// 生成80x63的心形点阵
const heartPoints = generateHeartPoints(COLS, ROWS);

// 创建视频播放器元素
const createVideoElement = () => {
  const videoDiv = document.createElement('div');
  videoDiv.style.width = '500px';
  videoDiv.style.height = '400px';
  videoDiv.style.backgroundColor = '#000';
  videoDiv.style.position = 'absolute';
  videoDiv.style.zIndex = '1000';

  const iframe = document.createElement('iframe');
  iframe.style.width = '100%';
  iframe.style.height = '100%';
  iframe.style.border = '0';
  iframe.src = '//player.bilibili.com/player.html?isOutside=true&aid=886441191&bvid=BV1jK4y1p7Hg&cid=290464814&p=1&autoplay=true';
  //iframe.src = '//player.bilibili.com/player.html?isOutside=true&aid=8795554&bvid=BV1Ux411y7XT&cid=205097595&p=1" scrolling="no" border="0" frameborder="no" framespacing="0" allowfullscreen="true"';
  videoDiv.appendChild(iframe);

  const object = new CSS3DObject(videoDiv);
  object.position.set(0, 0, -30);
  object.scale.set(0.08, 0.08, 0.08);
  
  const group = new THREE.Group();
  group.add(object);
  group.position.set(0, 0, -50);
  
  return group;
};

// 创建屏幕像素点阵
const createScreenPoints = () => {
  const points = [];
  const width = 8;
  const height = width * (ROWS / COLS);
  
  for(let row = 0; row < ROWS; row++) {
    for(let col = 0; col < COLS; col++) {
      const index = row * COLS + col;
      points.push({ 
        x: (col / COLS - 0.5) * width,
        y: (0.5 - row / ROWS) * height,
        z: 0,
        screenX: (col / COLS - 0.5) * width,
        screenY: (0.5 - row / ROWS) * height,
        screenZ: 0
      });
    }
  }
  return points;
};

// 烟花形状定义
const createFireworkShape = () => {
  const points = [];
  const layers = 5;
  for(let l = 0; l < layers; l++) {
    const radius = 0.8 + l * 0.5;
    const count = 100 + l * 50;
    for(let i = 0; i < count; i++) {
      const angle = (i * 2 * Math.PI) / count;
      const variance = 0.15 * Math.random();
      points.push({
        x: radius * Math.cos(angle) + variance,
        y: radius * Math.sin(angle) + variance,
        z: (l - layers/2) * 0.3
      });
    }
  }
  return points;
};

// 创建玫瑰花形状
const createRoseShape = () => {
  const rosePoints = [];
  const m = Math;
  const C = m.cos, S = m.sin, P = m.pow, R = m.random;
  const f = 500, h = -250;
  
  function p(a,b,c) {
    if(c>60) return [S(a*7)*(13+5/(.2+P(b*4,4)))-S(b)*50,b*f+50,625+C(a*7)*(13+5/(.2+P(b*4,4)))+b*400,a*1-b/2,a];
    const A=a*2-1, B=b*2-1;
    if(A*A+B*B<1) {
      if(c>37) {
        const n=(c&1)?6:4, o=.5/(a+.01)+C(b*125)*3-a*300, w=b*h;
        return [o*C(n)+w*S(n)+(c&1)*610-390,o*S(n)-w*C(n)+550-(c&1)*350,1180+C(B+A)*99-(c&1)*300,.4-a*.1+P(1-B*B,-h*6)*.15-a*b*.4+C(a+b)/5+P(C((o*(a+1)+(B>0?w:-w))/25),30)*.1*(1-B*B),o/1e3+.7-o*w*3e-6];
      }
      if(c>32) {
        let c2=c*1.16-.15, o=a*45-20, w=b*b*h;
        const z=o*S(c2)+w*C(c2)+620;
        return [o*C(c2)-w*S(c2),28+C(B*.5)*99-b*b*b*60-z/2-h,z,(b*b*.3+P((1-(A*A)),7)*.15+.3)*b,b*.7];
      }
      const o=A*(2-b)*(80-c*2), w=99-C(A)*120-C(b)*(-h-c*4.9)+C(P(1-b,7))*50+c*2;
      const z=o*S(c)+w*C(c)+700;
      return [o*C(c)-w*S(c),B*99-C(P(b,7))*50-c/3-z/1.35+450,z,(1-b/1.2)*.9+a*.1,P((1-b),20)/4+.05];
    }
    return null;
  }
  
  for(let i=0; i<10000; i++) {
    const s = p(R(), R(), i%46/.74);
    if(s) {
      rosePoints.push({
        x: s[0]/100,
        y: -s[1]/100,
        z: -s[2]/100 - 5,
        r: ~(s[3]*h)/255,
        g: ~(s[4]*h)/255,
        b: ~(s[3]*s[3]*-80)/255
      });
    }
  }
  
  return rosePoints;
};

// 加载汉字图片并离散为点阵
const loadChineseCharacter = async () => {
  return new Promise((resolve) => {
    const img = new Image();
    img.src = './assets/imgs/赵洁.png';
    img.onload = () => {
      const canvas = document.createElement('canvas');
      const ctx = canvas.getContext('2d');
      canvas.width = COLS;
      canvas.height = ROWS;
      ctx.drawImage(img, 0, 0, COLS, ROWS);
      
      const imageData = ctx.getImageData(0, 0, COLS, ROWS);
      const data = imageData.data;
      const points = [];
      
      for(let row = 0; row < ROWS; row++) {
        for(let col = 0; col < COLS; col++) {
          const index = (row * COLS + col) * 4;
          if(data[index + 3] > 128) {
            points.push({ 
              row, 
              col,
              active: true
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
  camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 0.25, 100);
  camera.position.set(0, 0, 15);

  scene = new THREE.Scene();
  // 初始化WebGL渲染器
  renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.setPixelRatio(window.devicePixelRatio);
  renderer.setSize(window.innerWidth, window.innerHeight);
  container.value.appendChild(renderer.domElement);
  // 初始化CSS3D渲染器
  css3dRenderer = new CSS3DRenderer();
  css3dRenderer.setSize(window.innerWidth, window.innerHeight);
  css3dRenderer.domElement.style.position = 'absolute';
  css3dRenderer.domElement.style.top = '0';
  css3dRenderer.domElement.style.pointerEvents = 'none';
  container.value.appendChild(css3dRenderer.domElement);
  // 关键修改：确保CSS3D渲染器在WebGL渲染器之后渲染
  const originalRender = css3dRenderer.render.bind(css3dRenderer);
  css3dRenderer.render = (scene, camera) => {
    renderer.render(scene, camera);
    originalRender(scene, camera);
  };
  // 添加视频播放器
  const videoElement = createVideoElement();
  scene.add(videoElement);

  // 加载全景背景
  const loader = new THREE.CubeTextureLoader().setPath('./assets/city/');
  scene.background = await loader.loadAsync(['px.jpg', 'nx.jpg', 'py.jpg', 'ny.jpg', 'pz.jpg', 'nz.jpg']);

  controls = new OrbitControls(camera, renderer.domElement);
  controls.minDistance = 5;
  controls.maxDistance = 50;

  // 创建环境光
  scene.add(new THREE.AmbientLight(0x404040));

  // 加载汉字点阵、烟花形状和玫瑰花形状
  const chinesePoints = await loadChineseCharacter();
  const fireworkPoints = createFireworkShape();
  const rosePoints = createRoseShape();
  const screenPoints = createScreenPoints();
  
  // 创建点阵系统
  const geometry = new THREE.BufferGeometry();
  const positions = new Float32Array(POINT_COUNT * 3);
  const colors = new Float32Array(POINT_COUNT * 3);
  const sizes = new Float32Array(POINT_COUNT);
  const activePoints = new Array(POINT_COUNT).fill(false);
  const initialYPositions = new Float32Array(POINT_COUNT);

  // 标记汉字对应的活跃点
  chinesePoints.forEach(point => {
    const index = point.row * COLS + point.col;
    if(index < POINT_COUNT) activePoints[index] = true;
  });

  // 初始化位置
  for(let i = 0; i < POINT_COUNT; i++) {
    positions[i*3] = (Math.random() - 0.5) * 20;
    positions[i*3+1] = (Math.random() - 0.5) * 1;
    positions[i*3+2] = (Math.random() - 0.5) * 20;
    
    initialYPositions[i] = positions[i*3+1];
    
    const hue = i / POINT_COUNT;
    const color = new THREE.Color().setHSL(hue, 1.0, 0.7);
    colors[i*3] = color.r;
    colors[i*3+1] = color.g;
    colors[i*3+2] = color.b;
    
    sizes[i] = 0.1;
  }

  geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
  geometry.setAttribute('color', new THREE.BufferAttribute(colors, 3));
  geometry.setAttribute('size', new THREE.BufferAttribute(sizes, 1));

  const material = new THREE.PointsMaterial({
    size: 0.2,
    vertexColors: true,
    sizeAttenuation: true,
    transparent: true,
    opacity: 1.0,
    blending: THREE.AdditiveBlending
  });

  points = new THREE.Points(geometry, material);
  scene.add(points);

  // 动画控制
  let animationStartTime = Date.now();
  let currentStage = 'initial';
  
  // 摄像机动画控制
  let isCameraRotated = false;
  let isCameraPanned = false;
  const cameraRotationDuration = 10; // 旋转动画持续时间(秒)
  const cameraPanDuration = 10;      // 平移动画持续时间(秒)
  const cameraRotationStartTime = Date.now();
  const cameraPanStartTime = Date.now() + cameraRotationDuration * 1000;
  const initialCameraPosition = new THREE.Vector3(0, 0, 15);
  const targetPanPosition = new THREE.Vector3(-10, 3.5, 15); // 向左平移的目标位置
  
  // 缓动函数
  const easeInOutCubic = (t) => {
    return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;
  };
  let nextStage = 'toScreen';
  let initialSpreadComplete = false;
  let transitionStartTime = 0;
  let isTransitioning = false;
  let transitionProgress = 0;
  let transitionDuration = 2.5;
  let currentPositions = [];
  let targetPositions = [];

  // 初始化位置数组
  for(let i = 0; i < POINT_COUNT; i++) {
    currentPositions[i] = {x: positions[i*3], y: positions[i*3+1], z: positions[i*3+2]};
    targetPositions[i] = {x: positions[i*3], y: positions[i*3+1], z: positions[i*3+2]};
  }

  const animate = () => {
    requestAnimationFrame(animate);
    
    const time = Date.now() * 0.001;
    
    // 摄像机旋转动画
    // if (!isCameraRotated) {
    //   const angle = Math.PI / 9; // 20度
    //   const radius = 15;
    //   const elapsed = Date.now() - cameraRotationStartTime;
    //   const progress = Math.min(elapsed / (cameraRotationDuration * 1000), 1);
      
    //   if (progress < 1) {
    //     const easedProgress = easeInOutCubic(progress);
    //     const currentAngle = easedProgress * angle;
    //     camera.position.x = radius * -Math.sin(currentAngle);
    //     camera.position.z = radius * Math.cos(currentAngle);
    //     camera.lookAt(0, 0, 0);
    //   } else {
    //     isCameraRotated = true;
    //   }
    // }
    // 摄像机平移动画
    if (!isCameraPanned ) {
      const elapsed = Date.now() - cameraPanStartTime;
      const progress = Math.min(elapsed / (cameraPanDuration * 1000), 1);
      
      if (progress < 1) {
        const easedProgress = easeInOutCubic(progress);
        camera.position.x = initialCameraPosition.x + (targetPanPosition.x - initialCameraPosition.x) * easedProgress;
        camera.position.z = initialCameraPosition.z + (targetPanPosition.z - initialCameraPosition.z) * easedProgress;
        camera.position.y = initialCameraPosition.y + (targetPanPosition.y - initialCameraPosition.y) * easedProgress;
        camera.lookAt(0, 0, 0);
      } else {
        isCameraPanned = true;
        controls.enabled = true; // 恢复用户控制
      }
    }
    
    const elapsed = Date.now() - animationStartTime;
    let progress = 0;
    let stageDuration = INITIAL_DURATION;
    
    // 设置各阶段参数
    switch(currentStage) {
      case 'initial': stageDuration = INITIAL_DURATION; break;
      case 'toScreen': stageDuration = TO_SCREEN_DURATION; break;
      case 'screen': stageDuration = SCREEN_DURATION; break;
      case 'heart': stageDuration = HEART_DURATION; break;
      case 'text': stageDuration = TEXT_DURATION; break;
      case 'firework': stageDuration = FIREWORK_DURATION; break;
      case 'rose': stageDuration = ROSE_DURATION; break;
    }
    
    progress = Math.min(elapsed / (stageDuration * 1000), 1);
    
    // 更新点属性
    const positions = points.geometry.attributes.position.array;
    const colors = points.geometry.attributes.color.array;

    // 随机生成运动烟花
    if (currentStage === 'firework' && Math.random() < 0.03) {
      movingFireworks.push(new MovingFirework());
    }

    // 更新运动烟花
    for (let i = movingFireworks.length - 1; i >= 0; i--) {
      const alive = movingFireworks[i].update();
      if (!alive) {
        movingFireworks[i].dispose();
        movingFireworks.splice(i, 1);
      }
    }

    // 颜色动画
    for(let i = 0; i < POINT_COUNT; i++) {
      let hue, brightness = 0.7;
      
      if(currentStage === 'rose' || (isTransitioning && nextStage === 'rose')) {
        const point = rosePoints[i % rosePoints.length] || {r:1,g:0,b:1};
        colors[i*3] = point.r;
        colors[i*3+1] = point.g;
        colors[i*3+2] = point.b;
        brightness = 0.9;
      } 
      else if(currentStage === 'heart') {
        const row = Math.floor(i / COLS);
        const col = i % COLS;
        const heartValue = heartPoints[row]?.[col] || 0;
        
        if(heartValue > 0) {
          const pulse = 0.7 + Math.sin(time * 2.5) * 0.3;
          const hueShift = Math.sin(time * 0.5) * 0.05;
          
          if(heartValue === 2) {
            colors[i*3] = 1.0;
            colors[i*3+1] = 0.2 + hueShift;
            colors[i*3+2] = 0.2 + hueShift;
            sizes[i] = 0.35 + Math.sin(time * 3.5) * 0.1;
          } else {
            colors[i*3] = 1.0;
            colors[i*3+1] = 0.4 + hueShift;
            colors[i*3+2] = 0.4 + hueShift;
            sizes[i] = 0.3 + Math.sin(time * 3) * 0.08;
          }
        } else {
          colors[i*3] = 0.1;
          colors[i*3+1] = 0.1;
          colors[i*3+2] = 0.1;
          sizes[i] = 0.05;
        }
      }
      else {
        hue = (i / POINT_COUNT + time * 0.02) % 1;
        if(currentStage === 'screen' || currentStage === 'text') brightness = 0.9;
        
        const pulse = Math.sin(time * 3 + i * 0.001) * 0.1 + 0.9;
        const color = new THREE.Color().setHSL(hue, 1.0, brightness * pulse);
        colors[i*3] = color.r;
        colors[i*3+1] = color.g;
        colors[i*3+2] = color.b;
      }
    }

    // 阶段转换逻辑
    if(progress >= 1 && !isTransitioning) {
      if(elapsed > stageDuration * 1000 + 1000) {
        isTransitioning = true;
        transitionStartTime = Date.now();
        transitionProgress = 0;
        
        for(let i = 0; i < POINT_COUNT; i++) {
          currentPositions[i] = {
            x: positions[i*3],
            y: positions[i*3+1],
            z: positions[i*3+2]
          };
        }
        
        switch(currentStage) {
          case 'initial': 
            nextStage = 'toScreen'; 
            initialSpreadComplete = true;
            break;
          case 'toScreen': nextStage = 'screen'; break;
          case 'screen': nextStage = 'heart'; break;
          case 'heart': nextStage = 'text'; break;
          case 'text': nextStage = 'firework'; break;
          case 'firework': nextStage = 'rose'; break;
          case 'rose': nextStage = 'screen'; break;
        }
        
        for(let i = 0; i < POINT_COUNT; i++) {
          const screenPoint = screenPoints[i];
          const row = Math.floor(i / COLS);
          const col = i % COLS;
          
          if(nextStage === 'initial') {
            targetPositions[i] = {
              x: (Math.random() - 0.5) * 20,
              y: initialYPositions[i] + (Math.random() - 0.5) * 10,
              z: (Math.random() - 0.5) * 20
            };
          }
          else if(nextStage === 'toScreen') {
            targetPositions[i] = {
              x: screenPoint.screenX,
              y: screenPoint.screenY,
              z: screenPoint.screenZ
            };
          }
          else if(nextStage === 'screen' || nextStage === 'heart') {
            targetPositions[i] = {
              x: screenPoint.screenX,
              y: screenPoint.screenY,
              z: screenPoint.screenZ
            };
          }
          else if(nextStage === 'text') {
            if(activePoints[i]) {
              targetPositions[i] = {
                x: screenPoint.screenX,
                y: screenPoint.screenY,
                z: screenPoint.screenZ
              };
            } else {
              targetPositions[i] = {x: 0, y: 0, z: 0};
            }
          }
          else if(nextStage === 'firework') {
            const point = fireworkPoints[i % fireworkPoints.length] || {x:0,y:0,z:0};
            targetPositions[i] = {
              x: point.x,
              y: point.y,
              z: point.z
            };
          }
          else if(nextStage === 'rose') {
            const point = rosePoints[i % rosePoints.length] || {x:0,y:0,z:0};
            targetPositions[i] = {
              x: point.x,
              y: point.y,
              z: point.z
            };
          }
        }
      }
    }

    // 处理过渡动画
    if(isTransitioning) {
      transitionProgress = Math.min((Date.now() - transitionStartTime) / (transitionDuration * 1000), 1);
      
      const easedProgress = easeInOutCubic(transitionProgress);
      
      for(let i = 0; i < POINT_COUNT; i++) {
        positions[i*3] = currentPositions[i].x + (targetPositions[i].x - currentPositions[i].x) * easedProgress;
        positions[i*3+1] = currentPositions[i].y + (targetPositions[i].y - currentPositions[i].y) * easedProgress;
        positions[i*3+2] = currentPositions[i].z + (targetPositions[i].z - currentPositions[i].z) * easedProgress;
        
        if(nextStage === 'text') {
          if(activePoints[i]) {
            sizes[i] = 0.1 + 0.2 * easedProgress;
          } else {
            sizes[i] = 0.1 - 0.05 * easedProgress;
          }
        }
        else if(nextStage === 'firework' || nextStage === 'rose' || nextStage === 'heart') {
          sizes[i] = 0.1 + 0.15 * easedProgress;
        }
      }
      
      if(transitionProgress >= 1) {
        isTransitioning = false;
        currentStage = nextStage;
        animationStartTime = Date.now();
      }
    } 
    else {
      for(let i = 0; i < POINT_COUNT; i++) {
        const screenPoint = screenPoints[i];
        let targetX, targetY, targetZ;
        
        if(currentStage === 'initial') {
          const spreadFactor = Math.sin(time * 0.2 + i * 0.01) * 10 * progress;
          targetX = positions[i*3] + (Math.random() - 0.5) * 0.1;
          targetY = initialYPositions[i] + spreadFactor;
          targetZ = positions[i*3+2] + (Math.random() - 0.5) * 0.1;
        }
        else if(currentStage === 'toScreen') {
          const flyProgress = easeOutCubic(progress);
          targetX = screenPoint.screenX * flyProgress;
          targetY = screenPoint.screenY * flyProgress;
          targetZ = screenPoint.screenZ * flyProgress;
        }
        else if(currentStage === 'screen' || currentStage === 'heart') {
          targetX = screenPoint.screenX;
          targetY = screenPoint.screenY;
          targetZ = screenPoint.screenZ;
        }
        else if(currentStage === 'text') {
          if(activePoints[i]) {
            targetX = screenPoint.screenX;
            targetY = screenPoint.screenY;
            targetZ = screenPoint.screenZ;
            sizes[i] = 0.3;
          } else {
            targetX = targetY = targetZ = 0;
            sizes[i] = 0.05;
          }
        }
        else if(currentStage === 'firework') {
          const point = fireworkPoints[i % fireworkPoints.length] || {x:0,y:0,z:0};
          targetX = point.x;
          targetY = point.y;
          targetZ = point.z;
          sizes[i] = 0.25;
        }
        else if(currentStage === 'rose') {
          const point = rosePoints[i % rosePoints.length] || {x:0,y:0,z:0};
          targetX = point.x;
          targetY = point.y;
          targetZ = point.z;
          sizes[i] = 0.3;
        }
        
        positions[i*3] += (targetX - positions[i*3]) * 0.1;
        positions[i*3+1] += (targetY - positions[i*3+1]) * 0.1;
        positions[i*3+2] += (targetZ - positions[i*3+2]) * 0.1;
      }
    }

    // 动态调整点大小
    if(currentStage === 'text' || currentStage === 'firework' || currentStage === 'rose' || currentStage === 'heart' || 
       (isTransitioning && (nextStage === 'text' || nextStage === 'firework' || nextStage === 'rose' || nextStage === 'heart'))) {
      points.material.size = 0.25 + Math.sin(time * 2) * 0.05;
    } else {
      points.material.size = 0.2;
    }

    points.geometry.attributes.position.needsUpdate = true;
    points.geometry.attributes.color.needsUpdate = true;
    points.geometry.attributes.size.needsUpdate = true;
    
    // 渲染两种内容
    renderer.render(scene, camera);
    css3dRenderer.render(scene, camera);
  };

  // 缓动函数
  function easeOutCubic(t) {
    return 1 - Math.pow(1 - t, 3);
  }
  
  // function easeInOutCubic(t) {
  //   return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;
  // }

  animate();
  window.addEventListener('resize', onWindowResize);
});

function onWindowResize() {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
  css3dRenderer.setSize(window.innerWidth, window.innerHeight);
}

onBeforeUnmount(() => {
  if (controls) controls.dispose();
  if (renderer) renderer.dispose();
  if (css3dRenderer) {
    container.value.removeChild(css3dRenderer.domElement);
  }
  window.removeEventListener('resize', onWindowResize);
});
</script>

<style>
body {
  margin: 0;
  overflow: hidden;
  background: #000;
}

#container {
  position: relative;
}
</style>