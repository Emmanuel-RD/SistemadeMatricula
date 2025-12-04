# Sistema de Gestión de Matrículas

Sistema completo de gestión de matrículas escolares con autenticación propia, gestión de usuarios, alumnos, docentes, cursos y matrículas.

## 🚀 Inicio Rápido

1. **Instalar dependencias:**
   ```bash
   npm install
   ```

2. **Configurar variables de entorno:**
   - Copiar `env.example` a `.env`
   - Configurar `VITE_SUPABASE_URL` y `VITE_SUPABASE_ANON_KEY`

3. **Configurar base de datos:**
   - Crear proyecto en Supabase
   - Ejecutar `supabase/schema-completo.sql` en SQL Editor

4. **Ejecutar proyecto:**
   ```bash
   npm run dev
   ```

5. **Iniciar sesión:**
   - Email: `admin@colegio.com`
   - Password: `Admin123!`
   - ⚠️ Cambiar la contraseña después del primer login

## 📚 Documentación Completa

Para información detallada sobre configuración, despliegue, base de datos, permisos y más, consulta:

**[GUIA_COMPLETA.md](./GUIA_COMPLETA.md)**

## ✨ Características

- ✅ Autenticación propia (no usa Supabase Auth)
- ✅ Gestión de usuarios con roles (admin, docente, alumno)
- ✅ CRUD completo de alumnos, docentes y cursos
- ✅ Sistema de matrículas con validaciones
- ✅ Envío de emails con credenciales
- ✅ Panel de administración de usuarios
- ✅ Validaciones de horarios y grados
- ✅ Interfaz moderna con Bulma CSS

## 🛠️ Tecnologías

- Vue 3 + Composition API
- Pinia (gestión de estado)
- Vue Router
- Supabase (PostgreSQL)
- Bulma CSS

## 📋 Estructura del Proyecto

```
sistema-matriculas/
├── src/
│   ├── services/        # Servicios (auth, email)
│   ├── stores/          # Stores de Pinia
│   ├── views/           # Vistas principales
│   ├── router/          # Configuración de rutas
│   └── config/          # Configuración
├── supabase/
│   └── schema-completo.sql  # Schema de base de datos
└── GUIA_COMPLETA.md     # Documentación completa
```

## 🔐 Credenciales por Defecto

- **Email:** admin@colegio.com
- **Password:** Admin123!

⚠️ **IMPORTANTE:** Cambia esta contraseña inmediatamente después del primer login.

## 📧 Configuración de Email

El sistema soporta múltiples métodos de envío de email. Configura en `src/services/email.js`:

- EmailJS (recomendado para desarrollo)
- API personalizada
- Servicios de email (Resend, SendGrid, etc.)

Ver detalles en [GUIA_COMPLETA.md](./GUIA_COMPLETA.md#configuración-de-email)

## 🗄️ Base de Datos

El sistema usa PostgreSQL a través de Supabase con:

- Tabla de usuarios con autenticación propia
- Tabla de roles (admin, docente, alumno)
- Tablas de alumnos, docentes, cursos y matrículas
- Funciones SQL para crear usuarios y verificar contraseñas
- Triggers para validaciones automáticas

## 📖 Más Información

Consulta [GUIA_COMPLETA.md](./GUIA_COMPLETA.md) para:
- Configuración detallada
- Estructura de base de datos
- Permisos y políticas
- Solución de problemas
- Guía de despliegue

## 📝 Licencia

Este proyecto es de código abierto.
