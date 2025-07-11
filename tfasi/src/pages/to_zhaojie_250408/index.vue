<template>
  <div ref="container" class="three-container">
    <!-- <div class="controls">
      <button @click="startWave('center')">中心波浪</button>
      <button @click="startWave('diagonal')">对角线波浪</button>
      <button @click="startWave('peripheryToCenter')">外围到中心</button>
      <button @click="startWave('random')">随机波动</button>
      <button @click="resetBlocks">重置</button>
    </div> -->
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount } from 'vue';
import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';

const hzk16Loaded = ref(false);
let hzk16Buffer = null;

const container = ref(null);

// 配置
const config = {
  rows: 23,
  cols: 39,
  spacing: 1.01,
  blockWidth: 1,
  blockDepth: 1,
  blockHeight: 5,
  animationSpeed: 0.03,
  colors: {
    base: 0xffdfd4,
    highlight: 0xded2d2,
    character: 0xfaabb7
  },
  transitions: {
    duration: 2000,
    easing: t => t < 0.5 ? 2 * t * t : 1 - Math.pow(-2 * t + 2, 2) / 2
  },
  characters: ['赵', '洁','大','宝',  '开', '心','每','一','天'],
  characterDisplayTime: 18000,
  characterSize: 16,
  animationDuration: 18000, // 每个动画的持续时间
  amplitudeChangeDuration: 18000, // 振幅渐强渐弱的持续时间
  characterTransitionDuration: 1000 // 汉字切换的过渡时间
};

async function loadHZK16() {
  try {
    const response = await fetch('/assets/hzk16s');
    const arrayBuffer = await response.arrayBuffer();
    hzk16Buffer = new Uint8Array(arrayBuffer);
    hzk16Loaded.value = true;
    console.log('HZK16字库加载成功');
  } catch (error) {
    console.error('加载HZK16字库失败:', error);
  }
}

const ranges = [
  [0xA1, 0xA9,  0xA1, 0xFE],
  [0xB0, 0xF7,  0xA1, 0xFE],
  [0x81, 0xA0,  0x40, 0xFE],
  [0xAA, 0xFE,  0x40, 0xA0],
  [0xA8, 0xA9,  0x40, 0xA0],
  [0xAA, 0xAF,  0xA1, 0xFE],
  [0xF8, 0xFE,  0xA1, 0xFE],
  [0xA1, 0xA7,  0x40, 0xA0],
];
const codes = new Uint16Array(23940);
let i = 0;
for (const [b1Begin, b1End, b2Begin, b2End] of ranges) {
  for (let b2 = b2Begin; b2 <= b2End; b2++) {
    if (b2 !== 0x7F) {
      for (let b1 = b1Begin; b1 <= b1End; b1++) {
        codes[i++] = b2 << 8 | b1;
      }
    }
  }
}
const str = new TextDecoder('gbk').decode(codes);
const table = new Uint16Array(65536);
for (let i = 0; i < str.length; i++) {
  table[str.charCodeAt(i)] = codes[i];
}

function stringToGbk(str) {
  const buf = new Uint8Array(str.length * 2);
  let n = 0;
  for (let i = 0; i < str.length; i++) {
    const code = str.charCodeAt(i);
    if (code < 0x80) {
      buf[n++] = code;
    } else {
      const gbk = table[code];
      buf[n++] = gbk & 0xFF;
      buf[n++] = gbk >> 8;
    }
  }
  return buf.subarray(0, n);
}

function hzkOffset(hz) {
  const buffer1 = stringToGbk(hz);
  const q = buffer1[0];
  const w = buffer1[1];
  return ((q - 161) * 94 + w - 161) * 32;
}

function getHZK16Character(char) {
  if (!hzk16Buffer) return new Array(32).fill(0);
  const offset = hzkOffset(char);
  return hzk16Buffer.slice(offset, offset + 32);
}

function getCharacterMatrix(char) {
  const buffer = getHZK16Character(char);
  const matrix = [];
  for (let i = 0; i < 16; i++) {
    matrix[i] = [];
    for (let j = 0; j < 2; j++) {
      const byte = buffer[i * 2 + j];
      for (let k = 0; k < 8; k++) {
        matrix[i][j * 8 + k] = (byte & (0x80 >> k)) !== 0;
      }
    }
  }
  return matrix;
}

