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
          <div class="mobile-sidebar-header" @click="$router.push('/')" >
            <n-text strong class="brand-text" style="padding-left: 80px">Vessels Certification</n-text>
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
                <div class="brand-container" @click="$router.push('/')" style="cursor: pointer;">
                  <div class="brand-icon">🚢</div>
                  <n-text strong class="brand-text" v-if="!isMobile">
                    Vessels Certification System
                  </n-text>
                  <n-text strong class="brand-text-short" style="padding-left: 10px" v-else>
                    Vessels Certification System
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
                    :style="{ width: isCompact ? '150px' : '200px', paddingLeft: '8px', paddingRight: '8px' }"
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

  // if (currentRole.value === 'authority') {
  //   return [
  //     ...baseMenu,
  //     { label: 'Survey', key: '/surveys', to: '/surveys' },
  //     { label: 'Findings', key: '/findings', to: '/findings' },
  //     { label: 'Ship Owner', key: '/shipowners', to: '/shipowners' },
  //     { label: 'Authority', key: '/authority', to: '/authority' }
  //   ]
  // } else if (currentRole.value === 'shipowner') {
  //   return [
  //     ...baseMenu,
  //     { label: 'Survey', key: '/surveys', to: '/surveys' },
  //     { label: 'Findings', key: '/findings', to: '/findings' }
  //   ]
  // }

  return baseMenu
})

// Compact menu for smaller screens (shows icons and text)
const compactMenuOptions = computed(() => {
  const essentialMenu = [
    { label: '🏠 Beranda', key: '/', to: '/' },
    { label: '🚢 Kapal', key: '/vessels', to: '/vessels' },
    { label: '📜 Sertifikat', key: '/certificates', to: '/certificates' }
  ]

  // if (currentRole.value === 'authority') {
  //   return [
  //     ...essentialMenu,
  //     { label: '🔍 Survey', key: '/surveys', to: '/surveys' },
  //     { label: '⚠️ Findings', key: '/findings', to: '/findings' },
  //     { label: '👥 Ship Owners', key: '/shipowners', to: '/shipowners' },
  //     { label: '🏛️ Authority', key: '/authority', to: '/authority' }
  //   ]
  // } else if (currentRole.value === 'shipowner') {
  //   return [
  //     ...essentialMenu,
  //     { label: '🔍 Survey', key: '/surveys', to: '/surveys' },
  //     { label: '⚠️ Findings', key: '/findings', to: '/findings' }
  //   ]
  // }

  return essentialMenu
})

const toggleTheme = (value) => {
  isDark.value = value
  // Set data-theme attribute on html and body for better CSS targeting
  if (value) {
    document.documentElement.setAttribute('data-theme', 'dark')
    document.body.setAttribute('data-theme', 'dark')
  } else {
    document.documentElement.removeAttribute('data-theme')
    document.body.removeAttribute('data-theme')
  }
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
  
  // Initialize theme attributes
  if (isDark.value) {
    document.documentElement.setAttribute('data-theme', 'dark')
    document.body.setAttribute('data-theme', 'dark')
  }
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

/* Add container responsive styles */
.container-responsive {
  padding-left: 2rem;
  padding-right: 2rem;
  max-width: 1200px;
  margin: 0 auto;
}

/* Responsive padding adjustments */
@media (min-width: 640px) {
  .container-responsive {
    padding-left: 1.5rem;
    padding-right: 1.5rem;
  }
}

@media (min-width: 768px) {
  .container-responsive {
    padding-left: 2rem;
    padding-right: 2rem;
  }
}

@media (min-width: 1024px) {
  .container-responsive {
    padding-left: 2.5rem;
    padding-right: 2.5rem;
  }
}

@media (min-width: 1280px) {
  .container-responsive {
    padding-left: 3rem;
    padding-right: 3rem;
  }
}

body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
    sans-serif;
  background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
  min-height: 100vh;
  transition: background 0.3s ease;
}

