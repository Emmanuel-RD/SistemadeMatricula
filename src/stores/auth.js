import { defineStore } from 'pinia'
import { authService } from '@/services/auth'

export const useAuthStore = defineStore('auth', {
  state: () => ({
    user: null,
    loading: false
  }),

  getters: {
    isAuthenticated: (state) => {
      if (state.user) return true
      const session = authService.getSession()
      if (session) {
        this.user = session
        return true
      }
      return false
    },
    userRole: (state) => {
      if (state.user) return state.user.rol_nombre
      const session = authService.getSession()
      return session?.rol_nombre || null
    },
    isAdmin: (state) => {
      if (state.user) return state.user.rol_nombre === 'admin'
      return authService.isAdmin()
    },
    isDocente: (state) => {
      if (state.user) return state.user.rol_nombre === 'docente'
      return authService.isDocente()
    },
    isAlumno: (state) => {
      if (state.user) return state.user.rol_nombre === 'alumno'
      return authService.isAlumno()
    }
  },

  actions: {
    async signIn(email, password) {
      this.loading = true
      try {
        const result = await authService.login(email, password)
        if (result.success) {
          this.user = result.data
        }
        return result
      } catch (error) {
        return { success: false, error: error.message }
      } finally {
        this.loading = false
      }
    },

    async signOut() {
      try {
        await authService.logout()
        this.user = null
        return { success: true }
      } catch (error) {
        return { success: false, error: error.message }
      }
    },

    async checkSession() {
      try {
        const session = authService.getSession()
        if (session) {
          this.user = session
          return session
        }
        this.user = null
        return null
      } catch (error) {
        console.error('Error checking session:', error)
        this.user = null
        return null
      }
    },

    async init() {
      await this.checkSession()
    }
  }
})

