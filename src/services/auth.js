import { supabase } from '@/config/supabase'

/**
 * Servicio de autenticación usando tabla de usuarios
 */
export const authService = {
  /**
   * Iniciar sesión
   */
  async login(email, password) {
    try {
      const { data, error } = await supabase.rpc('verificar_password', {
        p_email: email,
        p_password: password
      })

      if (error) throw error

      if (!data || data.length === 0) {
        return { success: false, error: 'Credenciales inválidas' }
      }

      const usuario = data[0]

      if (!usuario.activo) {
        return { success: false, error: 'Usuario inactivo. Contacta al administrador.' }
      }

      // Actualizar último acceso
      await supabase
        .from('usuarios')
        .update({ ultimo_acceso: new Date().toISOString() })
        .eq('id', usuario.usuario_id)

      // Guardar sesión en localStorage
      const sessionData = {
        usuario_id: usuario.usuario_id,
        email: usuario.email,
        rol_id: usuario.rol_id,
        rol_nombre: usuario.rol_nombre,
        nombre: usuario.nombre,
        apellido: usuario.apellido,
        loggedIn: true,
        timestamp: Date.now()
      }

      localStorage.setItem('session', JSON.stringify(sessionData))

      return { success: true, data: sessionData }
    } catch (error) {
      console.error('Error en login:', error)
      return { success: false, error: error.message || 'Error al iniciar sesión' }
    }
  },

  /**
   * Cerrar sesión
   */
  async logout() {
    localStorage.removeItem('session')
    return { success: true }
  },

  /**
   * Verificar sesión
   */
  getSession() {
    try {
      const sessionStr = localStorage.getItem('session')
      if (!sessionStr) return null

      const session = JSON.parse(sessionStr)
      
      // Verificar que la sesión no sea muy antigua (24 horas)
      const maxAge = 24 * 60 * 60 * 1000 // 24 horas
      if (Date.now() - session.timestamp > maxAge) {
        localStorage.removeItem('session')
        return null
      }

      return session
    } catch (error) {
      console.error('Error al leer sesión:', error)
      localStorage.removeItem('session')
      return null
    }
  },

  /**
   * Verificar si el usuario está autenticado
   */
  isAuthenticated() {
    const session = this.getSession()
    return session !== null && session.loggedIn === true
  },

  /**
   * Obtener información del usuario actual
   */
  getCurrentUser() {
    return this.getSession()
  },

  /**
   * Verificar si el usuario tiene un rol específico
   */
  hasRole(roleName) {
    const session = this.getSession()
    return session?.rol_nombre === roleName
  },

  /**
   * Verificar si es admin
   */
  isAdmin() {
    return this.hasRole('admin')
  },

  /**
   * Verificar si es docente
   */
  isDocente() {
    return this.hasRole('docente')
  },

  /**
   * Verificar si es alumno
   */
  isAlumno() {
    return this.hasRole('alumno')
  }
}





