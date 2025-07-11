import axios from 'axios';
const baseURL = import.meta.env.VITE_API_BASE_URL;
// 创建 Axios 实例
const axiosInstance = axios.create({
  baseURL: baseURL,
  timeout: 10000, // 设置请求超时时间 (10s)
});

// 请求拦截器
axiosInstance.interceptors.request.use(
  (config) => {
    // 这里可以添加请求头等配置
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// 响应拦截器
axiosInstance.interceptors.response.use(
  (response) => {
    return response.data; // 直接返回 data，避免每次都要 data.xxx
  },
  (error) => {
    console.error('请求错误:', error);
    return Promise.reject(error);
  }
);

/**
 * 发送 GET 请求
 * @param {string} url 请求地址
 * @param {object} params 请求参数（可选）
 * @returns {Promise} 返回请求的 Promise
 */
export const get = (url, params = {}) => {
  return axiosInstance.get(url, { params });
};

/**
 * 发送 POST 请求
 * @param {string} url 请求地址
 * @param {object} data 请求数据
 * @returns {Promise} 返回请求的 Promise
 */
export const post = (url, data = {}) => {
  return axiosInstance.post(url, data);
};
