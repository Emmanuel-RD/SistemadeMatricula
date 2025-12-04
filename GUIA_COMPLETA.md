# 📚 Guía Completa - Sistema de Gestión de Matrículas

## 📋 Tabla de Contenidos

1. [Configuración Inicial](#configuración-inicial)
2. [Base de Datos](#base-de-datos)
3. [Autenticación](#autenticación)
4. [Configuración de Email](#configuración-de-email)
5. [Despliegue](#despliegue)
6. [Estructura del Sistema](#estructura-del-sistema)
7. [Permisos y Políticas](#permisos-y-políticas)
8. [Solución de Problemas](#solución-de-problemas)

---

## 🚀 Configuración Inicial

### Requisitos Previos

- Node.js 16+ instalado
- Cuenta en Supabase (https://supabase.com)
- Editor de código (VS Code recomendado)

### Pasos de Instalación

1. **Clonar o descargar el proyecto**

2. **Instalar dependencias:**
   ```bash
   npm install
   ```

3. **Configurar variables de entorno:**
   - Copiar `env.example` a `.env`
   - Obtener credenciales de Supabase:
     - Ve a tu proyecto en Supabase
     - Settings > API
     - Copia `Project URL` y `anon public key`
   - Editar `.env`:
     ```env
     VITE_SUPABASE_URL=https://tu-proyecto.supabase.co
     VITE_SUPABASE_ANON_KEY=tu_anon_key_aqui
     ```

4. **Ejecutar el proyecto:**
   ```bash
   npm run dev
   ```

---

## 🗄️ Base de Datos

### Estructura de Tablas

#### 1. **roles**
Almacena los roles del sistema (admin, docente, alumno).

```sql
- id (SERIAL PRIMARY KEY)
- nombre (VARCHAR(50) UNIQUE)
- descripcion (TEXT)
- permisos (JSONB)
```

#### 2. **usuarios**
Usuarios del sistema con autenticación propia.

```sql
- id (UUID PRIMARY KEY)
- email (VARCHAR(255) UNIQUE)
- password_hash (TEXT) -- Hash bcrypt
- rol_id (INTEGER REFERENCES roles)
- nombre, apellido, dni, telefono
- activo (BOOLEAN)
- email_confirmado (BOOLEAN)
- ultimo_acceso (TIMESTAMP)
```

#### 3. **alumnos**
Información de alumnos vinculada a usuarios.

```sql
- id (BIGSERIAL PRIMARY KEY)
- usuario_id (UUID REFERENCES usuarios)
- nombre, apellido, dni, email
- grado (INTEGER 1-6)
```

#### 4. **docentes**
Información de docentes vinculada a usuarios.

```sql
- id (BIGSERIAL PRIMARY KEY)
- usuario_id (UUID REFERENCES usuarios)
- nombre, apellido, email, telefono
```

#### 5. **cursos**
Cursos disponibles en el sistema.

```sql
- id (BIGSERIAL PRIMARY KEY)
- nombre, descripcion
- grado (INTEGER 1-6)
- docente_id (BIGINT REFERENCES docentes)
- dia_semana, hora_inicio, hora_fin
- capacidad (INTEGER)
- activo (BOOLEAN)
```

#### 6. **matriculas**
Matrículas de alumnos en cursos.

```sql
- id (BIGSERIAL PRIMARY KEY)
- alumno_id (BIGINT REFERENCES alumnos)
- curso_id (BIGINT REFERENCES cursos)
- fecha_matricula (TIMESTAMP)
- estado (VARCHAR: activa, cancelada, finalizada)
- UNIQUE(alumno_id, curso_id)
```

### Configuración de la Base de Datos

1. **Crear proyecto en Supabase:**
   - Ve a https://supabase.com
   - Crea un nuevo proyecto
   - Espera a que se complete la configuración

2. **Ejecutar el schema:**
   - Ve a SQL Editor en Supabase
   - Abre el archivo `supabase/schema-completo.sql`
   - Copia y pega todo el contenido
   - Haz clic en "Run" o presiona Ctrl+Enter
   - Verifica que no haya errores

3. **Verificar tablas creadas:**
   - Ve a Table Editor en Supabase
   - Deberías ver: roles, usuarios, alumnos, docentes, cursos, matriculas

### Datos Iniciales

El schema crea automáticamente:

- **Roles:** admin, docente, alumno
- **Usuario admin por defecto:**
  - Email: `admin@colegio.com`
  - Password: `Admin123!`
  - ⚠️ **CAMBIA ESTA CONTRASEÑA DESPUÉS DEL PRIMER LOGIN**

### Funciones SQL Importantes

#### `crear_usuario_con_password`
Crea un usuario con hash de contraseña.

```sql
SELECT crear_usuario_con_password(
  'email@ejemplo.com',
  'password123',
  1, -- rol_id (1=admin, 2=docente, 3=alumno)
  'Nombre',
  'Apellido',
  '12345678', -- DNI (opcional)
  '123456789' -- Teléfono (opcional)
);
```

#### `verificar_password`
Verifica credenciales de login.

```sql
SELECT * FROM verificar_password(
  'email@ejemplo.com',
  'password123'
);
```

---

## 🔐 Autenticación

### Sistema de Autenticación

El sistema usa **autenticación propia** basada en la tabla `usuarios`, NO usa Supabase Auth.

### Flujo de Login

1. Usuario ingresa email y contraseña
2. Se llama a `verificar_password()` que:
   - Busca el usuario por email
   - Compara el hash de la contraseña
   - Retorna información del usuario si es válido
3. Se guarda la sesión en `localStorage`
4. Se redirige al dashboard

### Gestión de Sesiones

- Las sesiones se almacenan en `localStorage`
- Tiempo de expiración: 24 horas
- Al cerrar sesión, se elimina del `localStorage`

### Crear Usuarios

#### Como Administrador:

1. **Crear Alumno:**
   - Ve a Alumnos > Nuevo Alumno
   - Completa el formulario
   - El sistema:
     - Crea el usuario automáticamente
     - Genera una contraseña aleatoria
     - Envía las credenciales por email
     - Vincula el alumno al usuario

2. **Crear Docente:**
   - Ve a Docentes > Nuevo Docente
   - Completa el formulario
   - El sistema hace lo mismo que con alumnos

### Roles y Permisos

| Rol | Permisos |
|-----|----------|
| **admin** | Acceso completo al sistema |
| **docente** | Ver cursos, ver estudiantes, editar cursos asignados |
| **alumno** | Ver cursos, matricularse en cursos de su grado |

---

## 📧 Configuración de Email

### Opciones Disponibles

El sistema soporta múltiples métodos de envío de email:

#### Opción 1: EmailJS (Recomendado para desarrollo)

1. **Crear cuenta en EmailJS:**
   - Ve a https://www.emailjs.com
   - Crea una cuenta gratuita
   - Crea un servicio de email (Gmail, Outlook, etc.)
   - Crea un template de email

2. **Configurar en el proyecto:**
   - Edita `src/services/email.js`
   - Configura:
     ```javascript
     useEmailJS: true,
     emailJSServiceID: 'tu_service_id',
     emailJSTemplateID: 'tu_template_id',
     emailJSPublicKey: 'tu_public_key'
     ```

#### Opción 2: API Personalizada

1. **Crear endpoint backend:**
   - Crea un endpoint POST `/api/send-email`
   - Acepta: `{ to, subject, html }`
   - Envía el email usando tu servicio preferido

2. **Configurar en el proyecto:**
   - Edita `src/services/email.js`
   - Configura:
     ```javascript
     useCustomAPI: true,
     customAPIEndpoint: 'https://tu-api.com/api/send-email'
     ```

#### Opción 3: Servicios de Email (Producción)

- **Resend:** https://resend.com
- **SendGrid:** https://sendgrid.com
- **Mailgun:** https://mailgun.com
- **AWS SES:** https://aws.amazon.com/ses

Configura según el servicio elegido en tu backend.

### Template de Email

El sistema envía emails con:
- Credenciales de acceso
- Instrucciones de uso
- Enlace para iniciar sesión

El template HTML está en `src/services/email.js` y puede personalizarse.

---

## 🚢 Despliegue

### Desplegar en Vercel

1. **Instalar Vercel CLI:**
   ```bash
   npm i -g vercel
   ```

2. **Desplegar:**
   ```bash
   vercel
   ```

3. **Configurar variables de entorno:**
   - En el dashboard de Vercel
   - Settings > Environment Variables
   - Agregar `VITE_SUPABASE_URL` y `VITE_SUPABASE_ANON_KEY`

### Desplegar en Netlify

1. **Conectar repositorio:**
   - Ve a https://netlify.com
   - Conecta tu repositorio

2. **Configurar build:**
   - Build command: `npm run build`
   - Publish directory: `dist`

3. **Variables de entorno:**
   - Site settings > Environment variables
   - Agregar las variables necesarias

### Desplegar en Otros Servicios

Cualquier servicio que soporte aplicaciones estáticas (Vite):
- GitHub Pages
- Firebase Hosting
- AWS S3 + CloudFront
- Azure Static Web Apps

---

## 🏗️ Estructura del Sistema

### Estructura de Carpetas

```
sistema-matriculas/
├── src/
│   ├── config/
│   │   └── supabase.js          # Configuración de Supabase
│   ├── services/
│   │   ├── auth.js              # Servicio de autenticación
│   │   └── email.js             # Servicio de envío de emails
│   ├── stores/
│   │   └── auth.js              # Store de Pinia para auth
│   ├── views/
│   │   ├── Login.vue            # Página de login
│   │   ├── Dashboard.vue        # Dashboard principal
│   │   ├── Alumnos.vue          # Gestión de alumnos
│   │   ├── Docentes.vue         # Gestión de docentes
│   │   ├── Cursos.vue           # Gestión de cursos
│   │   ├── Matriculas.vue       # Gestión de matrículas
│   │   ├── Usuarios.vue         # Administración de usuarios
│   │   └── ...
│   ├── router/
│   │   └── index.js             # Configuración de rutas
│   └── main.js                  # Punto de entrada
├── supabase/
│   └── schema-completo.sql      # Schema completo de BD
└── package.json
```

### Componentes Principales

#### Servicios

- **auth.js:** Maneja login, logout, verificación de sesión
- **email.js:** Envía emails con credenciales

#### Vistas

- **Login.vue:** Página de inicio de sesión
- **Dashboard.vue:** Panel principal con estadísticas
- **Alumnos.vue:** CRUD de alumnos
- **Docentes.vue:** CRUD de docentes
- **Cursos.vue:** CRUD de cursos
- **Matriculas.vue:** Gestión de matrículas
- **Usuarios.vue:** Administración de usuarios

---

## 🔒 Permisos y Políticas

### Row Level Security (RLS)

**Nota Importante:** Las políticas RLS están configuradas para permitir acceso desde la aplicación. Los permisos reales se manejan a nivel de aplicación usando el sistema de roles.

Todas las tablas tienen RLS habilitado:

#### Usuarios
- **SELECT:** Propio usuario o admin
- **INSERT:** Solo admin
- **UPDATE:** Propio usuario o admin

#### Alumnos
- **SELECT:** Todos los autenticados
- **INSERT/UPDATE/DELETE:** Solo admin

#### Docentes
- **SELECT:** Todos los autenticados
- **INSERT/UPDATE/DELETE:** Solo admin

#### Cursos
- **SELECT:** Todos los autenticados
- **INSERT/UPDATE/DELETE:** Admin o docente

#### Matrículas
- **SELECT:** 
  - Alumnos ven solo sus matrículas
  - Admin y docentes ven todas
- **INSERT:**
  - Alumnos pueden matricularse
  - Admin puede matricular a cualquiera
- **UPDATE/DELETE:** Solo admin

### Validaciones

#### Triggers de Base de Datos

1. **validar_horario_matricula:**
   - Evita que un alumno se matricule en cursos con el mismo horario

2. **validar_grado_matricula:**
   - Verifica que el grado del alumno coincida con el del curso

3. **update_updated_at_column:**
   - Actualiza automáticamente el campo `updated_at`

---

## 🐛 Solución de Problemas

### Error: "relation does not exist"

**Causa:** Las tablas no se han creado.

**Solución:**
1. Ve a SQL Editor en Supabase
2. Ejecuta `supabase/schema-completo.sql`
3. Verifica que todas las tablas se crearon

### Error: "permission denied"

**Causa:** Políticas RLS bloqueando el acceso.

**Solución:**
1. Verifica que estás autenticado
2. Verifica que tu usuario tiene el rol correcto
3. Revisa las políticas RLS en Supabase

### No puedo iniciar sesión

**Causa:** Usuario no existe o contraseña incorrecta.

**Solución:**
1. Verifica que el usuario existe en la tabla `usuarios`
2. Usa el usuario admin por defecto: `admin@colegio.com` / `Admin123!`
3. Si olvidaste la contraseña, un admin puede resetearla

### Los emails no se envían

**Causa:** Servicio de email no configurado.

**Solución:**
1. Configura EmailJS o tu API personalizada en `src/services/email.js`
2. Verifica que las credenciales sean correctas
3. Revisa la consola del navegador para errores

### Error al crear usuario

**Causa:** Email duplicado o error en la función RPC.

**Solución:**
1. Verifica que el email no esté ya registrado
2. Verifica que la función `crear_usuario_con_password` existe
3. Revisa los logs en Supabase

### La sesión se pierde al recargar

**Causa:** Problema con localStorage.

**Solución:**
1. Verifica que el navegador permite localStorage
2. Limpia el localStorage y vuelve a iniciar sesión
3. Verifica que no hay errores en la consola

---

## 📝 Notas Adicionales

### Seguridad

- Las contraseñas se almacenan con hash bcrypt
- Nunca expongas el `service_role_key` en el cliente
- Usa HTTPS en producción
- Implementa rate limiting para login

### Mejoras Futuras

- [ ] Recuperación de contraseña por email
- [ ] Confirmación de email
- [ ] Logs de auditoría
- [ ] Exportación de reportes
- [ ] Notificaciones push

### Soporte

Para problemas o preguntas:
1. Revisa esta guía completa
2. Revisa los logs en la consola del navegador
3. Revisa los logs en Supabase (Logs > Postgres Logs)

---

## ✅ Checklist de Configuración

- [ ] Proyecto creado en Supabase
- [ ] Schema ejecutado correctamente
- [ ] Variables de entorno configuradas
- [ ] Usuario admin creado y probado
- [ ] Servicio de email configurado
- [ ] Aplicación funcionando localmente
- [ ] Desplegada en producción (opcional)

---

**Última actualización:** 2024

