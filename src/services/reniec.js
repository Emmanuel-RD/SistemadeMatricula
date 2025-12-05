// Servicio para consultar RENIEC (API Decolecta)
const API_URL = import.meta.env.DEV
  ? '/api/reniec/dni'
  : 'https://api.decolecta.com/v1/reniec/dni'

// Usa token desde .env; el valor hardcode es solo fallback local
const API_TOKEN = import.meta.env.VITE_RENIEC_TOKEN || 'sk_12167.HYeEssEmqJQgiqHwzS56LEmN8DhhCwMS'

const buildHeaders = () => ({
  'Content-Type': 'application/json',
  Authorization: `Bearer ${API_TOKEN}`
})

export const reniecService = {
  /**
   * Obtiene datos de persona por DNI usando la API de Decolecta/RENIEC
   * @param {string} dni - Número de DNI (8 dígitos)
   */
  async fetchByDni(dni) {
    const sanitized = String(dni || '').trim()

    if (sanitized.length !== 8 || !/^\d{8}$/.test(sanitized)) {
      return { success: false, error: 'El DNI debe tener 8 dígitos numéricos.' }
    }

    try {
      const response = await fetch(`${API_URL}?numero=${sanitized}`, {
        method: 'GET',
        headers: buildHeaders()
      })

      if (!response.ok) {
        const message = await response.text()
        throw new Error(message || 'No se pudo obtener datos del DNI.')
      }

      const data = await response.json()
      return { success: true, data }
    } catch (error) {
      console.error('Error consultando RENIEC:', error)
      return { success: false, error: error.message || 'Error al consultar RENIEC.' }
    }
  }
}
