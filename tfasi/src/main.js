/**
 * main.js
 *
 * Bootstraps Vuetify and other plugins then mounts the App`
 */

// Plugins
import { registerPlugins } from '@/plugins'
// import VueMasonry from 'vue-masonry-css'
// Components
import App from './App.vue'

// Composables
import { createApp } from 'vue'

const app = createApp(App)
// app.use(VueMasonry)
registerPlugins(app)

app.mount('#app')