/* Dark mode body - Force override */
body[data-theme="dark"],
html[data-theme="dark"] body,
.n-config-provider[data-theme="dark"] body {
  background: linear-gradient(135deg, #0f1419 0%, #1a202c 50%, #2d3748 100%) !important;
}

/* Additional dark mode root override */
html[data-theme="dark"] {
  background: linear-gradient(135deg, #0f1419 0%, #1a202c 50%, #2d3748 100%) !important;
}

#app {
  height: 100vh;
  transition: background 0.3s ease;
}

/* Dark mode for #app */
#app[data-theme="dark"] {
  background: linear-gradient(135deg, #0f1419 0%, #1a202c 50%, #2d3748 100%) !important;
}

.app-container {
  position: relative;
  min-height: 100vh;
  background: inherit;
  transition: background 0.3s ease;
}

/* Dark mode app container - multiple selectors for better coverage */
.app-container[data-theme="dark"],
.n-config-provider[data-theme="dark"] .app-container,
[data-theme="dark"] .app-container {
  background: linear-gradient(135deg, #0f1419 0%, #1a202c 50%, #2d3748 100%) !important;
}

/* Mobile Menu Toggle */
.mobile-menu-toggle {
  position: fixed;
  top: 0.5rem;
  left: 1rem;
  z-index: 1001;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
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

/* Dark mode mobile toggle - multiple selectors */
.mobile-menu-toggle[data-theme="dark"],
.n-config-provider[data-theme="dark"] .mobile-menu-toggle,
[data-theme="dark"] .mobile-menu-toggle {
  background: linear-gradient(135deg, #4c1d95 0%, #7c3aed 100%) !important;
  box-shadow: 0 4px 12px rgba(124, 58, 237, 0.3) !important;
}

/* Mobile Sidebar */
.mobile-sidebar {
  position: fixed;
  top: 0;
  left: -100%;
  width: 280px;
  height: 100vh;
  background: linear-gradient(180deg, #1e3c72 0%, #2a5298 100%);
  z-index: 1000;
  transition: left 0.3s ease;
  overflow-y: auto;
  box-shadow: 4px 0 20px rgba(0, 0, 0, 0.1);
  /* padding: 1rem; */
}

/* Dark mode mobile sidebar - multiple selectors */
.mobile-sidebar[data-theme="dark"],
.n-config-provider[data-theme="dark"] .mobile-sidebar,
[data-theme="dark"] .mobile-sidebar {
  background: linear-gradient(180deg, #1a202c 0%, #2d3748 100%) !important;
  box-shadow: 4px 0 20px rgba(0, 0, 0, 0.5) !important;
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

/* Removed old mobile sidebar header dark mode - using new selectors above */
.mobile-sidebar-header .brand-text {
  color: white;
  font-size: 1.125rem;
}

.mobile-nav {
  background: transparent !important;
}

/* Dark mode mobile nav items - Removed old selectors, using new ones above */

.mobile-controls {
  padding: 1rem 0;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  margin-top: 2rem;
}

/* Dark mode mobile controls - Removed old selectors, using new ones above */

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

/* Dark mode mobile overlay - Removed old selectors, using new ones above */

/* Header Styles */
.header-gradient {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 50%, #667eea 100%);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  position: relative;
  overflow: hidden;
  transition: background 0.3s ease, box-shadow 0.3s ease;
}

/* Dark mode header - multiple selectors */
.header-gradient[data-theme="dark"],
.n-config-provider[data-theme="dark"] .header-gradient,
[data-theme="dark"] .header-gradient {
  background: linear-gradient(135deg, #1a202c 0%, #2d3748 50%, #4a5568 100%) !important;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3) !important;
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

/* Dark mode header shimmer - multiple selectors */
.header-gradient[data-theme="dark"]::before,
.n-config-provider[data-theme="dark"] .header-gradient::before,
[data-theme="dark"] .header-gradient::before {
  background: linear-gradient(45deg, transparent 30%, rgba(255, 255, 255, 0.05) 50%, transparent 70%) !important;
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
  font-size: 0.9rem;
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
  transition: background 0.3s ease;
}

/* Dark mode navigation - multiple selectors */
.nav-gradient[data-theme="dark"],
.n-config-provider[data-theme="dark"] .nav-gradient,
[data-theme="dark"] .nav-gradient {
  background: rgba(255, 255, 255, 0.05) !important;
  border: 1px solid rgba(255, 255, 255, 0.1) !important;
}

/* Navigation menu items styling - Force white in both light and dark mode */
:deep(.nav-gradient .n-menu .n-menu-item .n-menu-item-content) {
  color: white !important;
  font-weight: 700 !important;
  font-size: 0.875rem !important;
  white-space: nowrap !important;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.8) !important;
  filter: brightness(1.5) contrast(1.2) !important;
}

:deep(.nav-gradient .n-menu .n-menu-item .n-menu-item-content .n-menu-item-content-header) {
  color: white !important;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.8) !important;
  filter: brightness(1.5) contrast(1.2) !important;
  font-weight: 700 !important;
}

:deep(.nav-gradient .n-menu .n-menu-item:hover .n-menu-item-content) {
  color: white !important;
  text-shadow: 0 2px 8px rgba(0, 0, 0, 0.9) !important;
  filter: brightness(1.8) contrast(1.3) !important;
}

:deep(.nav-gradient .n-menu .n-menu-item:hover .n-menu-item-content .n-menu-item-content-header) {
  color: white !important;
  text-shadow: 0 2px 8px rgba(0, 0, 0, 0.9) !important;
  filter: brightness(1.8) contrast(1.3) !important;
}

:deep(.nav-gradient .n-menu .n-menu-item.n-menu-item--selected .n-menu-item-content) {
  color: white !important;
  font-weight: 800 !important;
  text-shadow: 0 2px 8px rgba(0, 0, 0, 0.9) !important;
  filter: brightness(2.0) contrast(1.4) !important;
}

:deep(.nav-gradient .n-menu .n-menu-item.n-menu-item--selected .n-menu-item-content .n-menu-item-content-header) {
  color: white !important;
  font-weight: 800 !important;
  text-shadow: 0 2px 8px rgba(0, 0, 0, 0.9) !important;
  filter: brightness(2.0) contrast(1.4) !important;
}

/* Force white text regardless of theme */
.n-config-provider .nav-gradient :deep(.n-menu .n-menu-item .n-menu-item-content),
.n-config-provider[data-theme="dark"] .nav-gradient :deep(.n-menu .n-menu-item .n-menu-item-content) {
  color: white !important;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.8) !important;
  filter: brightness(1.5) contrast(1.2) !important;
}

.n-config-provider .nav-gradient :deep(.n-menu .n-menu-item .n-menu-item-content .n-menu-item-content-header),
.n-config-provider[data-theme="dark"] .nav-gradient :deep(.n-menu .n-menu-item .n-menu-item-content .n-menu-item-content-header) {
  color: white !important;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.8) !important;
  filter: brightness(1.5) contrast(1.2) !important;
}

/* Main Content */
.main-layout {
  background: transparent;
  transition: background 0.3s ease;
}

.main-content {
  background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
  min-height: calc(100vh - 72px);
  position: relative;
  padding-left: 10px;
  padding-right: 10px;
  transition: background 0.3s ease;
}

/* Dark mode main content - multiple selectors */
.main-content[data-theme="dark"],
.n-config-provider[data-theme="dark"] .main-content,
[data-theme="dark"] .main-content {
  background: linear-gradient(135deg, #0f1419 0%, #1a202c 50%, #2d3748 100%) !important;
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
  transition: opacity 0.3s ease;
}

/* Dark mode pattern overlay - multiple selectors */
.main-content[data-theme="dark"]::before,
.n-config-provider[data-theme="dark"] .main-content::before,
[data-theme="dark"] .main-content::before {
  background: url('data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><defs><pattern id="dots-dark" width="20" height="20" patternUnits="userSpaceOnUse"><circle cx="10" cy="10" r="1" fill="rgba(124,58,237,0.15)"/></pattern></defs><rect width="100" height="100" fill="url(%23dots-dark)"/></svg>') !important;
  opacity: 0.2 !important;
}

.content-wrapper {
  position: relative;
  z-index: 1;
  padding: 2rem 0;
  min-height: calc(100vh - 72px - 4rem);
}

/* Role select and theme switch dark mode styling - Removed old selectors, using new ones above */

/* Responsive adjustments */
@media (max-width: 1200px) {
  .nav-gradient {
    padding: 0.375rem 0.75rem;
  }
  
  :deep(.nav-gradient .n-menu .n-menu-item .n-menu-item-content) {
    font-size: 0.8rem !important;
    color: white !important;
    text-shadow: 0 2px 6px rgba(0, 0, 0, 0.8) !important;
    filter: brightness(1.5) contrast(1.2) !important;
  }
  
  :deep(.nav-gradient .n-menu .n-menu-item .n-menu-item-content .n-menu-item-content-header) {
    color: white !important;
    text-shadow: 0 2px 6px rgba(0, 0, 0, 0.8) !important;
    filter: brightness(1.5) contrast(1.2) !important;
  }
  
  .n-config-provider .nav-gradient :deep(.n-menu .n-menu-item .n-menu-item-content),
  .n-config-provider[data-theme="dark"] .nav-gradient :deep(.n-menu .n-menu-item .n-menu-item-content) {
    color: white !important;
    font-size: 0.8rem !important;
    text-shadow: 0 2px 6px rgba(0, 0, 0, 0.8) !important;
    filter: brightness(1.5) contrast(1.2) !important;
  }
}

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
  
  .nav-gradient {
    padding: 0.25rem 0.5rem;
  }
  
  :deep(.nav-gradient .n-menu .n-menu-item .n-menu-item-content) {
    font-size: 0.75rem !important;
    color: white !important;
    text-shadow: 0 2px 6px rgba(0, 0, 0, 0.8) !important;
    filter: brightness(1.5) contrast(1.2) !important;
  }
  
  :deep(.nav-gradient .n-menu .n-menu-item .n-menu-item-content .n-menu-item-content-header) {
    color: white !important;
    text-shadow: 0 2px 6px rgba(0, 0, 0, 0.8) !important;
    filter: brightness(1.5) contrast(1.2) !important;
  }
  
  .n-config-provider .nav-gradient :deep(.n-menu .n-menu-item .n-menu-item-content),
  .n-config-provider[data-theme="dark"] .nav-gradient :deep(.n-menu .n-menu-item .n-menu-item-content) {
    color: white !important;
    font-size: 0.75rem !important;
    text-shadow: 0 2px 6px rgba(0, 0, 0, 0.8) !important;
    filter: brightness(1.5) contrast(1.2) !important;
  }
  
  :deep(.nav-gradient .n-menu .n-menu-item) {
    margin: 0 0.125rem;
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

/* Dark mode scrollbar - Removed old selectors, using new ones above */

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

/* Enhanced dark theme text colors - multiple selectors */
.n-config-provider[data-theme="dark"] :deep(.n-text),
[data-theme="dark"] :deep(.n-text) {
  color: #e2e8f0 !important;
}

.n-config-provider[data-theme="dark"] :deep(.n-card),
[data-theme="dark"] :deep(.n-card) {
  background: rgba(45, 55, 72, 0.8) !important;
  border: 1px solid rgba(255, 255, 255, 0.1) !important;
}

.n-config-provider[data-theme="dark"] :deep(.n-button),
[data-theme="dark"] :deep(.n-button) {
  background: rgba(124, 58, 237, 0.8) !important;
  border: 1px solid rgba(124, 58, 237, 0.6) !important;
}

.n-config-provider[data-theme="dark"] :deep(.n-input),
[data-theme="dark"] :deep(.n-input) {
  background: rgba(45, 55, 72, 0.8) !important;
  border: 1px solid rgba(255, 255, 255, 0.2) !important;
  color: #e2e8f0 !important;
}

.n-config-provider[data-theme="dark"] :deep(.n-select),
[data-theme="dark"] :deep(.n-select) {
  background: rgba(45, 55, 72, 0.8) !important;
  border: 1px solid rgba(255, 255, 255, 0.2) !important;
}

/* Global dark mode adjustments - multiple selectors */
.n-config-provider[data-theme="dark"],
[data-theme="dark"] {
  background: linear-gradient(135deg, #0f1419 0%, #1a202c 50%, #2d3748 100%) !important;
}

/* Ensure proper contrast for all interactive elements - multiple selectors */
.n-config-provider[data-theme="dark"] :deep(.n-dropdown-menu),
[data-theme="dark"] :deep(.n-dropdown-menu) {
  background: rgba(45, 55, 72, 0.95) !important;
  border: 1px solid rgba(255, 255, 255, 0.1) !important;
  backdrop-filter: blur(10px);
}

.n-config-provider[data-theme="dark"] :deep(.n-dropdown-option),
[data-theme="dark"] :deep(.n-dropdown-option) {
  color: #e2e8f0 !important;
}

.n-config-provider[data-theme="dark"] :deep(.n-dropdown-option:hover),
[data-theme="dark"] :deep(.n-dropdown-option:hover) {
  background: rgba(124, 58, 237, 0.2) !important;
}

/* Additional dark mode styling for better coverage */
[data-theme="dark"] body,
[data-theme="dark"] html {
  background: linear-gradient(135deg, #0f1419 0%, #1a202c 50%, #2d3748 100%) !important;
  color: #e2e8f0 !important;
}

/* Dark mode for layout components */
[data-theme="dark"] :deep(.n-layout),
[data-theme="dark"] :deep(.n-layout-header),
[data-theme="dark"] :deep(.n-layout-content) {
  background: transparent !important;
}

/* Dark mode for menu items in mobile sidebar */
[data-theme="dark"] .mobile-nav :deep(.n-menu-item),
.n-config-provider[data-theme="dark"] .mobile-nav :deep(.n-menu-item) {
  color: #e2e8f0 !important;
}

[data-theme="dark"] .mobile-nav :deep(.n-menu-item:hover),
.n-config-provider[data-theme="dark"] .mobile-nav :deep(.n-menu-item:hover) {
  background: rgba(255, 255, 255, 0.1) !important;
  color: white !important;
}

/* Dark mode for mobile controls */
[data-theme="dark"] .mobile-controls,
.n-config-provider[data-theme="dark"] .mobile-controls {
  border-top: 1px solid rgba(255, 255, 255, 0.2) !important;
}

/* Dark mode for mobile sidebar header */
[data-theme="dark"] .mobile-sidebar-header,
.n-config-provider[data-theme="dark"] .mobile-sidebar-header {
  border-bottom: 1px solid rgba(255, 255, 255, 0.2) !important;
}

/* Dark mode for mobile overlay */
[data-theme="dark"] .mobile-overlay,
.n-config-provider[data-theme="dark"] .mobile-overlay {
  background: rgba(0, 0, 0, 0.7) !important;
}

/* Dark mode scrollbar */
[data-theme="dark"] ::-webkit-scrollbar-track,
.n-config-provider[data-theme="dark"] ::-webkit-scrollbar-track {
  background: #2d3748 !important;
}

[data-theme="dark"] ::-webkit-scrollbar-thumb,
.n-config-provider[data-theme="dark"] ::-webkit-scrollbar-thumb {
  background: linear-gradient(135deg, #4c1d95 0%, #7c3aed 100%) !important;
}

[data-theme="dark"] ::-webkit-scrollbar-thumb:hover,
.n-config-provider[data-theme="dark"] ::-webkit-scrollbar-thumb:hover {
  background: linear-gradient(135deg, #5b21b6 0%, #8b5cf6 100%) !important;
}

/* Role select and theme switch dark mode styling */
[data-theme="dark"] .role-select,
.n-config-provider[data-theme="dark"] .role-select {
  background: rgba(255, 255, 255, 0.1) !important;
  border: 1px solid rgba(255, 255, 255, 0.2) !important;
}

[data-theme="dark"] .theme-switch,
.n-config-provider[data-theme="dark"] .theme-switch {
  background: rgba(255, 255, 255, 0.1) !important;
}


[data-theme="dark"] .filter-box{
    background: rgba(255, 255, 255, 0.1) !important;

}
</style>