let scene, camera, renderer, controls, blocks = [];
let currentAnimation = null;
let transitionStart = 0;
let isTransitioning = false;
let nextAnimationType = null;
let currentCharIndex = 0;
let characterMatrix = [];
let characterStartTime = 0;
let characterPhase = 0;
let characterBlocks = [];
let animationStartTime = 0;
let amplitudeStartTime = 0;
let amplitude = 0;
const animationTypes = ['center', 'diagonal', 'peripheryToCenter', 'random', 'spiral'];
let currentAnimationIndex = 0;
let isCharacterTransitioning = false;
let characterTransitionStart = 0;
let prevCharacterBlocks = [];

function init() {
  scene = new THREE.Scene();
  scene.background = new THREE.Color(0xf0f0f0);

  camera = new THREE.PerspectiveCamera(
    60,
    container.value.clientWidth / container.value.clientHeight, 
    0.1, 
    1000
  );
  camera.position.set(0, 20, 20);

  renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.setSize(container.value.clientWidth, container.value.clientHeight);
  renderer.shadowMap.enabled = true;
  container.value.appendChild(renderer.domElement);

  controls = new OrbitControls(camera, renderer.domElement);
  controls.enableDamping = true;
  controls.minDistance = 10;
  controls.maxDistance = 60;

  const ambientLight = new THREE.AmbientLight(0xffffff, 0.5);
  scene.add(ambientLight);

  const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
  directionalLight.position.set(15, 40, 30);
  directionalLight.castShadow = true;
  scene.add(directionalLight);

  createBlocks();
  updateCurrentCharacter();
  currentAnimation = animationTypes[currentAnimationIndex];
  animationStartTime = Date.now();
  amplitudeStartTime = Date.now();
  animate();
}

function createBlocks() {
  const geometry = new THREE.BoxGeometry(
    config.blockWidth, 
    config.blockHeight,
    config.blockDepth
  );
  
  const totalRows = config.rows;
  const totalCols = config.cols;
  const startX = -((totalCols - 1) * config.spacing) / 2;
  const startZ = -((totalRows - 1) * config.spacing) / 2;
  
  for (let row = 0; row < totalRows; row++) {
    for (let col = 0; col < totalCols; col++) {
      const material = new THREE.MeshPhongMaterial({ 
        color: config.colors.base,
        shininess: 40,
        specular: 0x111111
      });
      
      const block = new THREE.Mesh(geometry, material);
      block.position.x = startX + col * config.spacing;
      block.position.z = startZ + row * config.spacing;
      block.position.y = config.blockHeight / 2;
      
      block.userData = {
        originalY: config.blockHeight / 2,
        targetY: config.blockHeight / 2,
        row,
        col,
        baseColor: config.colors.base,
        isCharacterBlock: false,
        isNewCharacterBlock: false
      };
      
      block.castShadow = true;
      block.receiveShadow = true;
      
      scene.add(block);
      blocks.push(block);
    }
  }
}

function updateCurrentCharacter() {
  // 保存之前的字符方块
  prevCharacterBlocks = [...characterBlocks];
  
  // 重置之前的字符方块状态
  prevCharacterBlocks.forEach(index => {
    blocks[index].userData.isCharacterBlock = false;
    blocks[index].userData.isNewCharacterBlock = false;
  });
  
  characterBlocks = [];
  
  characterMatrix = getCharacterMatrix(config.characters[currentCharIndex]);
  characterStartTime = Date.now();
  characterPhase = 0;
  
  const charSize = config.characterSize;
  const totalRows = config.rows;
  const totalCols = config.cols;
  const startRow = Math.floor((totalRows - charSize) / 2);
  const startCol = Math.floor((totalCols - charSize) / 2);
  
  for (let i = 0; i < charSize; i++) {
    for (let j = 0; j < charSize; j++) {
      if (characterMatrix[i] && characterMatrix[i][j]) {
        const row = startRow + i;
        const col = startCol + j;
        
        if (row >= 0 && row < totalRows && col >= 0 && col < totalCols) {
          const index = row * totalCols + col;
          blocks[index].userData.isCharacterBlock = true;
          blocks[index].userData.isNewCharacterBlock = true;
          blocks[index].material.color.setHex(config.colors.base); // 初始设置为base颜色
          characterBlocks.push(index);
        }
      }
    }
  }
  
  // 开始字符过渡动画
  isCharacterTransitioning = true;
  characterTransitionStart = Date.now();
  
  console.log(`显示汉字: ${config.characters[currentCharIndex]}, 方块数量: ${characterBlocks.length}`);
}

