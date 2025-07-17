<template>
  <n-config-provider :theme="theme">
    <n-message-provider>
      <div class="app-container">
        <!-- Mobile Menu Toggle -->
        <div class="mobile-menu-toggle" v-if="isMobile || isTablet" @click="toggleMobileMenu">
          <n-icon size="24">
            <svg viewBox="0 0 24 24">
              <path fill="currentColor" d="M3 18h18v-2H3v2zm0-5h18v-2H3v2zm0-7v2h18V6H3z"/>
            </svg>
          </n-icon>
        </div>

        <!-- Sidebar for mobile and tablet -->
        <div class="mobile-sidebar" :class="{ 'open': mobileMenuOpen }" v-if="isMobile || isTablet">
          <div class="mobile-sidebar-header">
            <n-text strong class="brand-text">BKI Ship Certification</n-text>
            <n-icon size="24" @click="toggleMobileMenu" style="cursor: pointer;">
              <svg viewBox="0 0 24 24">
                <path fill="currentColor" d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"/>
              </svg>
            </n-icon>
          </div>
          <n-menu
            v-model:value="activeKey"
            mode="vertical"
            :options="menuOptions"
            @update:value="handleMenuUpdate"
            class="mobile-nav"
          />
          <div class="mobile-controls">
            <n-select
              v-model:value="currentRole"
              :options="roleOptions"
              style="width: 100%; margin-bottom: 16px"
              @update:value="handleRoleChange"
            />
            <n-switch
              v-model:value="isDark"
              @update:value="toggleTheme"
              style="margin-bottom: 16px"
            >
              <template #checked>🌙</template>
              <template #unchecked>☀️</template>
            </n-switch>
          </div>
        </div>

        <!-- Overlay for mobile menu -->
        <div class="mobile-overlay" v-if="mobileMenuOpen" @click="toggleMobileMenu"></div>

        <n-layout style="height: 100vh" class="main-layout">
          <n-layout-header class="header-gradient" style="height: 72px; padding: 0">
            <div class="header-content container-responsive">
              <div class="header-left">
                <div class="brand-container">
                  <div class="brand-icon">🚢</div>
                  <n-text strong class="brand-text" v-if="!isMobile">
                    BKI Ship Certification System
                  </n-text>
                  <n-text strong class="brand-text-short" v-else>
                    BKI System
                  </n-text>
                </div>
                <n-menu
                  v-if="!isMobile && !isTablet"
                  v-model:value="activeKey"
                  mode="horizontal"
                  :options="compactMenuOptions"
                  @update:value="handleMenuUpdate"
                  class="nav-gradient"
                />
              </div>
              <div class="header-right" v-if="!isMobile">
                <n-select
                  v-model:value="currentRole"
                  :options="roleOptions"
                  :style="{ width: isCompact ? '150px' : '200px' }"
                  @update:value="handleRoleChange"
                  class="role-select"
                  size="small"
                  v-if="!isTablet"
                />
                <n-switch
                  v-model:value="isDark"
                  @update:value="toggleTheme"
                  class="theme-switch"
                  size="small"
                >
                  <template #checked>🌙</template>
                  <template #unchecked>☀️</template>
                </n-switch>
              </div>
            </div>
          </n-layout-header>
          
          <n-layout-content class="main-content">
            <div class="content-wrapper container-responsive">
              <router-view />
            </div>
          </n-layout-content>
        </n-layout>
      </div>
    </n-message-provider>
  </n-config-provider>
</template>

<script setup>
import { ref, computed, watch, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { darkTheme } from 'naive-ui'
import { useUserStore } from './stores/user'

const router = useRouter()
const userStore = useUserStore()

const isDark = ref(false)
const activeKey = ref('/')
const currentRole = ref('public')
const isMobile = ref(false)
const isTablet = ref(false)
const isCompact = ref(false)
const mobileMenuOpen = ref(false)

const theme = computed(() => isDark.value ? darkTheme : null)

// Responsive detection
const checkResponsive = () => {
  const width = window.innerWidth
  isMobile.value = width < 768
  isTablet.value = width >= 768 && width < 1024
  isCompact.value = width < 1200
  
  if (!isMobile.value) {
    mobileMenuOpen.value = false
  }
}

const toggleMobileMenu = () => {
  mobileMenuOpen.value = !mobileMenuOpen.value
}

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

// Compact menu for smaller screens (shows only essential items)
const compactMenuOptions = computed(() => {
  const essentialMenu = [
    { label: '🏠', key: '/', to: '/' },
    { label: '🚢', key: '/vessels', to: '/vessels' },
    { label: '📜', key: '/certificates', to: '/certificates' }
  ]

  if (currentRole.value === 'authority') {
    return [
      ...essentialMenu,
      { label: '🔍', key: '/surveys', to: '/surveys' },
      { label: '⚠️', key: '/findings', to: '/findings' },
      { label: '👥', key: '/shipowners', to: '/shipowners' }
    ]
  } else if (currentRole.value === 'shipowner') {
    return [
      ...essentialMenu,
      { label: '🔍', key: '/surveys', to: '/surveys' },
      { label: '⚠️', key: '/findings', to: '/findings' }
    ]
  }

  return essentialMenu
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
  // Close mobile menu when navigating
  if (isMobile.value) {
    mobileMenuOpen.value = false
  }
}

const handleRoleChange = (role) => {
  currentRole.value = role
  userStore.setRole(role)
  // Redirect to home when role changes
  router.push('/')
  activeKey.value = '/'
}

// Lifecycle hooks
onMounted(() => {
  checkResponsive()
  window.addEventListener('resize', checkResponsive)
})

onUnmounted(() => {
  window.removeEventListener('resize', checkResponsive)
})

// Watch route changes
watch(() => router.currentRoute.value.path, (newPath) => {
  activeKey.value = newPath
})

// Initialize user role
userStore.setRole(currentRole.value)

// Watch for role changes and update user store
watch(currentRole, (newRole) => {
  userStore.setRole(newRole)
})
</script>

<style>
@import './styles/responsive-gradients.css';

body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
    sans-serif;
  background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
  min-height: 100vh;
}

#app {
  height: 100vh;
}

