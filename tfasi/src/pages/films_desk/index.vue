<template>
  <v-app>
    <!-- 顶部搜索栏 -->
    <v-container fluid class="custom-sticky-top">
      <v-row>
        <v-col cols="3">
          <v-select
            :items="options"
            item-title="type_name"
            item-value="type_id"
            label="选择分类"
            v-model="selectedOption"
            rounded
            outlined
            variant="plain"
            dark
          ></v-select>
        </v-col>
        <v-col cols="9">
          <v-text-field
            v-model="searchQueryInput"
            label="搜索"
            placeholder="输入关键词，按回车搜索"
            rounded
            outlined
            variant="plain"
            dark
            @keydown="handleKeyDown"
          ></v-text-field>
        </v-col>
      </v-row>
    </v-container>

    <!-- 瀑布流卡片（纯瀑布流布局，每行约8个） -->
    <v-container class="desktop-container">
      <div ref="masonryRef" class="masonry-waterfall">
        <div 
          v-for="item in filteredItems" 
          :key="item.vod_id" 
          class="waterfall-item"
        >
          <v-card 
            class="film-card"
            @click="handleClick(item)"
          >
            <v-img
              :src="item.vod_pic"
              aspect-ratio="2/3"
              class="rounded-t-lg"
              @load="imageLoaded"
            >
              <template #placeholder>
                <v-skeleton-loader type="image" aspect-ratio="2/3"></v-skeleton-loader>
              </template>
              <template #bottom>
                <v-card-subtitle class="bg-white text-black px-2 py-1 rounded-br-lg">
                  {{ item.tag }}
                </v-card-subtitle>
              </template>
            </v-img>
            <v-card-title class="px-2 py-1">{{ item.vod_name }}</v-card-title>
            <v-card-text class="px-2 py-1 text-body-2">
              {{ item.vod_content.slice(0, 50) + (item.vod_content.length > 50 ? "..." : "") }}
            </v-card-text>
          </v-card>
        </div>
      </div>
    </v-container>

    <v-overlay :model-value="isLoading" class="align-center justify-center">
      <v-progress-circular color="primary" indeterminate size="64"></v-progress-circular>
    </v-overlay>
  </v-app>
</template>

<script setup>
import { ref, onMounted, watch, computed, nextTick } from "vue";
import Masonry from "masonry-layout";
import { get } from "@/plugins/useAxios";
import { useRouter } from 'vue-router';

const router = useRouter();

// 数据状态
const items = ref([]);
const options = ref([]);
const selectedOption = ref("0");
const searchQuery = ref("");
const searchQueryInput = ref("");
const page = ref(1);
const pagecount = ref(Infinity);
const isLoading = ref(false);
const masonryRef = ref(null);
let masonryInstance = null;

// 滚动加载
const onScroll = () => {
  if (isLoading.value) return;
  const threshold = 200;
  const { scrollTop, scrollHeight, clientHeight } = document.documentElement;
  if (scrollHeight - (scrollTop + clientHeight) < threshold) {
    fetchData(page.value + 1);
  }
};

// 键盘事件
const handleKeyDown = (e) => {
  if (e.key === 'Enter') handleSearch();
};

// 筛选数据
const filteredItems = computed(() => {
  return items.value.filter((item) => {
    if (item.type_id === '19' || item.type_id === '61') return false;
    const isOptionMatch = selectedOption.value === "0" || item.type_id === selectedOption.value;
    const isSearchMatch = !searchQuery.value || 
      item.vod_name.includes(searchQuery.value) || 
      item.vod_content.includes(searchQuery.value);
    return isOptionMatch && isSearchMatch;
  });
});

// 点击卡片
const handleClick = (item) => {
  router.push({
    path: '/film_detail',
    query: { item: JSON.stringify(item) }
  });
};

// 搜索处理
const handleSearch = () => {
  searchQuery.value = searchQueryInput.value;
  page.value = 1;
  pagecount.value = Infinity;
  items.value = [];
  fetchData(1);
};

// 获取分类
const fetchCategories = async () => {
  try {
    const data = await get("/proxy/api/get_list");
    if (data.class) {
      const filteredClasses = data.class.filter(
        item => item.type_id !== '19' && item.type_id !== '61'
      );
      options.value = [
        { type_id: "0", type_name: "全部" }, 
        ...filteredClasses
      ];
    }
  } catch (error) {
    console.error("获取分类失败:", error);
  }
};

// 获取数据
const fetchData = async (pg) => {
  if (isLoading.value || pg < 1 || pg > pagecount.value) return;
  isLoading.value = true;

  try {
    const params = {
      t: selectedOption.value,
      pg,
    };
    if (searchQuery.value) params.wd = searchQuery.value;

    const { code, list, page: currentPage, pagecount: maxPage } = await get(
      "/proxy/api/get_detail", 
      params
    );

    if (code === 1) {
      page.value = currentPage;
      pagecount.value = maxPage;
      updateItems(list, currentPage);
    }
  } catch (error) {
    console.error("数据请求失败:", error);
  } finally {
    isLoading.value = false;
  }
};

// 更新数据
const updateItems = (newData, currentPage) => {
  if (currentPage === 1) {
    items.value = [...newData];
  } else {
    items.value.push(...newData);
  }
};

// 图片加载完成
const imageLoaded = () => {
  nextTick(() => {
    masonryInstance?.reloadItems();
    masonryInstance?.layout();
  });
};

// 初始化
onMounted(async () => {
  window.addEventListener("scroll", onScroll);
  await fetchCategories();
  fetchData(1);

  // 纯瀑布流配置（自动适应列数）
  masonryInstance = new Masonry(masonryRef.value, {
    itemSelector: ".waterfall-item",
    columnWidth: 200, // 基础宽度（约8列/行）
    gutter: 12,
    fitWidth: true, // 自动适应容器
    transitionDuration: 0
  });

  watch(filteredItems, () => {
    nextTick(() => {
      masonryInstance?.reloadItems();
      masonryInstance?.layout();
    });
  });
});

// 销毁
onUnmounted(() => {
  window.removeEventListener("scroll", onScroll);
});
</script>

<style scoped>
/* 搜索栏样式 */
.custom-sticky-top {
  position: sticky;
  top: 0;
  z-index: 10;
  background-color: #000;
  border-radius: 12px;
  padding: 8px 24px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
  max-width: 95%;
  margin: 0 auto;
  margin-top: 8px;
}

/* 瀑布流容器 */
.desktop-container {
  max-width: 1800px;
  padding: 16px;
  margin: 0 auto;
}

.masonry-waterfall {
  width: 100%;
}

/* 瀑布流项目 */
.waterfall-item {
  width: 200px;
  margin-bottom: 16px;
  break-inside: avoid;
}

/* 卡片样式 */
.film-card {
  width: 100%;
  transition: all 0.3s;
  cursor: pointer;
}

/* 卡片内容 */
.v-card-title {
  font-size: 0.9rem;
  line-height: 1.3;
  white-space: normal;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  padding: 8px 12px 0;
}

.v-card-text {
  font-size: 0.8rem;
  color: #616161;
  line-height: 1.4;
  padding: 4px 12px 12px;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* 悬停效果 */
.film-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 10px 20px rgba(0, 0, 0, 0.15) !important;
}

/* 图片样式 */
.v-img {
  border-radius: 8px 8px 0 0 !important;
}
</style>