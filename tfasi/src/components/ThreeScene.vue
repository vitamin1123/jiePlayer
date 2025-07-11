<template>
    <div ref="container" class="three-container"></div>
  </template>
  
  <script setup lang="ts">
  import * as THREE from 'three';
  import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls';
  import { onMounted, onUnmounted, ref } from 'vue';
  
  // 定义 ref
  const container = ref<HTMLElement | null>(null);
  
  let camera: THREE.PerspectiveCamera;
  let scene: THREE.Scene;
  let renderer: THREE.WebGLRenderer;
  let controls: OrbitControls;
  let mesh: THREE.Mesh[] = [];
  const AMOUNT = 1;
  const array16x16: number[][] = Array.from({ length: 16 }, () => Array(16).fill(0));
  
  // WebSocket
  //const ws = new WebSocket("ws://127.0.0.1:8010/ws/3");
  
  // 初始化场景
  function init() {
    const ASPECT_RATIO = window.innerWidth / window.innerHeight;
    const WIDTH = (window.innerWidth / AMOUNT) * window.devicePixelRatio;
    const HEIGHT = (window.innerHeight / AMOUNT) * window.devicePixelRatio;
  
    camera = new THREE.PerspectiveCamera(40, ASPECT_RATIO, 0.1, 10);
    camera.viewport = new THREE.Vector4(Math.floor(0), Math.floor(0), Math.ceil(WIDTH), Math.ceil(HEIGHT));
    camera.position.set(-0.5, -0.5, 2.5).multiplyScalar(2);
    camera.lookAt(0, 0, 0);
    camera.updateMatrixWorld();
  
    scene = new THREE.Scene();
    scene.add(new THREE.AmbientLight(0x999999));
  
    const light = new THREE.DirectionalLight(0xffffff, 3);
    light.position.set(2, 2, 3);
    light.castShadow = true;
    light.shadow.camera.zoom = 4;
    scene.add(light);
  
    const geometryBackground = new THREE.PlaneGeometry(100, 100);
    const materialBackground = new THREE.MeshPhongMaterial({ color: 0x000066 });
    const background = new THREE.Mesh(geometryBackground, materialBackground);
    background.receiveShadow = true;
    background.position.set(0, 0, -1);
    scene.add(background);
  
    for (let i = -8; i < 8; i++) {
      for (let j = 7; j >= -8; j--) {
        const geometryCylinder = new THREE.BoxGeometry(0.1, 0.1, 0.1);
        const materialCylinder = new THREE.MeshPhongMaterial({ color: 0xffdfd4 });
        const mesh_tp = new THREE.Mesh(geometryCylinder, materialCylinder);
        mesh_tp.castShadow = true;
        mesh_tp.receiveShadow = true;
        mesh_tp.position.set(i / 10, j / 10, 1);
        scene.add(mesh_tp);
        mesh.push(mesh_tp);
      }
    }
  
    renderer = new THREE.WebGLRenderer();
    renderer.setPixelRatio(window.devicePixelRatio);
    renderer.setSize(window.innerWidth, window.innerHeight);
    renderer.shadowMap.enabled = true;
    controls = new OrbitControls(camera, renderer.domElement);
    controls.update();
  
    if (container.value) {
      container.value.appendChild(renderer.domElement);
    }
  
    window.addEventListener('resize', onWindowResize);
  }
  
  // 窗口大小调整
  function onWindowResize() {
    const ASPECT_RATIO = window.innerWidth / window.innerHeight;
    const WIDTH = (window.innerWidth / AMOUNT) * window.devicePixelRatio;
    const HEIGHT = (window.innerHeight / AMOUNT) * window.devicePixelRatio;
  
    camera.aspect = ASPECT_RATIO;
    camera.updateProjectionMatrix();
    camera.viewport.set(Math.floor(WIDTH), Math.floor(HEIGHT), Math.ceil(WIDTH), Math.ceil(HEIGHT));
    renderer.setSize(window.innerWidth, window.innerHeight);
  }
  
  // 动画循环
  function animate() {
    requestAnimationFrame(animate);
    controls.update();
    renderer.render(scene, camera);
  }
  
  // WebSocket 消息处理
//   ws.onmessage = function (event) {
//     const ed_json = JSON.parse(event.data);
//     if ("pos_data" in ed_json) {
//       camera.position.set(ed_json["pos_data"]["pos_x"], ed_json["pos_data"]["pos_y"], ed_json["pos_data"]["pos_z"]);
//     }
//     if ("tar_data" in ed_json) {
//       controls.target.set(ed_json["tar_data"]["tar_x"], ed_json["tar_data"]["tar_y"], ed_json["tar_data"]["tar_z"]);
//     }
//   };
  
  // 组件挂载时初始化
  onMounted(() => {
    init();
    animate();
  });
  
  // 组件卸载时清理
  onUnmounted(() => {
    window.removeEventListener('resize', onWindowResize);
    if (container.value && renderer) {
      container.value.removeChild(renderer.domElement);
    }
  });
  </script>
  
  <style scoped>
  .three-container {
    width: 100%;
    height: 100vh;
  }
  </style>