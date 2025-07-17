<template>
  <div :class="['login-container', { 'dark': isDark }]">
    <n-card title="Login" style="max-width: 400px; margin: 80px auto;" :class="{ 'login-card-dark': isDark }">
      <n-form @submit.prevent="handleLogin" :model="form" :rules="rules" ref="formRef">
        <n-form-item label="Username" path="username">
          <n-input v-model:value="form.username" placeholder="Username or Email" />
        </n-form-item>
        <n-form-item label="Password" path="password">
          <n-input v-model:value="form.password" type="password" placeholder="Password" />
        </n-form-item>
        <n-form-item>
          <n-button type="primary" :loading="loading" block @click="handleLogin">Login</n-button>
        </n-form-item>
        <n-alert v-if="error" type="error" style="margin-top: 8px;">{{ error }}</n-alert>
      </n-form>
    </n-card>
  </div>
</template>

<script setup>
import { ref, inject } from 'vue'
import { useRouter } from 'vue-router'
import { useUserStore } from '@/stores/user'
import api from '@/services/api'
import { useMessage } from 'naive-ui'

const router = useRouter()
const userStore = useUserStore()
const message = useMessage()

const form = ref({ username: '', password: '' })
const loading = ref(false)
const error = ref('')
const formRef = ref(null)

const rules = {
  username: { required: true, message: 'Username is required' },
  password: { required: true, message: 'Password is required' }
}

// Get isDark from App.vue via provide/inject
const isDark = inject('isDark', false)

const handleLogin = async () => {
  console.log('Login button clicked', form.value)
  error.value = ''
  await formRef.value?.validate()
  loading.value = true
  try {
    const res = await api.post('/login', form.value)
    userStore.login(res.user, res.token)
    message.success('Login successful!')
    router.push('/')
  } catch (err) {
    error.value = err.message || 'Login failed'
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-container {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0;
  margin: 0;
}
.login-container.dark {
  background: linear-gradient(135deg, #0f1419 0%, #1a202c 50%, #2d3748 100%) !important;
}
.login-card-dark {
  background: rgba(45, 55, 72, 0.8) !important;
  border: 1px solid rgba(255, 255, 255, 0.1) !important;
  color: #e2e8f0 !important;
}
:deep(.n-card) {
  margin: 0 !important;
  padding: 0 !important;
}
</style> 