.app-container {
  position: relative;
  min-height: 100vh;
}

/* Mobile Menu Toggle */
.mobile-menu-toggle {
  position: fixed;
  top: 1rem;
  left: 1rem;
  z-index: 1001;
  background: var(--gradient-primary);
  color: white;
  border-radius: 0.5rem;
  padding: 0.75rem;
  cursor: pointer;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  transition: all 0.3s ease;
}

.mobile-menu-toggle:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 16px rgba(0, 0, 0, 0.2);
}

/* Mobile Sidebar */
.mobile-sidebar {
  position: fixed;
  top: 0;
  left: -100%;
  width: 280px;
  height: 100vh;
  background: var(--gradient-dark);
  z-index: 1000;
  transition: left 0.3s ease;
  overflow-y: auto;
  padding: 1rem;
  box-shadow: 4px 0 20px rgba(0, 0, 0, 0.1);
}

.mobile-sidebar.open {
  left: 0;
}

.mobile-sidebar-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem 0 2rem 0;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  margin-bottom: 1rem;
}

.mobile-sidebar-header .brand-text {
  color: white;
  font-size: 1.125rem;
}

.mobile-nav {
  background: transparent !important;
}

.mobile-controls {
  padding: 1rem 0;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  margin-top: 2rem;
}

.mobile-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.5);
  z-index: 999;
  backdrop-filter: blur(4px);
}

/* Header Styles */
.header-gradient {
  background: var(--gradient-ocean);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  position: relative;
  overflow: hidden;
}

.header-gradient::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: linear-gradient(45deg, transparent 30%, rgba(255, 255, 255, 0.1) 50%, transparent 70%);
  animation: shimmer 3s infinite;
}

@keyframes shimmer {
  0% { transform: translateX(-100%); }
  100% { transform: translateX(100%); }
}

.header-content {
  display: flex;
  align-items: center;
  justify-content: space-between;
  height: 72px;
  position: relative;
  z-index: 1;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 2rem;
}

.header-right {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.brand-container {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.brand-icon {
  font-size: 2rem;
  animation: float 3s ease-in-out infinite;
}

@keyframes float {
  0%, 100% { transform: translateY(0px); }
  50% { transform: translateY(-8px); }
}

.brand-text {
  color: white !important;
  font-size: 1.5rem;
  font-weight: 700;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.brand-text-short {
  color: white !important;
  font-size: 1.25rem;
  font-weight: 700;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.nav-gradient {
  background: rgba(255, 255, 255, 0.1) !important;
  border-radius: 1rem;
  backdrop-filter: blur(10px);
  padding: 0.5rem 1rem;
}

.role-select {
  background: rgba(255, 255, 255, 0.9);
  border-radius: 0.5rem;
  backdrop-filter: blur(10px);
}

.theme-switch {
  background: rgba(255, 255, 255, 0.1);
  border-radius: 2rem;
  padding: 0.5rem;
}

/* Main Content */
.main-layout {
  background: transparent;
}

.main-content {
  background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
  min-height: calc(100vh - 72px);
  position: relative;
}

.main-content::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: url('data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><defs><pattern id="dots" width="20" height="20" patternUnits="userSpaceOnUse"><circle cx="10" cy="10" r="1" fill="rgba(102,126,234,0.1)"/></pattern></defs><rect width="100" height="100" fill="url(%23dots)"/></svg>');
  opacity: 0.3;
  pointer-events: none;
}

.content-wrapper {
  position: relative;
  z-index: 1;
  padding: 2rem 0;
  min-height: calc(100vh - 72px - 4rem);
}

/* Responsive adjustments */
@media (max-width: 1024px) {
  .mobile-menu-toggle {
    display: block;
  }
  
  .header-content {
    padding-left: 4rem;
  }
  
  .brand-text-short {
    font-size: 1rem;
  }
  
  .content-wrapper {
    padding: 1rem 0;
  }
}

@media (max-width: 768px) {
  .header-content {
    padding-left: 5rem;
    padding-right: 1rem;
  }
  
  .brand-icon {
    font-size: 1.5rem;
  }
  
  .content-wrapper {
    padding: 1rem 0;
  }
}

@media (max-width: 480px) {
  .mobile-sidebar {
    width: 100%;
    left: -100%;
  }
  
  .brand-text-short {
    font-size: 0.875rem;
  }
  
  .header-content {
    padding-left: 4rem;
    padding-right: 0.5rem;
  }
}

/* Custom scrollbar */
::-webkit-scrollbar {
  width: 8px;
}

::-webkit-scrollbar-track {
  background: #f1f1f1;
  border-radius: 4px;
}

::-webkit-scrollbar-thumb {
  background: var(--gradient-primary);
  border-radius: 4px;
}

::-webkit-scrollbar-thumb:hover {
  background: var(--gradient-secondary);
}

/* Enhanced animations */
.main-layout, .content-wrapper {
  animation: fadeInUp 0.6s ease-out;
}

@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* Dark theme adjustments */
.n-config-provider[data-theme="dark"] .main-content {
  background: linear-gradient(135deg, #1a1a1a 0%, #2d3748 100%);
}

.n-config-provider[data-theme="dark"] body {
  background: linear-gradient(135deg, #1a1a1a 0%, #2d3748 100%);
}
</style>