function animate() {
  requestAnimationFrame(animate);
  
  const now = Date.now();
  
  // 处理字符过渡动画
  if (isCharacterTransitioning) {
    const elapsed = now - characterTransitionStart;
    const progress = Math.min(elapsed / config.characterTransitionDuration, 1);
    
    // 之前的字符方块逐渐下降并变回基础颜色
    prevCharacterBlocks.forEach(index => {
      if (progress < 1) {
        blocks[index].userData.targetY = config.blockHeight / 2;
        blocks[index].material.color.setHex(config.colors.base);
      }
    });
    
    // 新的字符方块在过渡完成后开始上升并变为字符颜色
    if (progress >= 1) {
      isCharacterTransitioning = false;
      characterBlocks.forEach(index => {
        blocks[index].material.color.setHex(config.colors.character);
      });
    }
  }
  
  if (!isCharacterTransitioning && now - characterStartTime > config.characterDisplayTime) {
    currentCharIndex = (currentCharIndex + 1) % config.characters.length;
    updateCurrentCharacter();
  }
  
  if (now - animationStartTime > config.animationDuration) {
    currentAnimationIndex = (currentAnimationIndex + 1) % animationTypes.length;
    currentAnimation = animationTypes[currentAnimationIndex];
    animationStartTime = now;
    amplitudeStartTime = now;
    amplitude = 0;
  }
  
  // 计算振幅
  const amplitudeElapsed = now - amplitudeStartTime;
  if (amplitudeElapsed < config.amplitudeChangeDuration / 2) {
    amplitude = amplitudeElapsed / (config.amplitudeChangeDuration / 2);
  } else if (amplitudeElapsed < config.amplitudeChangeDuration) {
    amplitude = 1 - (amplitudeElapsed - config.amplitudeChangeDuration / 2) / (config.amplitudeChangeDuration / 2);
  } else {
    amplitude = 0;
  }
  
  if (isTransitioning) {
    const elapsed = now - transitionStart;
    const progress = Math.min(elapsed / config.transitions.duration, 1);
    const easedProgress = config.transitions.easing(progress);
    
    if (progress >= 1) {
      isTransitioning = false;
      if (nextAnimationType) {
        currentAnimation = nextAnimationType;
        nextAnimationType = null;
      }
    }
  }
  
  blocks.forEach((block, index) => {
    if (block.userData.isCharacterBlock && !isCharacterTransitioning && characterPhase === 1) {
      block.userData.targetY = config.blockHeight * 1.5;
    }
    
    block.position.y += (block.userData.targetY - block.position.y) * config.animationSpeed;
    
    if (block.userData.isCharacterBlock && !block.userData.isNewCharacterBlock) {
      block.material.color.setHex(config.colors.character);
    } else if (!block.userData.isCharacterBlock) {
      if (block.material.color.getHex() !== block.userData.targetColor) {
        const currentColor = new THREE.Color(block.material.color.getHex());
        const targetColor = new THREE.Color(block.userData.targetColor || block.userData.baseColor);
        block.material.color.lerp(targetColor, 0.1);
      }
    }
  });
  
  if (currentAnimation === 'center') {
    centerWaveAnimation();
  } else if (currentAnimation === 'diagonal') {
    diagonalWaveAnimation();
  } else if (currentAnimation === 'peripheryToCenter') {
    peripheryToCenterAnimation();
  } else if (currentAnimation === 'random') {
    randomWaveAnimation();
  } else if (currentAnimation === 'spiral') {
    spiralWaveAnimation();
  }
  
  controls.update();
  renderer.render(scene, camera);
}

function centerWaveAnimation() {
  const centerRow = config.rows / 2 - 0.5;
  const centerCol = config.cols / 2 - 0.5;
  const time = Date.now() * 0.002;
  
  blocks.forEach(block => {
    const dx = block.userData.col - centerCol;
    const dz = block.userData.row - centerRow;
    const distance = Math.sqrt(dx * dx + dz * dz);
    const wave = Math.sin(distance * 0.3 - time) * 1.5 * amplitude;
    const waveHeight = wave + (config.blockHeight / 2);
    
    if (block.userData.isCharacterBlock && !isCharacterTransitioning) {
      const wavePos = distance * 0.3 - time;
      const wavePhase = (wavePos / (Math.PI * 2)) % 1;
      
      if (characterPhase === 0 && wavePhase > 0.2 && wavePhase < 0.3) {
        characterPhase = 1;
      } else if (characterPhase === 1 && wavePhase > 0.7 && wavePhase < 0.8) {
        characterPhase = 2;
      }
      
      // 取波峰高度和当前目标高度的最大值
      block.userData.targetY = Math.max(block.userData.targetY, waveHeight);
    } else if (!block.userData.isCharacterBlock) {
      block.userData.targetY = waveHeight;
      
      const colorFactor = (wave + 1.5 * amplitude) / (3 * amplitude);
      block.userData.targetColor = new THREE.Color().lerpColors(
        new THREE.Color(config.colors.base),
        new THREE.Color(config.colors.highlight),
        colorFactor
      ).getHex();
    }
  });
}

