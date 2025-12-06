/**
 * Servicio de envío de emails
 * Configura tu servicio de email preferido aquí
 */

// Configuración del servicio de email
const EMAIL_CONFIG = {
  // Opción 1: EmailJS (gratis, fácil de configurar)
  // https://www.emailjs.com/
  useEmailJS: true,
  emailJSServiceID: 'service_vofmuol',
  emailJSTemplateID: 'template_nyot8i9',
  emailJSPublicKey: 'l_j8Sou5xMy0SluyF',

  // Opción 2: API personalizadass
  useCustomAPI: false,
  customAPIEndpoint: '/api/send-email', // Cambiar por tu endpoint

  // Opción 3: Resend, SendGrid, etc. (requiere backend)
  // Configurar según tu proveedor
}

/**
 * Enviar email con credenciales
 */
export const emailService = {
  /**
   * Enviar credenciales a un nuevo usuario
   */
  async sendCredentials(email, password, nombre, apellido, rol) {
    const subject = 'Credenciales de acceso - Sistema de Gestión de Matrículas'
    const html = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background-color: #4CAF50; color: white; padding: 20px; text-align: center; }
          .content { background-color: #f9f9f9; padding: 20px; border: 1px solid #ddd; }
          .credentials { background-color: white; padding: 15px; border-left: 4px solid #4CAF50; margin: 20px 0; }
          .button { display: inline-block; padding: 10px 20px; background-color: #4CAF50; color: white; text-decoration: none; border-radius: 5px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Bienvenido al Sistema de Gestión de Matrículas</h1>
          </div>
          <div class="content">
            <p>Hola ${nombre} ${apellido},</p>
            <p>Tu cuenta ha sido creada exitosamente en el sistema.</p>
            <div class="credentials">
              <h3>Credenciales de Acceso:</h3>
              <p><strong>Email:</strong> ${email}</p>
              <p><strong>Contraseña:</strong> ${password}</p>
              <p><strong>Rol:</strong> ${rol === 'alumno' ? 'Alumno' : rol === 'docente' ? 'Docente' : 'Administrador'}</p>
            </div>
            <p><strong>⚠️ IMPORTANTE:</strong></p>
            <ul>
              <li>Guarda estas credenciales de forma segura</li>
              <li>Cambia tu contraseña después de iniciar sesión</li>
            </ul>
            <p>Puedes acceder al sistema en: <a href="${window.location.origin}">${window.location.origin}</a></p>
            <a href="${window.location.origin}/login" class="button">Iniciar Sesión</a>
          </div>
        </div>
      </body>
      </html>
    `

    return await this.sendEmail(email, subject, html)
  },

  /**
   * Enviar email genérico
   */
  async sendEmail(to, subject, html) {
    try {
      if (EMAIL_CONFIG.useEmailJS) {
        return await this.sendViaEmailJS(to, subject, html)
      } else if (EMAIL_CONFIG.useCustomAPI) {
        return await this.sendViaCustomAPI(to, subject, html)
      } else {
        // Fallback: mostrar en consola (solo para desarrollo)
        console.log('📧 Email (simulado):', { to, subject })
        console.log('HTML:', html)
        return { success: true, message: 'Email simulado (modo desarrollo)' }
      }
    } catch (error) {
      console.error('Error al enviar email:', error)
      return { success: false, error: error.message }
    }
  },

  /**
   * Enviar usando EmailJS
   */
  async sendViaEmailJS(to, subject, html) {
    // Cargar EmailJS si no está disponible
    if (typeof emailjs === 'undefined') {
      const script = document.createElement('script')
      script.src = 'https://cdn.jsdelivr.net/npm/@emailjs/browser@3/dist/email.min.js'
      document.head.appendChild(script)
      await new Promise((resolve) => {
        script.onload = resolve
      })
      emailjs.init(EMAIL_CONFIG.emailJSPublicKey)
    }

    const templateParams = {
      to_email: to,
      subject: subject,
      message: html
    }

    await emailjs.send(
      EMAIL_CONFIG.emailJSServiceID,
      EMAIL_CONFIG.emailJSTemplateID,
      templateParams
    )

    return { success: true, message: 'Email enviado exitosamente' }
  },

  /**
   * Enviar usando API personalizada
   */
  async sendViaCustomAPI(to, subject, html) {
    const response = await fetch(EMAIL_CONFIG.customAPIEndpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        to,
        subject,
        html
      })
    })

    if (!response.ok) {
      throw new Error('Error al enviar email')
    }

    return { success: true, message: 'Email enviado exitosamente' }
  }
}





