import axios from 'axios'
import { useUserStore } from '@/stores/user'

const api = axios.create({
  baseURL: '/api',
  timeout: 10000,
})

// Request interceptor
api.interceptors.request.use(
  (config) => {
    // Attach JWT token if available
    try {
      const userStore = useUserStore()
      if (userStore.isLoggedIn() && userStore.token) {
        config.headers = config.headers || {}
        config.headers['Authorization'] = `Bearer ${userStore.token}`
      }
    } catch (e) {}
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// Response interceptor
api.interceptors.response.use(
  (response) => {
    return response.data
  },
  (error) => {
    const message = error.response?.data?.message || error.message || 'An error occurred'
    return Promise.reject(new Error(message))
  }
)

// API endpoints
export const vesselApi = {
  getAll: () => api.get('/vessels'),
  getById: (id) => api.get(`/vessels/${id}`),
  create: (data) => api.post('/vessels', data),
  getMy: () => api.get('/vessels/my'),
}

export const surveyApi = {
  getAll: () => api.get('/surveys'),
  create: (data) => api.post('/surveys', data),
  start: (id) => api.put(`/surveys/${id}/start`),
}

export const findingApi = {
  getAllOpen: () => api.get('/findings/open'),
  getBySurvey: (surveyId) => api.get(`/surveys/${surveyId}/findings`),
  create: (surveyId, data) => api.post(`/surveys/${surveyId}/findings`, data),
  resolve: (surveyId, findingId, data) => api.put(`/surveys/${surveyId}/findings/${findingId}/resolve`, data),
  verify: (surveyId, findingId, data) => api.put(`/surveys/${surveyId}/findings/${findingId}/verify`, data),
  getMyOpen: () => api.get('/findings/my/open'),
}

export const certificateApi = {
  getAll: () => api.get('/certificates'),
  getById: (id) => api.get(`/certificates/${id}`),
  create: (data) => api.post('/certificates', data),
  verify: (id) => api.get(`/certificates/${id}/verify`),
}

export const shipOwnerApi = {
  getAll: () => api.get('/shipowners'),
  create: (data) => api.post('/shipowners', data),
}

export const authorityApi = {
  create: (data) => api.post('/authorities', data),
}

export default api