function diagonalWaveAnimation() {
  const time = Date.now() * 0.002;
  
  blocks.forEach(block => {
    const diagonalPos = (block.userData.col / config.cols) + (block.userData.row / config.rows);
    const wave = Math.sin(diagonalPos * 8 - time) * 1.5 * amplitude;
    const waveHeight = wave + (config.blockHeight / 2);
    
    if (block.userData.isCharacterBlock && !isCharacterTransitioning) {
      const wavePos = diagonalPos * 8 - time;
      const wavePhase = (wavePos / (Math.PI * 2)) % 1;
      
      if (characterPhase === 0 && wavePhase > 0.2 && wavePhase < 0.3) {
        characterPhase = 1;
      }
      
      // 取波峰高度和当前目标高度的最大值
      block.userData.targetY = Math.max(block.userData.targetY, waveHeight);
    } else if (!block.userData.isCharacterBlock) {
      block.userData.targetY = waveHeight;
      
      const colorFactor = (wave + 1.5 * amplitude) / (3 * amplitude);
      block.userData.targetColor = new THREE.Color().lerpColors(
        new THREE.Color(config.colors.base),
        new THREE.Color(config.colors.highlight),
        colorFactor
      ).getHex();
    }
  });
}

function peripheryToCenterAnimation() {
  const totalRows = config.rows; // 23
  const totalCols = config.cols; // 39
  const maxLayer = Math.floor(Math.min(totalRows, totalCols) / 2); // 11层
  const time = Date.now() - animationStartTime;
  
  // 分配时间：上升50%，停留10%，下降40%
  const riseDuration = config.animationDuration * 0.5;
  const holdDuration = config.animationDuration * 0.1;
  const fallDuration = config.animationDuration * 0.4;
  
  const layerRiseDuration = riseDuration / (maxLayer + 1);
  const layerFallDuration = fallDuration / (maxLayer + 1);

  blocks.forEach(block => {
    const row = block.userData.row;
    const col = block.userData.col;
    const layer = Math.min(row, totalRows - row - 1, col, totalCols - col - 1);

    let targetHeight = config.blockHeight / 2;
    
    // 上升阶段
    if (time < riseDuration) {
      const currentLayer = Math.floor(time / layerRiseDuration);
      const layerProgress = Math.min(1, (time % layerRiseDuration) / layerRiseDuration);
      
      if (layer < currentLayer) {
        targetHeight = config.blockHeight / 2 + 2 * amplitude;
      } else if (layer === currentLayer) {
        targetHeight = config.blockHeight / 2 + layerProgress * 2 * amplitude;
      }
    } 
    // 停留阶段
    else if (time < riseDuration + holdDuration) {
      targetHeight = config.blockHeight / 2 + 2 * amplitude;
    }
    // 下降阶段
    else if (time < riseDuration + holdDuration + fallDuration) {
      const fallTime = time - riseDuration - holdDuration;
      const currentLayer = Math.floor(fallTime / layerFallDuration);
      const layerProgress = Math.min(1, (fallTime % layerFallDuration) / layerFallDuration);
      
      if (layer < (maxLayer - currentLayer)) {
        targetHeight = config.blockHeight / 2;
      } else if (layer === (maxLayer - currentLayer)) {
        targetHeight = config.blockHeight / 2 + (1 - layerProgress) * 2 * amplitude;
      } else {
        targetHeight = config.blockHeight / 2 + 2 * amplitude;
      }
    }
    // 循环结束
    else {
      targetHeight = config.blockHeight / 2;
    }

    if (block.userData.isCharacterBlock && !isCharacterTransitioning) {
      // 取波峰高度和当前目标高度的最大值
      block.userData.targetY = Math.max(block.userData.targetY, targetHeight);
    } else if (!block.userData.isCharacterBlock) {
      block.userData.targetY = targetHeight;
      
      const colorFactor = (targetHeight - config.blockHeight / 2) / (2 * amplitude);
      block.userData.targetColor = new THREE.Color().lerpColors(
        new THREE.Color(config.colors.base),
        new THREE.Color(config.colors.highlight),
        colorFactor
      ).getHex();
    }
  });
}

