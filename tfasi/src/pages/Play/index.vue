<template>
   
      
      <div id="xgplayer-container"></div>
      
   
  </template>
  
  <script>
  import { onMounted, onUnmounted, ref } from 'vue'
  import { useRoute } from 'vue-router'
  import Player, { Events }from 'xgplayer'
import HlsPlugin from 'xgplayer-hls'
import 'xgplayer/dist/index.min.css'; 

  
  export default {
    setup() {
      const route = useRoute()
      const playerRef = ref(null)
      const playList = ref([])
      const currentIndex = ref(0)
      const title = ref('')
  
      // 播放指定视频
      const playVideo = (index) => {
        currentIndex.value = index
        const [videoTitle, url] = playList.value[index].split('$')
  
        // 更新标题
        title.value = videoTitle
  
        // 播放器重置
        if (playerRef.value) {
          playerRef.value.destroy()
        }
  
        // 初始化播放器
        playerRef.value = new Player({
          id: 'xgplayer-container',
          url: url,
          plugins: [HlsPlugin],
          autoplay: true,
          poster: '',
          fluid: true,
          fitVideoSize: 'auto',
          lang: 'zh-cn',
          playbackRate: [0.5, 0.75 ,1, 1.25,1.5,1.75, 2]
        })
  
        // 自动播放下一集
        playerRef.value.on('ended', () => {
          if (currentIndex.value < playList.value.length - 1) {
            playVideo(currentIndex.value + 1)
          }
        })
      }
  
      onMounted(() => {
        // 获取播放列表和索引
        const decodedList = JSON.parse(decodeURIComponent(route.query.playList))
        playList.value = decodedList
        currentIndex.value = parseInt(route.query.index)
  
        // 播放当前集
        playVideo(currentIndex.value)
      })
  
      onUnmounted(() => {
        if (playerRef.value) {
          playerRef.value.destroy()
        }
      })
  
      return {
        title,
        playList,
        currentIndex,
        playVideo
      }
    }
  }
  </script>
  
  <style scoped>
  #xgplayer-container {
    width: 100%;
    height: 500px;
  }
  
  .playlist {
    margin-top: 20px;
  }
  
  .playlist ul {
    list-style: none;
    padding: 0;
  }
  
  .playlist li {
    cursor: pointer;
    padding: 10px;
    border-bottom: 1px solid #eee;
  }
  
  .playlist li.active {
    background-color: #f0f8ff;
    color: #007bff;
  }
  </style>
  