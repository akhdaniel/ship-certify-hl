import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useUserStore = defineStore('user', () => {
  const role = ref('public')
  const user = ref(null)

  const setRole = (newRole) => {
    role.value = newRole
  }

  const setUser = (userData) => {
    user.value = userData
  }

  const isAuthority = () => role.value === 'authority'
  const isShipOwner = () => role.value === 'shipowner'
  const isPublic = () => role.value === 'public'

  return {
    role,
    user,
    setRole,
    setUser,
    isAuthority,
    isShipOwner,
    isPublic
  }
})