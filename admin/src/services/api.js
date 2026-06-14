import axios from 'axios'
import { useAuthStore } from '../stores/auth'

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'https://horizon-back-u0iy.onrender.com/api/admin', // Endereço base do backend
})

api.interceptors.request.use((config) => {
  const authStore = useAuthStore()
  if (authStore.adminKey) {
    config.headers['x-admin-key'] = authStore.adminKey
  }
  return config
}, (error) => {
  return Promise.reject(error)
})

api.interceptors.response.use((response) => response, (error) => {
  if (error.response && error.response.status === 401) {
    const authStore = useAuthStore()
    authStore.clearAdminKey()
    window.location.href = '/admin/login'
  }
  return Promise.reject(error)
})

export default api
