<template>
  <v-app>
    <!-- 顶部搜索栏 -->
    <v-container fluid class="custom-sticky-top">
      <v-row>
        <v-col cols="4">
          <v-select
            :items="options"
            item-title="type_name"
            item-value="type_id"
            label="选择分类"
            v-model="selectedOption"
            rounded
            outlined
            variant="plain"
          ></v-select>
        </v-col>
        <v-col cols="8">
          <v-text-field
            v-model="searchQueryInput"
            label="搜索"
            placeholder="输入关键词，按回车搜索"
            rounded
            outlined
            variant="plain"
            @keydown.enter="handleSearch"
          ></v-text-field>
        </v-col>
      </v-row>
    </v-container>

    <!-- 瀑布流卡片 -->
    <v-container>
      <div ref="masonryRef" class="masonry">
        <div v-for="item in filteredItems" :key="item.vod_id" class="masonry-item">
          <v-card class="rounded-lg elevation-2">
            <v-img
              :src="item.vod_pic"
              aspect-ratio="395/326"
              class="rounded-t-lg"
              @click="handleClick(item)"
              @load="imageLoaded"
            >
              <template #placeholder>
                <v-skeleton-loader type="image" aspect-ratio="16/9"></v-skeleton-loader>
              </template>
              <template #bottom>
                <v-card-subtitle class="bg-white text-black px-3 py-1 rounded-br-lg">
                  {{ item.tag }}
                </v-card-subtitle>
              </template>
            </v-img>
            <v-card-title class="px-3 py-2">{{ item.vod_name }}</v-card-title>
            <v-card-text class="px-3 py-2">
              {{ item.vod_content.slice(0, 50) + (item.vod_content.length > 50 ? "..." : "") }}
            </v-card-text>
          </v-card>
        </div>
      </div>
    </v-container>
  </v-app>
</template>

<script setup>
import { ref, onMounted, watch, computed } from "vue";
import Masonry from "masonry-layout";
import { get } from "@/plugins/useAxios";
import { useRouter } from 'vue-router';
import { UAParser } from 'ua-parser-js';

const router = useRouter();

const items = ref([]);
const options = ref([]);
const selectedOption = ref("0");
const searchQuery = ref("");
const searchQueryInput = ref(""); // 临时存放搜索框输入的内容
const page = ref(1);
const pagecount = ref(Infinity);
const isLoading = ref(false);

// 计算筛选后的数据
const filteredItems = computed(() => {
  return items.value.filter((item) => {
    if (item.type_id === '19' || item.type_id === '61') {
      return false;
    }
    const isOptionMatch = selectedOption.value === "0" || item.type_id === selectedOption.value;
    const isSearchMatch =
      !searchQuery.value ||
      item.vod_name.includes(searchQuery.value) ||
      item.vod_content.includes(searchQuery.value);
    return isOptionMatch && isSearchMatch;
  });
});

const handleClick = (item) => {
  router.push({
    path: '/film_detail',
    query: { item: JSON.stringify(item) }
  });
};

// 处理搜索逻辑（按下回车时调用）
const handleSearch = () => {
  searchQuery.value = searchQueryInput.value; // 将输入框的内容同步到真正搜索字段
  page.value = 1;
  pagecount.value = Infinity;
  items.value = []; // 清空数据
  fetchData(1);  // 触发数据请求
};

// 获取分类数据
const fetchCategories = async () => {
  try {
    // const data = await get("https://api.yzzy-api.com/inc/apijson.php?ac=list");
    const data = await get("/proxy/api/get_list");
    if (data.class) {
      // options.value = [{ type_id: "0", type_name: "全部" }, ...data.class];
      const filteredClasses = data.class.filter(
        item => item.type_id !== '19' && item.type_id !== '61'
      );
      
      options.value = [
        { type_id: "0", type_name: "全部" }, 
        ...filteredClasses
      ];
      selectedOption.value = "0"; // 默认选中 "全部"
    }
  } catch (error) {
    console.error("获取分类失败:", error);
  }
};

