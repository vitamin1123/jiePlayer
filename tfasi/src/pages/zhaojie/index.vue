<template>
    <div></div>
  </template>
  
  <script setup>
  import * as THREE from 'three';
  
  // 场景、相机、渲染器
  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(90, window.innerWidth / window.innerHeight, 0.1, 1000);
  camera.position.z = 6;
  
  const renderer = new THREE.WebGLRenderer({
    antialias: true,
  });
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.outputColorSpace = THREE.SRGBColorSpace;  // 新版本 Three.js 的设置
//   renderer.gammaFactor = 1.0;  // 禁用 Gamma 校正
  document.body.appendChild(renderer.domElement);
  
  // 加载纹理
  const textureLoader = new THREE.TextureLoader();
  const texture = textureLoader.load('/assets/zhaojie.png');
  const depthTexture = textureLoader.load('/assets/zhaojie1.png');
  texture.colorSpace = THREE.SRGBColorSpace;  // 新版本 Three.js 的设置
  
  // 创建平面
  const geometry = new THREE.PlaneGeometry(6.8, 10.24); 

//   const material = new THREE.MeshBasicMaterial({
//     map: texture,
//     color: 0xFFFFFF,
//     transparent: true,  // 启用透明度
//     opacity: 1      // 调整亮度
//   });
const mouse = new THREE.Vector2();
const material = new THREE.ShaderMaterial({
    uniforms: {
        uTexture: { value: texture },
        uDepthTexture: { value: depthTexture },
        uMouse: { value: mouse },
        
    },
    vertexShader: `
        varying vec2 vUv;
        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
    `,
    fragmentShader: `
        uniform sampler2D uTexture;
        uniform sampler2D uDepthTexture;
        uniform vec2 uMouse;
        varying vec2 vUv;
        void main() {
            vec4 color = texture2D(uTexture, vUv);
            
            vec4 depth = texture2D(uDepthTexture, vUv);
            float depthValue = depth.r;
            float x = vUv.x + uMouse.x * 0.03 * depthValue;
            float y = vUv.y + uMouse.y * 0.03 * depthValue;
            vec4 newColor = texture2D(uTexture, vec2(x, y));
            newColor.rgb = pow(newColor.rgb, vec3(1.0/2.2));
            gl_FragColor = newColor; 
        }
    `,
})
  const plane = new THREE.Mesh(geometry, material);
  scene.add(plane);
  
  // 动画循环
  requestAnimationFrame(function animate() {
    material.uniforms.uMouse.value = mouse
    requestAnimationFrame(animate);
    renderer.render(scene, camera);
  });

  window.addEventListener('mousemove', (event) => {
    mouse.x = (event.clientX / window.innerWidth) * 2 - 1;
    mouse.y = -(event.clientY / window.innerHeight) * 2 + 1;
  });
  </script>
  
  <style>
  * {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
  }
  
  canvas {
    width: 100vw;
    height: 100vh;
    display: block;
    position: fixed;
    top: 0;
    left: 0;
  }
  </style>