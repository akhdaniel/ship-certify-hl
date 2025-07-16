import { createApp } from 'vue'
import { createPinia } from 'pinia'
import { createRouter, createWebHistory } from 'vue-router'
import naive from 'naive-ui'
import App from './App.vue'

// Views
import Home from './views/Home.vue'
import Vessels from './views/Vessels.vue'
import Surveys from './views/Surveys.vue'
import Findings from './views/Findings.vue'
import Certificates from './views/Certificates.vue'
import ShipOwners from './views/ShipOwners.vue'
import Authority from './views/Authority.vue'

const routes = [
  { path: '/', name: 'Home', component: Home },
  { path: '/vessels', name: 'Vessels', component: Vessels },
  { path: '/surveys', name: 'Surveys', component: Surveys },
  { path: '/findings', name: 'Findings', component: Findings },
  { path: '/certificates', name: 'Certificates', component: Certificates },
  { path: '/shipowners', name: 'ShipOwners', component: ShipOwners },
  { path: '/authority', name: 'Authority', component: Authority },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

const app = createApp(App)
app.use(createPinia())
app.use(router)
app.use(naive)
app.mount('#app')