function randomWaveAnimation() {
  const time = Date.now() * 0.002;
  
  blocks.forEach(block => {
    const randomOffset = Math.random() * Math.PI * 2;
    const wave = Math.sin(time + randomOffset) * 1.5 * amplitude;
    const waveHeight = wave + (config.blockHeight / 2);
    
    if (block.userData.isCharacterBlock && !isCharacterTransitioning) {
      // 取波峰高度和当前目标高度的最大值
      block.userData.targetY = Math.max(block.userData.targetY, waveHeight);
    } else if (!block.userData.isCharacterBlock) {
      block.userData.targetY = waveHeight;
      
      const colorFactor = (wave + 1.5 * amplitude) / (3 * amplitude);
      block.userData.targetColor = new THREE.Color().lerpColors(
        new THREE.Color(config.colors.base),
        new THREE.Color(config.colors.highlight),
        colorFactor
      ).getHex();
    }
  });
}

function spiralWaveAnimation() {
  const totalRows = config.rows;
  const totalCols = config.cols;
  const time = Date.now() - animationStartTime;
  const blockCount = totalRows * totalCols;
  const durationPerBlock = config.animationDuration / blockCount;
  
  // 螺旋顺序预计算
  if (!blocks[0].userData.spiralOrder) {
    calculateSpiralOrder();
  }

  blocks.forEach((block, index) => {
    const spiralIndex = block.userData.spiralOrder;
    const blockStartTime = spiralIndex * durationPerBlock;
    const blockEndTime = blockStartTime + durationPerBlock * 0.8; // 留20%时间保持高位
    
    let targetHeight = config.blockHeight / 2;
    
    if (time >= blockStartTime) {
      if (time < blockEndTime) {
        // 上升阶段
        const progress = (time - blockStartTime) / (blockEndTime - blockStartTime);
        targetHeight = config.blockHeight / 2 + progress * 2 * amplitude;
      } else {
        // 保持高位
        targetHeight = config.blockHeight / 2 + 2 * amplitude;
      }
    }

    if (block.userData.isCharacterBlock && !isCharacterTransitioning) {
      // 取波峰高度和当前目标高度的最大值
      block.userData.targetY = Math.max(block.userData.targetY, targetHeight);
    } else if (!block.userData.isCharacterBlock) {
      block.userData.targetY = targetHeight;
      
      const colorFactor = (targetHeight - config.blockHeight / 2) / (2 * amplitude);
      block.userData.targetColor = new THREE.Color().lerpColors(
        new THREE.Color(config.colors.base),
        new THREE.Color(config.colors.highlight),
        colorFactor
      ).getHex();
    }
  });
}

// 预计算螺旋顺序
function calculateSpiralOrder() {
  const totalRows = config.rows;
  const totalCols = config.cols;
  const visited = Array(totalRows).fill().map(() => Array(totalCols).fill(false));
  const directions = [[0, 1], [1, 0], [0, -1], [-1, 0]]; // 右、下、左、上
  let currentDir = 0;
  let row = 0;
  let col = totalCols - 1; // 从右上角开始
  let order = 0;
  
  while (true) {
    visited[row][col] = true;
    const blockIndex = row * totalCols + col;
    blocks[blockIndex].userData.spiralOrder = order++;
    
    // 尝试继续当前方向
    let nextRow = row + directions[currentDir][0];
    let nextCol = col + directions[currentDir][1];
    
    // 如果无法继续当前方向，则改变方向
    if (nextRow < 0 || nextRow >= totalRows || 
        nextCol < 0 || nextCol >= totalCols || 
        visited[nextRow][nextCol]) {
      currentDir = (currentDir + 1) % 4;
      nextRow = row + directions[currentDir][0];
      nextCol = col + directions[currentDir][1];
      
      // 如果改变方向后仍然无法前进，则结束
      if (nextRow < 0 || nextRow >= totalRows || 
          nextCol < 0 || nextCol >= totalCols || 
          visited[nextRow][nextCol]) {
        break;
      }
    }
    
    row = nextRow;
    col = nextCol;
  }
}

function startWave(type) {
  if (isTransitioning) return;
  nextAnimationType = type;
  isTransitioning = true;
  transitionStart = Date.now();
}

function resetBlocks() {
  blocks.forEach(block => {
    block.userData.targetY = config.blockHeight / 2;
    block.userData.targetColor = block.userData.baseColor;
    block.material.color.setHex(block.userData.baseColor);
  });
}

onMounted(() => {
  loadHZK16().then(() => {
    init();
  });
});

onBeforeUnmount(() => {
  renderer.dispose();
  controls.dispose();
});
</script>

<style scoped>
.three-container {
  width: 100%;
  height: 100vh;
  position: relative;
}

.controls {
  position: absolute;
  top: 10px;
  left: 10px;
  z-index: 10;
}

.controls button {
  margin-right: 10px;
}
</style>