import axios from 'axios'

const api = axios.create({
  baseURL: '/api',
  timeout: 10000,
})

// Request interceptor
api.interceptors.request.use(
  (config) => {
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
}

export const surveyApi = {
  getAll: () => api.get('/surveys'),
  create: (data) => api.post('/surveys', data),
  start: (id) => api.put(`/surveys/${id}/start`),
}

export const findingApi = {
  getBySurvey: (surveyId) => api.get(`/surveys/${surveyId}/findings`),
  create: (surveyId, data) => api.post(`/surveys/${surveyId}/findings`, data),
  resolve: (surveyId, findingId, data) => api.put(`/surveys/${surveyId}/findings/${findingId}/resolve`, data),
  verify: (surveyId, findingId, data) => api.put(`/surveys/${surveyId}/findings/${findingId}/verify`, data),
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