// 获取数据
const fetchData = async (pg) => {
  console.log('fetchData',isLoading.value, pg, pagecount.value)
  if (isLoading.value || pg < 1 || pg > pagecount.value) return;
  isLoading.value = true;

  try {
    const params = {
      t: selectedOption.value,
      pg,
    };
    if (searchQuery.value) {
      params.wd = searchQuery.value;
    }

    const { code, list, page: currentPage, pagecount: maxPage } = await get(
      // "https://api.yzzy-api.com/inc/apijson.php?ac=detail",
      "/proxy/api/get_detail", 
      params
    );
    console.log('fetchData1',code, list, currentPage, maxPage)
    if (code === 1) {
      page.value = currentPage;
      pagecount.value = maxPage;
      updateItems(list, currentPage); // 更新数据
    }
  } catch (error) {
    console.error("数据请求失败:", error);
  } finally {
    isLoading.value = false;
  }
};


// 更新 items
const updateItems = (newData, currentPage) => {
  // if (currentPage > page.value) {
  //   if (items.value.length >= 100) {
  //     items.value.splice(0, 20);
  //   }
  //   items.value.push(...newData);
  // } else {
  //   items.value = [...newData];
  // }
  console.log('updateItems',newData, currentPage)
  if (currentPage === 1) {
    // 如果是第一页，直接替换所有数据
    items.value = [...newData];
    console.log('filteredItems: ',filteredItems.value)
  } else {
    // 如果是后续页，累加数据
    items.value.push(...newData);
  }
};

// 监听分类变化，重新加载数据
watch(selectedOption, () => {
  // console.log('fenlei:',selectedOption)
  searchQuery.value = searchQueryInput.value; 
  page.value = 1;
  pagecount.value = Infinity;
  items.value = [];
  fetchData(1);
});

// 滚动加载更多数据
const onScroll = () => {
  if (isLoading.value) return;
  const threshold = 200; // 增加触发阈值
  const { scrollTop, scrollHeight, clientHeight } = document.documentElement;
  if (scrollHeight - (scrollTop + clientHeight) < threshold) {
    fetchData(page.value + 1);
  }
};

// Masonry 布局
const masonryRef = ref(null);
let masonryInstance;

const imageLoaded = () => {
  setTimeout(() => {
    masonryInstance.reloadItems();
    masonryInstance.layout();
  }, 0);
};

onMounted(async () => {
  const parser = new UAParser();
  const ua_result = parser.getResult();
  if (ua_result.device.type === 'mobile') {
    console.log('移动端');
  } else {
    router.replace('/films_desk'); // 非移动端跳转
  }
  window.addEventListener("scroll", onScroll);
  await fetchCategories();
  fetchData(1);

  masonryInstance = new Masonry(masonryRef.value, {
  itemSelector: ".masonry-item",
  columnWidth: ".masonry-item",
  percentPosition: true,
  transitionDuration: 0 // 禁用动画确保即时布局
});

  watch(filteredItems, () => {
  nextTick(() => {
    masonryInstance.reloadItems();
    masonryInstance.layout();
    // 添加强制布局更新
    masonryRef.value.style.transform = 'translateZ(0)';
  });
});
});

onUnmounted(() => {
  window.removeEventListener("scroll", onScroll);
});
</script>

<style scoped>
.masonry {
  display: flex;
  flex-wrap: wrap;
  margin: -10px;

  transform: translateZ(0); /* 触发GPU加速 */
  backface-visibility: hidden;
}

.masonry-item {
  width: calc(50% - 16px);
  margin: 8px;
}

.rounded-lg {
  border-radius: 0.5rem;
}

.rounded-t-lg {
  border-top-left-radius: 0.5rem;
  border-top-right-radius: 0.5rem;
}

.rounded-br-lg {
  border-bottom-right-radius: 0.5rem;
}

.custom-sticky-top {
  position: sticky;
  top: 0;
  z-index: 10;

  background-color: #000;
  border-radius:  0.5rem;
  padding: 4px 16px; /* 减少上下内边距 */
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
  max-width: 95%; /* 限制宽度 */
  margin: 0 auto; /* 居中 */
  margin-top: 8px; /* 顶部留白 */
}

.v-card-title {
  font-size: 14px;
  white-space: normal;
  word-break: break-word;
}

.v-card-text {
  font-size: 12px;
  color: #757575;
}
</style>
