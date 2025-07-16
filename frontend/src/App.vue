<template>
  <n-config-provider :theme="theme">
    <n-layout style="height: 100vh">
      <n-layout-header bordered style="height: 64px; padding: 0 24px">
        <div style="display: flex; align-items: center; justify-content: space-between; height: 100%">
          <div style="display: flex; align-items: center">
            <n-text strong style="font-size: 18px; margin-right: 24px">
              BKI Ship Certification System
            </n-text>
            <n-menu
              v-model:value="activeKey"
              mode="horizontal"
              :options="menuOptions"
              @update:value="handleMenuUpdate"
            />
          </div>
          <div style="display: flex; align-items: center; gap: 16px">
            <n-select
              v-model:value="currentRole"
              :options="roleOptions"
              style="width: 200px"
              @update:value="handleRoleChange"
            />
            <n-switch
              v-model:value="isDark"
              @update:value="toggleTheme"
            >
              <template #checked>
                🌙
              </template>
              <template #unchecked>
                ☀️
              </template>
            </n-switch>
          </div>
        </div>
      </n-layout-header>
      
      <n-layout-content style="padding: 24px">
        <router-view />
      </n-layout-content>
    </n-layout>
  </n-config-provider>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { useRouter } from 'vue-router'
import { darkTheme } from 'naive-ui'
import { useUserStore } from './stores/user'

const router = useRouter()
const userStore = useUserStore()

const isDark = ref(false)
const activeKey = ref('/')
const currentRole = ref('public')

const theme = computed(() => isDark.value ? darkTheme : null)

const roleOptions = [
  { label: 'Public', value: 'public' },
  { label: 'BKI Authority', value: 'authority' },
  { label: 'Ship Owner', value: 'shipowner' }
]

const menuOptions = computed(() => {
  const baseMenu = [
    { label: 'Beranda', key: '/', to: '/' },
    { label: 'Kapal', key: '/vessels', to: '/vessels' },
    { label: 'Sertifikat', key: '/certificates', to: '/certificates' }
  ]

  if (currentRole.value === 'authority') {
    return [
      ...baseMenu,
      { label: 'Survey', key: '/surveys', to: '/surveys' },
      { label: 'Findings', key: '/findings', to: '/findings' },
      { label: 'Ship Owner', key: '/shipowners', to: '/shipowners' },
      { label: 'Authority', key: '/authority', to: '/authority' }
    ]
  } else if (currentRole.value === 'shipowner') {
    return [
      ...baseMenu,
      { label: 'Survey', key: '/surveys', to: '/surveys' },
      { label: 'Findings', key: '/findings', to: '/findings' }
    ]
  }

  return baseMenu
})

const toggleTheme = (value) => {
  isDark.value = value
}

const handleMenuUpdate = (key) => {
  activeKey.value = key
  const item = menuOptions.value.find(item => item.key === key)
  if (item?.to) {
    router.push(item.to)
  }
}

const handleRoleChange = (role) => {
  userStore.setRole(role)
  // Redirect to home when role changes
  router.push('/')
  activeKey.value = '/'
}

// Watch route changes
watch(() => router.currentRoute.value.path, (newPath) => {
  activeKey.value = newPath
})

// Initialize user role
userStore.setRole(currentRole.value)
</script>

<style>
body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
    sans-serif;
}

#app {
  height: 100vh;
}
</style>