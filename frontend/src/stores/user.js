import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useUserStore = defineStore('user', () => {
  const role = ref(localStorage.getItem('role') || 'public')
  const user = ref(JSON.parse(localStorage.getItem('user') || 'null'))
  const token = ref(localStorage.getItem('token') || '')

  const setRole = (newRole) => {
    role.value = newRole
    localStorage.setItem('role', newRole)
  }

  const setUser = (userData) => {
    user.value = userData
    localStorage.setItem('user', JSON.stringify(userData))
  }

  const setToken = (jwt) => {
    token.value = jwt
    localStorage.setItem('token', jwt)
  }

  const login = (userData, jwt) => {
    setUser(userData)
    setRole(userData.role)
    setToken(jwt)
  }

  const logout = () => {
    user.value = null
    role.value = 'public'
    token.value = ''
    localStorage.removeItem('user')
    localStorage.removeItem('role')
    localStorage.removeItem('token')
  }

  const isAuthority = () => role.value === 'authority'
  const isShipOwner = () => role.value === 'shipowner'
  const isPublic = () => role.value === 'public'
  const isLoggedIn = () => !!token.value

  return {
    role,
    user,
    token,
    setRole,
    setUser,
    setToken,
    login,
    logout,
    isAuthority,
    isShipOwner,
    isPublic,
    isLoggedIn
  }
})