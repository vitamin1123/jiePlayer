<template>
    <v-app>
      <v-container>
        <!-- 返回按钮 -->
        <v-btn 
          icon="mdi-arrow-left" 
          class="mb-4"
          @click="$router.go(-1)"
        ></v-btn>
  
        <!-- 主内容区域 -->
        <v-card class="rounded-lg elevation-2">
          <!-- 封面和基本信息 -->
          <v-row class="ma-0">
            <!-- 左侧封面图 -->
            <v-col cols="12" md="4">
              <v-img
                :src="detailData.vod_pic"
                aspect-ratio="2/3"
                class="rounded-lg"
              >
                <template #placeholder>
                  <v-skeleton-loader type="image" />
                </template>
              </v-img>
            </v-col>
  
            <!-- 右侧信息 -->
            <v-col cols="12" md="8">
              <v-card-title class="text-h6 font-weight-bold">
                {{ detailData.vod_name }}
                <v-chip class="ml-2" color="primary">
                  {{ detailData.vod_score }} 分
                </v-chip>
              </v-card-title>
  
              <v-card-text>
                <v-list density="compact" class="transparent">
                  <v-list-item>
                    <template #prepend>
                      <v-icon icon="mdi-filmstrip"></v-icon>
                    </template>
                    <v-list-item-title>
                      {{ detailData.type_name }}  {{ detailData.vod_class }}
                    </v-list-item-title>
                  </v-list-item>
  
                  <v-divider class="my-2"></v-divider>
  
                  <v-list-item>
                    <template #prepend>
                      <v-icon icon="mdi-clock-outline"></v-icon>
                    </template>
                    <v-list-item-title>
                      时长：{{ detailData.vod_duration }}分钟
                    </v-list-item-title>
                  </v-list-item>
  
                  <v-list-item>
                    <template #prepend>
                      <v-icon icon="mdi-calendar"></v-icon>
                    </template>
                    <v-list-item-title>
                      年份：{{ detailData.vod_year }}
                    </v-list-item-title>
                  </v-list-item>
  
                  <v-list-item>
                    <template #prepend>
                      <v-icon icon="mdi-earth"></v-icon>
                    </template>
                    <v-list-item-title>
                      地区：{{ detailData.vod_area }}（{{ detailData.vod_lang }}）
                    </v-list-item-title>
                  </v-list-item>
  
                  <v-list-item>
                    <template #prepend>
                      <v-icon icon="mdi-account-group"></v-icon>
                    </template>
                    <v-list-item-title>
                      演员：{{ detailData.vod_actor || '未知' }}
                    </v-list-item-title>
                  </v-list-item>
  
                  <v-list-item>
                    <template #prepend>
                      <v-icon icon="mdi-note-text"></v-icon>
                    </template>
                    <v-list-item-title>
                      备注：{{ detailData.vod_remarks }}
                    </v-list-item-title>
                  </v-list-item>
                </v-list>
              </v-card-text>
            </v-col>
          </v-row>
  
          <!-- 简介 -->
          <v-card-text class="bg-grey-lighten-4">
            <div class="text-subtitle-1 font-weight-bold mb-2">剧情简介</div>
            <div class="text-body-1">
              {{ detailData.vod_content }}
            </div>
          </v-card-text>
  
          <!-- 播放列表 -->
          <v-card-text>
            <div class="text-h6 font-weight-bold mb-4">播放列表</div>
            <v-list>
              <v-list-item
                v-for="(playItem, index) in playList"
                :key="index"
                class="mb-2 rounded-lg"
              >
                <template #prepend>
                  <v-icon icon="mdi-play-circle" color="primary"></v-icon>
                </template>
                
                <v-list-item-title>
                  {{ playItem.split('$')[0] || `第${index + 1}集` }}
                </v-list-item-title>
  
                <template #append>
                  <v-btn
                    variant="tonal"
                    color="primary"
                    @click="handlePlay(index)"
                  >
                    播放
                  </v-btn>
                </template>
              </v-list-item>
            </v-list>
          </v-card-text>
          <v-card-text v-if="showPlayer">
            <div class="text-h6 font-weight-bold mb-4">正在播放</div>
            <div id="xgplayer-container"></div>
        </v-card-text>
        </v-card>
      </v-container>
    </v-app>
  </template>
  
  <script setup>
  import { ref, onMounted } from 'vue'
  import { useRoute,useRouter } from 'vue-router'
  import Player from 'xgplayer'
  import 'xgplayer-hls'
  const route = useRoute()
  const router = useRouter()
  const detailData = ref({})
  const playList = ref([])
  const playerRef = ref(null) // 播放器实例引用
  const showPlayer = ref(false) // 控制播放器显示


const handlePlay = (index) => {
    console.log('index : ', index)
      router.push({
        path: '/Play',
        query: {
          playList: encodeURIComponent(JSON.stringify(playList.value)),
          index: index
        }
      })
    }
  onMounted(() => {
  // 新增调试日志
//   console.log('路由参数:', route.query.item)
  
  if (route.query.item) {
    try {
      // 关键修复：先解码URI组件，再解析JSON
      const decodedItem = decodeURIComponent(route.query.item)
      detailData.value = JSON.parse(decodedItem)
      
      // 处理播放列表
      if (detailData.value.vod_play_url) {
        playList.value = detailData.value.vod_play_url.split('#')
      }
      
      // 调试日志
      console.log('解析后的数据:', detailData.value)
    } catch (e) {
      console.error('参数解析失败:', e)
      // 可以添加错误提示
    }
  }
})

onUnmounted(() => {
  if (playerRef.value) {
    playerRef.value.destroy()
  }
})
  </script>
  
  <style scoped>
  /* 保持与首页一致的圆角风格 */
  .rounded-lg {
    border-radius: 12px;
  }
  
  /* 播放列表项样式 */
  .v-list-item {
    border: 1px solid rgba(0,0,0,0.12);
    transition: all 0.3s ease;
  }
  
  .v-list-item:hover {
    transform: translateX(4px);
    box-shadow: 0 3px 6px rgba(0,0,0,0.1);
  }
  </style>