<template>
    <v-container class="d-flex justify-center align-center" style="background-color: black; height: 100vh;">
      <v-card class="text-white" style="padding: 20px;">
        <v-card-title class="text-h2">{{ currentTime }}</v-card-title>
      </v-card>
    </v-container>
  </template>
  
  <script setup lang="ts">
  import { ref, onMounted, onUnmounted } from 'vue';
  
  // 用于存储当前时间的响应式变量
  const currentTime = ref('');
  // 修改 timer 的类型
  let timer: ReturnType<typeof setInterval>;
  
  // 初始化时钟的函数
  const initClock = () => {
    const now = new Date();
    currentTime.value = now.toLocaleTimeString();
  };
  
  // 启动时钟的函数
  const startClock = () => {
    // 每秒更新一次时钟
    timer = setInterval(() => {
      initClock();
    }, 1000);
  };
  
  // 停止时钟的函数
  const stopClock = () => {
    clearInterval(timer);
  };
  
  onMounted(() => {
    // 组件挂载时初始化时钟并启动
    initClock();
    startClock();
  });
  
  onUnmounted(() => {
    // 组件卸载时停止时钟
    stopClock();
  });
  </script>
  
  <style scoped>
  /* 可以在这里添加额外的样式 */
  </style>